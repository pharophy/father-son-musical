#!/usr/bin/env python3
"""Analyze a backing track and emit candidate vocal overlay regions."""

from __future__ import annotations

import argparse
import array
import json
import math
import statistics
import struct
from datetime import UTC, datetime
from pathlib import Path


def clamp(value: float, lower: float, upper: float) -> float:
    return max(lower, min(upper, value))


def format_seconds(value: float) -> str:
    whole = max(0, int(round(value)))
    minutes, seconds = divmod(whole, 60)
    return f"{minutes:02d}:{seconds:02d}"


def slugify(value: str) -> str:
    chars: list[str] = []
    last_hyphen = False
    for ch in value.lower():
        if ch.isalnum():
            chars.append(ch)
            last_hyphen = False
        elif not last_hyphen:
            chars.append("-")
            last_hyphen = True
    return "".join(chars).strip("-") or "overlay-song"


def analyze_wave(path: Path, window_seconds: float) -> dict:
    wav_info = read_wav_info(path)
    windows: list[dict] = []
    with path.open("rb") as handle:
        frame_rate = wav_info["sampleRate"]
        channels = wav_info["channels"]
        sample_width = wav_info["sampleWidthBytes"]
        frame_count = wav_info["frameCount"]
        duration_seconds = frame_count / float(frame_rate)
        frames_per_window = max(1, int(frame_rate * window_seconds))
        bytes_per_window = frames_per_window * wav_info["blockAlign"]
        handle.seek(wav_info["dataOffset"])
        for index in range(math.ceil(frame_count / frames_per_window)):
            raw = handle.read(bytes_per_window)
            if not raw:
                break
            samples = decode_samples(raw, sample_width, channels, wav_info["formatTag"])
            mono = mix_to_mono(samples, channels)
            rms = root_mean_square(mono)
            peak = max((abs(sample) for sample in mono), default=0)
            windows.append(
                {
                    "index": index,
                    "startSeconds": round(index * window_seconds, 3),
                    "durationSeconds": round(len(mono) / frame_rate, 3),
                    "rms": rms,
                    "peak": peak,
                }
            )
    return {
        "format": "wav",
        "sampleRate": frame_rate,
        "channels": channels,
        "sampleWidthBytes": sample_width,
        "frameCount": frame_count,
        "formatTag": wav_info["formatTag"],
        "durationSeconds": round(duration_seconds, 3),
        "windows": windows,
    }


def read_wav_info(path: Path) -> dict:
    with path.open("rb") as handle:
        header = handle.read(12)
        if len(header) != 12 or header[:4] != b"RIFF" or header[8:] != b"WAVE":
            raise SystemExit(f"Unsupported WAV container: {path}")
        fmt_info = None
        data_offset = None
        data_size = None
        while True:
            chunk_header = handle.read(8)
            if len(chunk_header) < 8:
                break
            chunk_id, chunk_size = struct.unpack("<4sI", chunk_header)
            chunk_start = handle.tell()
            if chunk_id == b"fmt ":
                chunk_data = handle.read(chunk_size)
                if len(chunk_data) < 16:
                    raise SystemExit("Incomplete WAV fmt chunk.")
                format_tag, channels, sample_rate, _, block_align, bits_per_sample = struct.unpack("<HHIIHH", chunk_data[:16])
                fmt_info = {
                    "formatTag": format_tag,
                    "channels": channels,
                    "sampleRate": sample_rate,
                    "blockAlign": block_align,
                    "sampleWidthBytes": bits_per_sample // 8,
                }
            elif chunk_id == b"data":
                data_offset = handle.tell()
                data_size = chunk_size
                handle.seek(chunk_size, 1)
            else:
                handle.seek(chunk_size, 1)
            if chunk_size % 2 == 1:
                handle.seek(1, 1)
            if fmt_info and data_offset is not None:
                break
            if handle.tell() <= chunk_start:
                raise SystemExit("Failed to advance while parsing WAV chunks.")
    if not fmt_info or data_offset is None or data_size is None:
        raise SystemExit(f"Missing fmt or data chunk in WAV file: {path}")
    if fmt_info["formatTag"] not in {1, 3}:
        raise SystemExit(f"Unsupported WAV format tag: {fmt_info['formatTag']}")
    frame_count = data_size // fmt_info["blockAlign"]
    return {
        **fmt_info,
        "dataOffset": data_offset,
        "dataSize": data_size,
        "frameCount": frame_count,
    }


def decode_samples(raw: bytes, sample_width: int, channels: int, format_tag: int) -> list[float]:
    if format_tag == 3:
        if sample_width != 4:
            raise SystemExit(f"Unsupported float WAV sample width: {sample_width} bytes")
        values = array.array("f")
        values.frombytes(raw)
        return list(values)
    if sample_width == 1:
        return [float(value - 128) for value in raw]
    type_code = "h" if sample_width == 2 else "i"
    values = array.array(type_code)
    values.frombytes(raw)
    if len(values) and values.itemsize != sample_width:
        raise SystemExit("Unexpected platform sample width while decoding WAV audio.")
    return [float(value) for value in values]


def mix_to_mono(samples: list[float], channels: int) -> list[float]:
    if channels <= 1:
        return samples
    mono: list[float] = []
    for index in range(0, len(samples), channels):
        frame = samples[index : index + channels]
        if frame:
            mono.append(sum(frame) / len(frame))
    return mono


def root_mean_square(samples: list[float]) -> float:
    if not samples:
        return 0.0
    square_mean = sum(sample * sample for sample in samples) / len(samples)
    return round(math.sqrt(square_mean), 3)


def estimate_tempo(windows: list[dict], window_seconds: float) -> tuple[float | None, float]:
    if len(windows) < 8:
        return None, 0.0
    rms_values = [window["rms"] for window in windows]
    median_rms = statistics.median(rms_values)
    onset_indices: list[int] = []
    previous = median_rms
    for idx, window in enumerate(windows):
        current = window["rms"]
        rise = current - previous
        if current > median_rms * 1.2 and rise > median_rms * 0.08:
            onset_indices.append(idx)
        previous = current
    if len(onset_indices) < 4:
        return None, 0.0
    bpm_buckets: dict[int, int] = {}
    intervals_considered = 0
    for first, second in zip(onset_indices, onset_indices[1:]):
        delta = (second - first) * window_seconds
        if delta <= 0:
            continue
        bpm = 60.0 / delta
        while bpm < 70:
            bpm *= 2
        while bpm > 180:
            bpm /= 2
        rounded = int(round(bpm))
        bpm_buckets[rounded] = bpm_buckets.get(rounded, 0) + 1
        intervals_considered += 1
    if not bpm_buckets or intervals_considered == 0:
        return None, 0.0
    best_bpm, support = max(bpm_buckets.items(), key=lambda item: item[1])
    confidence = round(support / intervals_considered, 3)
    if confidence < 0.18:
        return None, confidence
    return float(best_bpm), confidence


def build_candidate_regions(
    duration_seconds: float,
    tempo_bpm: float | None,
    tempo_confidence: float,
    target_start: float | None,
    target_end: float | None,
) -> tuple[list[dict], bool]:
    if target_start is not None and target_end is not None and target_end > target_start:
        length = target_end - target_start
        phrase_count = max(2, int(round(length / 8.0)))
        syllables = phrase_count * 10
        return (
            [
                {
                    "id": "user-target",
                    "startSeconds": round(target_start, 3),
                    "endSeconds": round(target_end, 3),
                    "startTimestamp": format_seconds(target_start),
                    "endTimestamp": format_seconds(target_end),
                    "estimatedBars": None,
                    "phraseCount": phrase_count,
                    "syllableBudget": {"min": max(8, syllables - 6), "max": syllables + 6},
                    "confidence": round(clamp(0.65 + tempo_confidence * 0.2, 0.0, 0.95), 3),
                    "rationale": "Prioritized because the user supplied the target timestamp range directly.",
                }
            ],
            False,
        )
    if tempo_bpm is None:
        return [], True

    bar_seconds = 240.0 / tempo_bpm
    usable_start = max(bar_seconds * 2, duration_seconds * 0.12)
    usable_end = min(duration_seconds - bar_seconds * 2, duration_seconds * 0.9)
    if usable_end <= usable_start:
        return [], True

    region_length_bars = 8 if duration_seconds < 210 else 12
    region_length_seconds = region_length_bars * bar_seconds
    centers = [0.28, 0.5, 0.7]
    candidates: list[dict] = []
    for index, center_ratio in enumerate(centers, start=1):
        center = duration_seconds * center_ratio
        start = clamp(center - (region_length_seconds / 2.0), usable_start, max(usable_start, usable_end - region_length_seconds))
        end = min(duration_seconds, start + region_length_seconds)
        phrase_count = max(2, region_length_bars // 2)
        budget_center = phrase_count * 11
        confidence = round(clamp(tempo_confidence * (0.92 - (index - 1) * 0.08), 0.0, 0.92), 3)
        candidates.append(
            {
                "id": f"candidate-{index}",
                "startSeconds": round(start, 3),
                "endSeconds": round(end, 3),
                "startTimestamp": format_seconds(start),
                "endTimestamp": format_seconds(end),
                "estimatedBars": region_length_bars,
                "phraseCount": phrase_count,
                "syllableBudget": {"min": max(12, budget_center - 8), "max": budget_center + 8},
                "confidence": confidence,
                "rationale": (
                    "Auto-selected from the stable middle portion of the track to avoid the intro/outro and give the lyric room for a complete phrase."
                ),
            }
        )
    return candidates, False


def write_source_brief(
    output_path: Path,
    title: str,
    source_audio: Path,
    analysis: dict,
    regions: list[dict],
    manual_review_required: bool,
    source_authorized: bool,
) -> None:
    lines = [
        f"# {title} - Overlay Source Brief",
        "",
        "## Source",
        "",
        f"- Audio path: `{source_audio.as_posix()}`",
        f"- File format: `{analysis['format']}`",
        f"- Duration: `{analysis['durationSeconds']}` seconds",
        f"- Tempo estimate: `{analysis.get('tempoBpm')}`" if analysis.get("tempoBpm") else "- Tempo estimate: unavailable",
        f"- Timing confidence: `{analysis.get('tempoConfidence', 0.0)}`",
        f"- Source authorization recorded: `{'yes' if source_authorized else 'no'}`",
        "",
        "## Region Recommendation",
        "",
    ]
    if regions:
        best = regions[0]
        lines.extend(
            [
                f"- Recommended region: `{best['id']}`",
                f"- Start: `{best['startTimestamp']}`",
                f"- End: `{best['endTimestamp']}`",
                f"- Phrase count: `{best['phraseCount']}`",
                f"- Syllable budget: `{best['syllableBudget']['min']}-{best['syllableBudget']['max']}`",
                f"- Rationale: {best['rationale']}",
            ]
        )
    else:
        lines.append("- No automatic region recommendation is safe enough yet.")
    lines.extend(
        [
            "",
            "## Status",
            "",
            (
                "- Manual review required before provider generation because timing confidence is too low or the format could not be analyzed deeply."
                if manual_review_required
                else "- Analysis produced candidate overlay regions. Review and select one before generating vocals."
            ),
            "",
        ]
    )
    output_path.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-audio", required=True)
    parser.add_argument("--song-dir", required=True)
    parser.add_argument("--song-slug")
    parser.add_argument("--title")
    parser.add_argument("--window-seconds", type=float, default=0.5)
    parser.add_argument("--target-start", type=float)
    parser.add_argument("--target-end", type=float)
    parser.add_argument("--duration-seconds", type=float, help="Fallback duration for unsupported formats")
    parser.add_argument("--source-authorized", action="store_true")
    args = parser.parse_args()

    source_audio = Path(args.source_audio).resolve()
    if not source_audio.exists():
        raise SystemExit(f"Missing source audio: {source_audio}")
    song_dir = Path(args.song_dir)
    song_dir.mkdir(parents=True, exist_ok=True)
    title = args.title or source_audio.stem.replace("-", " ").replace("_", " ").title()
    song_slug = args.song_slug or slugify(title)

    if source_audio.suffix.lower() == ".wav":
        analysis = analyze_wave(source_audio, args.window_seconds)
    else:
        if args.duration_seconds is None:
            raise SystemExit(
                "Unsupported audio format for deterministic analysis. Supply --duration-seconds or convert the source to WAV first."
            )
        analysis = {
            "format": source_audio.suffix.lower().lstrip(".") or "unknown",
            "sampleRate": None,
            "channels": None,
            "sampleWidthBytes": None,
            "frameCount": None,
            "durationSeconds": round(args.duration_seconds, 3),
            "windows": [],
        }

    tempo_bpm, tempo_confidence = estimate_tempo(analysis["windows"], args.window_seconds) if analysis["windows"] else (None, 0.0)
    analysis["songSlug"] = song_slug
    analysis["title"] = title
    analysis["sourceAudioPath"] = source_audio.as_posix()
    analysis["tempoBpm"] = tempo_bpm
    analysis["tempoConfidence"] = tempo_confidence
    analysis["generatedAt"] = datetime.now(UTC).isoformat()
    analysis["analysisMode"] = "wave-energy" if analysis["windows"] else "metadata-only"

    regions, manual_review_required = build_candidate_regions(
        duration_seconds=analysis["durationSeconds"],
        tempo_bpm=tempo_bpm,
        tempo_confidence=tempo_confidence,
        target_start=args.target_start,
        target_end=args.target_end,
    )
    if not regions and not manual_review_required:
        manual_review_required = True

    analysis["manualReviewRequired"] = manual_review_required
    analysis["sourceAuthorized"] = args.source_authorized

    region_map = {
        "songSlug": song_slug,
        "title": title,
        "sourceAudioPath": source_audio.as_posix(),
        "generatedAt": analysis["generatedAt"],
        "tempoBpm": tempo_bpm,
        "tempoConfidence": tempo_confidence,
        "manualReviewRequired": manual_review_required,
        "candidateRegions": regions,
    }

    (song_dir / "overlay-analysis.json").write_text(json.dumps(analysis, indent=2) + "\n", encoding="utf-8")
    (song_dir / "overlay-region-map.json").write_text(json.dumps(region_map, indent=2) + "\n", encoding="utf-8")
    write_source_brief(
        song_dir / "overlay-source-brief.md",
        title=title,
        source_audio=source_audio,
        analysis=analysis,
        regions=regions,
        manual_review_required=manual_review_required,
        source_authorized=args.source_authorized,
    )
    print(song_dir)


if __name__ == "__main__":
    main()
