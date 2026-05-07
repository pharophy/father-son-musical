#!/usr/bin/env python3
"""Create a DAW-ready package for a vocal overlay workflow."""

from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path


def copy_if_present(source: Path, destination: Path) -> str | None:
    if not source.exists():
        return None
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, destination)
    return destination.name


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--song-dir", required=True)
    parser.add_argument("--song-slug", required=True)
    parser.add_argument("--source-audio", required=True)
    args = parser.parse_args()

    song_dir = Path(args.song_dir)
    bundle_dir = song_dir / "overlay-stem-package"
    bundle_dir.mkdir(parents=True, exist_ok=True)

    source_audio = Path(args.source_audio)
    if not source_audio.exists():
        raise SystemExit(f"Missing source audio: {source_audio}")

    copied = {
        "sourceAudio": copy_if_present(source_audio, bundle_dir / source_audio.name),
        "regionMap": copy_if_present(song_dir / "overlay-region-map.json", bundle_dir / "overlay-region-map.json"),
        "requestManifest": copy_if_present(song_dir / "overlay-vocal-request.json", bundle_dir / "overlay-vocal-request.json"),
        "integrationNotes": copy_if_present(song_dir / "overlay-integration-notes.md", bundle_dir / "overlay-integration-notes.md"),
        "vocalDemo": copy_if_present(song_dir / "overlay-vocal-demo.md", bundle_dir / "overlay-vocal-demo.md"),
        "vocalStem": copy_if_present(song_dir / f"{args.song_slug}-overlay-vocal-only.mp3", bundle_dir / f"{args.song_slug}-overlay-vocal-only.mp3"),
    }

    manifest = {
        "songSlug": args.song_slug,
        "packageType": "overlay-stem-package",
        "sourceAudio": copied["sourceAudio"],
        "vocalStem": copied["vocalStem"],
        "regionMap": copied["regionMap"],
        "requestManifest": copied["requestManifest"],
        "integrationNotes": copied["integrationNotes"],
        "vocalDemo": copied["vocalDemo"],
        "complete": bool(copied["sourceAudio"] and copied["regionMap"] and copied["requestManifest"] and copied["integrationNotes"]),
        "vocalStemAvailable": bool(copied["vocalStem"]),
    }
    (bundle_dir / "overlay-package-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

    lines = [
        f"# Overlay Stem Package - {args.song_slug}",
        "",
        "## Import Order",
        "",
        "1. Import the copied source audio into your DAW as the timing reference.",
        "2. Review `overlay-region-map.json` and `overlay-integration-notes.md` to confirm the target timestamps.",
        "3. Import the vocal stem if present and place it on its own audio track.",
        "4. Align the vocal stem to the region start time and adjust for any provider latency manually.",
        "",
        "## Included Files",
        "",
    ]
    for label, filename in copied.items():
        lines.append(f"- {label}: `{filename or 'not included'}`")
    lines.extend(
        [
            "",
            "## Notes",
            "",
            (
                "- This package does not include a generated vocal stem yet. Use it as a planning bundle until provider execution is authorized."
                if not copied["vocalStem"]
                else "- This package includes an overlay-ready dry stem. Final balancing and merge are DAW tasks."
            ),
            "",
        ]
    )
    (bundle_dir / "IMPORT_INSTRUCTIONS.md").write_text("\n".join(lines), encoding="utf-8")
    print(bundle_dir)


if __name__ == "__main__":
    main()
