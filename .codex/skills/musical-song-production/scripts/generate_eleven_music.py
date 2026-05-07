#!/usr/bin/env python3
"""Generate a sung Eleven Music demo from a composition plan."""

from __future__ import annotations

import argparse
import json
import os
import urllib.error
import urllib.request
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--plan", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--output-format", default="mp3_44100_128")
    args = parser.parse_args()

    api_key = os.environ.get("ELEVENLABS_API_KEY")
    if not api_key:
        raise SystemExit("Missing ELEVENLABS_API_KEY environment variable.")

    plan = json.loads(Path(args.plan).read_text(encoding="utf-8"))
    payload = {
        "composition_plan": plan,
        "model_id": "music_v1",
        "respect_sections_durations": False,
    }
    data = json.dumps(payload).encode("utf-8")
    request = urllib.request.Request(
        f"https://api.elevenlabs.io/v1/music?output_format={args.output_format}",
        data=data,
        headers={"Content-Type": "application/json", "xi-api-key": api_key},
        method="POST",
    )

    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    try:
        with urllib.request.urlopen(request, timeout=300) as response:
            out.write_bytes(response.read())
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        raise SystemExit(f"Eleven Music request failed: HTTP {exc.code}: {body}") from exc

    print(out)


if __name__ == "__main__":
    main()
