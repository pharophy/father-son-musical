#!/usr/bin/env python3
"""Generate an ElevenLabs vocal guide from a text file.

Requires ELEVENLABS_API_KEY in the environment. Pass an authorized voice ID.
"""

from __future__ import annotations

import argparse
import json
import os
import urllib.error
import urllib.request
from datetime import UTC, datetime
from pathlib import Path


API_URL = "https://api.elevenlabs.io/v1/text-to-speech/{voice_id}"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--voice-id", required=True, help="Authorized ElevenLabs voice ID")
    parser.add_argument("--text-file", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--overlay-request", help="Path to overlay-vocal-request.json for guardrail enforcement")
    parser.add_argument("--metadata-out", help="Path to write overlay generation metadata JSON")
    parser.add_argument("--model-id", default="eleven_multilingual_v2")
    parser.add_argument("--output-format", default="mp3_44100_128")
    parser.add_argument("--stability", type=float, default=0.35)
    parser.add_argument("--similarity-boost", type=float, default=0.75)
    parser.add_argument("--style", type=float, default=0.25)
    args = parser.parse_args()

    overlay_request = None
    if args.overlay_request:
        overlay_request = json.loads(Path(args.overlay_request).read_text(encoding="utf-8"))
        if not overlay_request.get("readyForProviderCall"):
            reasons = overlay_request.get("blockingReasons") or ["Overlay request is not ready for provider execution."]
            raise SystemExit("Overlay request is blocked:\n- " + "\n- ".join(reasons))
        if not overlay_request.get("sourceAuthorized"):
            raise SystemExit("Overlay request is missing source-audio authorization.")
        if not overlay_request.get("voiceAuthorized"):
            raise SystemExit("Overlay request is missing voice authorization.")
        if not overlay_request.get("networkApproved"):
            raise SystemExit("Overlay request is missing network approval.")

    api_key = os.environ.get("ELEVENLABS_API_KEY")
    if not api_key:
        raise SystemExit("Missing ELEVENLABS_API_KEY environment variable.")

    text = Path(args.text_file).read_text(encoding="utf-8").strip()
    if not text:
        raise SystemExit("Text file is empty.")

    payload = {
        "text": text,
        "model_id": args.model_id,
        "voice_settings": {
            "stability": args.stability,
            "similarity_boost": args.similarity_boost,
            "style": args.style,
            "use_speaker_boost": True,
        },
    }
    data = json.dumps(payload).encode("utf-8")
    url = f"{API_URL.format(voice_id=args.voice_id)}?output_format={args.output_format}"
    request = urllib.request.Request(
        url,
        data=data,
        headers={
            "Content-Type": "application/json",
            "xi-api-key": api_key,
        },
        method="POST",
    )

    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    try:
        with urllib.request.urlopen(request, timeout=120) as response:
            out.write_bytes(response.read())
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        raise SystemExit(f"ElevenLabs request failed: HTTP {exc.code}: {body}") from exc

    if args.metadata_out:
        metadata = {
            "generatedAt": datetime.now(UTC).isoformat(),
            "voiceId": args.voice_id,
            "textFile": str(Path(args.text_file).resolve()),
            "outputPath": str(out.resolve()),
            "outputFormat": args.output_format,
            "modelId": args.model_id,
        }
        if overlay_request:
            metadata["overlay"] = {
                "songSlug": overlay_request.get("songSlug"),
                "title": overlay_request.get("title"),
                "sourceAudioPath": overlay_request.get("sourceAudioPath"),
                "selectedRegion": overlay_request.get("selectedRegion"),
                "timingConfidence": overlay_request.get("timingConfidence"),
                "voiceName": overlay_request.get("voiceName"),
            }
        metadata_out = Path(args.metadata_out)
        metadata_out.parent.mkdir(parents=True, exist_ok=True)
        metadata_out.write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")

    print(out)


if __name__ == "__main__":
    main()
