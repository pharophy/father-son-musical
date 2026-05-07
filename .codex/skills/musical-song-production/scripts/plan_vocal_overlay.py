#!/usr/bin/env python3
"""Create lyric-fit and provider-planning artifacts for a vocal overlay."""

from __future__ import annotations

import argparse
import json
from datetime import UTC, datetime
from pathlib import Path


def format_seconds(value: float) -> str:
    whole = max(0, int(round(value)))
    minutes, seconds = divmod(whole, 60)
    return f"{minutes:02d}:{seconds:02d}"


def choose_region(region_map: dict, requested_region_id: str | None) -> dict:
    regions = region_map.get("candidateRegions", [])
    if not regions:
        raise SystemExit("No candidate regions are available. Run analysis first or supply a manual target range.")
    if requested_region_id:
        for region in regions:
            if region["id"] == requested_region_id:
                return region
        raise SystemExit(f"Unknown region id: {requested_region_id}")
    return max(regions, key=lambda item: item.get("confidence", 0.0))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--song-dir", required=True)
    parser.add_argument("--song-slug", required=True)
    parser.add_argument("--title", required=True)
    parser.add_argument("--analysis", required=True)
    parser.add_argument("--region-map", required=True)
    parser.add_argument("--region-id")
    parser.add_argument("--voice-role", default="Lead overlay vocal")
    parser.add_argument("--dramatic-intent", default="Add a clear human perspective without overcrowding the backing track.")
    parser.add_argument("--lyric-theme", default="A new perspective that belongs inside the chosen section.")
    parser.add_argument("--provider", default="ElevenLabs")
    parser.add_argument("--source-audio")
    parser.add_argument("--source-authorized", action="store_true")
    parser.add_argument("--voice-name", default="TBD")
    parser.add_argument("--voice-authorized", action="store_true")
    parser.add_argument("--network-approved", action="store_true")
    parser.add_argument("--timing-confidence-threshold", type=float, default=0.35)
    args = parser.parse_args()

    song_dir = Path(args.song_dir)
    analysis = json.loads(Path(args.analysis).read_text(encoding="utf-8"))
    region_map = json.loads(Path(args.region_map).read_text(encoding="utf-8"))
    region = choose_region(region_map, args.region_id)

    confidence = min(region.get("confidence", 0.0), analysis.get("tempoConfidence", 0.0) or region.get("confidence", 0.0))
    blocking_reasons: list[str] = []
    if region_map.get("manualReviewRequired"):
        blocking_reasons.append("Timing analysis requires manual review before automation.")
    if confidence < args.timing_confidence_threshold:
        blocking_reasons.append(
            f"Timing confidence {confidence:.3f} is below the configured threshold of {args.timing_confidence_threshold:.3f}."
        )
    if not args.source_authorized:
        blocking_reasons.append("Source-audio authorization has not been confirmed.")
    if not args.voice_authorized:
        blocking_reasons.append("Voice authorization has not been confirmed.")
    if not args.network_approved:
        blocking_reasons.append("Network approval for a live provider call has not been confirmed.")

    start_seconds = float(region["startSeconds"])
    end_seconds = float(region["endSeconds"])
    duration_seconds = round(end_seconds - start_seconds, 3)
    phrase_count = int(region.get("phraseCount", 4))
    syllable_budget = region.get("syllableBudget", {"min": 32, "max": 44})
    phrase_budget_min = max(4, round(syllable_budget["min"] / phrase_count))
    phrase_budget_max = max(phrase_budget_min, round(syllable_budget["max"] / phrase_count))

    request = {
        "songSlug": args.song_slug,
        "title": args.title,
        "provider": args.provider,
        "sourceAudioPath": (Path(args.source_audio).resolve().as_posix() if args.source_audio else analysis.get("sourceAudioPath")),
        "sourceAuthorized": args.source_authorized,
        "voiceName": args.voice_name,
        "voiceAuthorized": args.voice_authorized,
        "networkApproved": args.network_approved,
        "apiKeyEnvVar": "ELEVENLABS_API_KEY",
        "selectedRegion": region,
        "timingConfidence": round(confidence, 3),
        "timingConfidenceThreshold": args.timing_confidence_threshold,
        "voiceRole": args.voice_role,
        "dramaticIntent": args.dramatic_intent,
        "lyricTheme": args.lyric_theme,
        "lyricPlan": {
            "phraseCount": phrase_count,
            "phraseBudgetMin": phrase_budget_min,
            "phraseBudgetMax": phrase_budget_max,
            "regionDurationSeconds": duration_seconds,
        },
        "readyForProviderCall": not blocking_reasons,
        "blockingReasons": blocking_reasons,
        "outputTargets": {
            "vocalOnly": (song_dir / f"{args.song_slug}-overlay-vocal-only.mp3").as_posix(),
            "metadata": (song_dir / "overlay-vocal-generation.json").as_posix(),
        },
        "generatedAt": datetime.now(UTC).isoformat(),
    }

    lyric_lines = [
        f"# {args.title} - Overlay Lyric Fit",
        "",
        "## Selected Region",
        "",
        f"- Region ID: `{region['id']}`",
        f"- Start: `{region.get('startTimestamp', format_seconds(start_seconds))}`",
        f"- End: `{region.get('endTimestamp', format_seconds(end_seconds))}`",
        f"- Duration: `{duration_seconds}` seconds",
        f"- Phrase count target: `{phrase_count}`",
        f"- Syllable budget target: `{syllable_budget['min']}-{syllable_budget['max']}` total, about `{phrase_budget_min}-{phrase_budget_max}` per phrase",
        f"- Voice role: {args.voice_role}",
        f"- Dramatic intent: {args.dramatic_intent}",
        f"- Lyric theme: {args.lyric_theme}",
        "",
        "## Phrase Grid",
        "",
    ]
    for phrase_number in range(1, phrase_count + 1):
        lyric_lines.append(
            f"- Phrase {phrase_number}: aim for {phrase_budget_min}-{phrase_budget_max} syllables and keep the ending open enough for the next downbeat."
        )
    lyric_lines.extend(
        [
            "",
            "## Draft Lyric",
            "",
            "_Write or revise the lyric here against the selected phrase grid before live generation._",
            "",
            "## Fit Check",
            "",
            "- Confirm the lyric can be sung inside the selected timestamps without compressing consonants unnaturally.",
            "- Revise or shorten before provider generation if the region feels overfilled.",
            "",
        ]
    )

    demo_lines = [
        f"# {args.title} - Overlay Vocal Demo Plan",
        "",
        "## Provider",
        "",
        f"- Provider: {args.provider}",
        f"- Intended output: `music/{args.song_slug}/{args.song_slug}-overlay-vocal-only.mp3`",
        f"- Status: {'Ready for provider call' if request['readyForProviderCall'] else 'Deferred'}",
        "",
        "## Region",
        "",
        f"- Selected region: `{region['id']}`",
        f"- Target range: `{region.get('startTimestamp', format_seconds(start_seconds))}` to `{region.get('endTimestamp', format_seconds(end_seconds))}`",
        f"- Timing confidence: `{request['timingConfidence']}`",
        "",
        "## Guardrails",
        "",
        f"- Source authorization: `{'yes' if args.source_authorized else 'no'}`",
        f"- Voice authorization: `{'yes' if args.voice_authorized else 'no'}`",
        f"- Network approval: `{'yes' if args.network_approved else 'no'}`",
        f"- Voice selection: `{args.voice_name}`",
        "",
        "## Fail-Closed Status",
        "",
    ]
    if blocking_reasons:
        demo_lines.extend([f"- {reason}" for reason in blocking_reasons])
    else:
        demo_lines.append("- All prerequisites are present. Provider call may proceed.")
    demo_lines.extend(
        [
            "",
            "## Metadata",
            "",
            f"- Request manifest: `music/{args.song_slug}/overlay-vocal-request.json`",
            f"- Integration notes: `music/{args.song_slug}/overlay-integration-notes.md`",
            "",
        ]
    )

    integration_lines = [
        f"# {args.title} - Overlay Integration Notes",
        "",
        "## Placement",
        "",
        f"- Source audio: `{request['sourceAudioPath']}`",
        f"- Target region: `{region['id']}`",
        f"- Start time: `{region.get('startTimestamp', format_seconds(start_seconds))}` ({start_seconds:.3f}s)",
        f"- End time: `{region.get('endTimestamp', format_seconds(end_seconds))}` ({end_seconds:.3f}s)",
        f"- Stem target: `music/{args.song_slug}/{args.song_slug}-overlay-vocal-only.mp3`",
        "",
        "## DAW Notes",
        "",
        "- Import the source track first, then place the generated vocal stem on a separate audio track.",
        "- Align the vocal stem to the target region start time and trim any extra lead-in manually if the provider adds latency.",
        "- Treat this as a dry overlay-ready stem unless a later workflow generates a deterministic preview mix.",
        "",
        "## Status",
        "",
        (
            "- Provider execution is deferred. Use the lyric-fit and request metadata for manual revision or for a later authorized run."
            if blocking_reasons
            else "- Provider execution may proceed. After generation, package the stem with `create_overlay_bundle.py`."
        ),
        "",
    ]

    (song_dir / "overlay-lyrics-fit.md").write_text("\n".join(lyric_lines), encoding="utf-8")
    (song_dir / "overlay-vocal-request.json").write_text(json.dumps(request, indent=2) + "\n", encoding="utf-8")
    (song_dir / "overlay-vocal-demo.md").write_text("\n".join(demo_lines), encoding="utf-8")
    (song_dir / "overlay-integration-notes.md").write_text("\n".join(integration_lines), encoding="utf-8")
    print(song_dir)


if __name__ == "__main__":
    main()
