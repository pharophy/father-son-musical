#!/usr/bin/env python3
"""Create a Cakewalk/Sonar-ready import bundle for a generated song."""

from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path


TRACKS = [
    {
        "name": "Lead Vocal",
        "type": "audio",
        "source": "{slug}-vocal-only.mp3",
        "folder": "Audio",
        "recommendedOutput": "Audio track",
        "notes": "Import at bar 1 beat 1. Keep this isolated for mixing.",
    },
    {
        "name": "Bass",
        "type": "midi",
        "source": "{slug}-bass.mid",
        "folder": "MIDI",
        "recommendedOutput": "SI-Bass Guitar or TTS-1 bass",
        "notes": "No guitar backing; bass is permitted.",
    },
    {
        "name": "Drums",
        "type": "midi",
        "source": "{slug}-drums.mid",
        "folder": "MIDI",
        "recommendedOutput": "SI-Drum Kit, Session Drummer, or TTS-1 drums",
        "notes": "Use MIDI channel 10 if your drum synth expects General MIDI drums.",
    },
    {
        "name": "Piano",
        "type": "midi",
        "source": "{slug}-piano.mid",
        "folder": "MIDI",
        "recommendedOutput": "SI-Electric Piano, TTS-1 piano, or piano VST",
        "notes": "Sparse chord bed.",
    },
    {
        "name": "Pad",
        "type": "midi",
        "source": "{slug}-pad.mid",
        "folder": "MIDI",
        "recommendedOutput": "TTS-1 pad/string patch or pad synth",
        "notes": "Warm support pad.",
    },
    {
        "name": "Celeste",
        "type": "midi",
        "source": "{slug}-celeste.mid",
        "folder": "MIDI",
        "recommendedOutput": "TTS-1 celesta/glockenspiel-style patch",
        "notes": "Optional nursery-light color.",
    },
]


def copy_required(src_dir: Path, bundle_dir: Path, slug: str) -> list[dict]:
    copied = []
    for track in TRACKS:
        source_name = track["source"].format(slug=slug)
        source = src_dir / source_name
        if not source.exists():
            raise SystemExit(f"Missing required file: {source}")
        target_dir = bundle_dir / track["folder"]
        target_dir.mkdir(parents=True, exist_ok=True)
        target = target_dir / source_name
        shutil.copy2(source, target)
        copied.append({**track, "bundlePath": str(target.relative_to(bundle_dir)).replace("\\", "/")})
    return copied


def write_instructions(bundle_dir: Path, slug: str, tracks: list[dict]) -> None:
    lines = [
        f"# Cakewalk/Sonar Import - {slug}",
        "",
        "## Project Setup",
        "",
        "1. Create a new empty Cakewalk/Sonar project.",
        "2. Set tempo to `100 BPM`.",
        "3. Set meter to `4/4`.",
        "4. Import `Audio/{slug}-vocal-only.mp3` to an audio track at bar 1 beat 1.".format(slug=slug),
        "5. Import the MIDI files from `MIDI/` as separate MIDI tracks.",
        "6. Assign each MIDI track to the recommended soft synth listed below.",
        "",
        "## Track Routing",
        "",
    ]
    for track in tracks:
        lines.append(f"- {track['name']}: `{track['bundlePath']}` -> {track['recommendedOutput']}. {track['notes']}")
    lines += [
        "",
        "## Native Project File Limitation",
        "",
        "This bundle does not include a native `.cwp` file. Cakewalk/Sonar project files are proprietary.",
        "For one-click native project creation, create a Cakewalk template with your preferred synth rack and provide it as a source template for future automation.",
    ]
    (bundle_dir / "IMPORT_INSTRUCTIONS.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--song-slug", required=True)
    parser.add_argument("--song-dir", required=True)
    args = parser.parse_args()

    song_dir = Path(args.song_dir)
    bundle_dir = song_dir / "cakewalk-sonar-project"
    tracks = copy_required(song_dir, bundle_dir, args.song_slug)
    manifest = {
        "songSlug": args.song_slug,
        "tempoBpm": 100,
        "meter": "4/4",
        "nativeProjectFileCreated": False,
        "nativeProjectLimitation": "Cakewalk/Sonar .cwp files are proprietary; this is an import-ready bundle.",
        "tracks": tracks,
    }
    (bundle_dir / "project-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    write_instructions(bundle_dir, args.song_slug, tracks)
    print(bundle_dir)


if __name__ == "__main__":
    main()
