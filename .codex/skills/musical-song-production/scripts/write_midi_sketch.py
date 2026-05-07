#!/usr/bin/env python3
"""Write a small deterministic MIDI sketch for father/son musical songs."""

from __future__ import annotations

import argparse
from pathlib import Path


TPQ = 480


def vlq(value: int) -> bytes:
    if value == 0:
        return b"\x00"
    parts = [value & 0x7F]
    value >>= 7
    while value:
        parts.append((value & 0x7F) | 0x80)
        value >>= 7
    return bytes(reversed(parts))


def meta(delta: int, kind: int, data: bytes) -> bytes:
    return vlq(delta) + bytes([0xFF, kind]) + vlq(len(data)) + data


def note(delta: int, channel: int, pitch: int, velocity: int, duration: int) -> bytes:
    return (
        vlq(delta)
        + bytes([0x90 | channel, pitch, velocity])
        + vlq(duration)
        + bytes([0x80 | channel, pitch, 0])
    )


def program(delta: int, channel: int, program_number: int) -> bytes:
    return vlq(delta) + bytes([0xC0 | channel, program_number])


def track(name: str, body: bytes) -> bytes:
    data = meta(0, 0x03, name.encode("ascii")) + body + meta(0, 0x2F, b"")
    return b"MTrk" + len(data).to_bytes(4, "big") + data


def rest(delta: int) -> bytes:
    return vlq(delta)


def notes_from_pitches(channel: int, pitches: list[int | None], velocity: int, unit: int = TPQ // 2) -> bytes:
    body = b""
    pending = 0
    for pitch in pitches:
        if pitch is None:
            pending += unit
        else:
            body += note(pending, channel, pitch, velocity, unit)
            pending = 0
    if pending:
        body += rest(pending)
    return body


def build_before_your_name() -> bytes:
    header = b"MThd" + (6).to_bytes(4, "big") + (1).to_bytes(2, "big") + (5).to_bytes(2, "big") + TPQ.to_bytes(2, "big")
    tempo = 600000
    conductor = track(
        "Conductor",
        meta(0, 0x51, tempo.to_bytes(3, "big"))
        + meta(0, 0x58, bytes([4, 2, 24, 8]))
        + meta(0, 0x59, bytes([0, 0])),
    )
    father = program(0, 0, 24)
    for pitch in [52, 55, 59, 62, 64, 62, 59, 55]:
        father += note(0, 0, pitch, 72, TPQ)
    father += note(TPQ, 0, 52, 58, TPQ * 2)
    father_track = track("Voice/Guitar 1 - Father", father)

    # The son is not born yet: represent him as rests plus a distant final imagined answer.
    son = program(0, 1, 24) + note(TPQ * 8, 1, 67, 38, TPQ)
    son_track = track("Voice/Guitar 2 - Imagined Answer", son)

    melody_pitches = [
        60, 62, 64, 64, 67, 67, 64, None,
        62, 64, 65, 65, 67, 69, 67, None,
        64, 65, 67, 67, 69, 71, 72, None,
        72, 71, 69, 67, 65, 64, 62, None,
        65, 67, 69, 69, 72, 72, 69, None,
        67, 69, 71, 72, 74, 72, 71, None,
    ]
    melody = program(0, 2, 52) + notes_from_pitches(2, melody_pitches, 70)
    melody_track = track("Guide Vocal Melody - Father", melody)

    chords = program(0, 3, 0)
    for root, third, fifth in [(60, 64, 67), (59, 62, 67), (57, 60, 64), (65, 69, 72)] * 3:
        chords += note(0, 3, root, 42, TPQ * 2)
        chords += note(0, 3, third, 36, TPQ * 2)
        chords += note(0, 3, fifth, 34, TPQ * 2)
    chords_track = track("Chord Guide", chords)
    return header + conductor + father_track + son_track + melody_track + chords_track


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--song-slug", required=True)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()
    if args.song_slug != "before-your-name":
        raise SystemExit("Only before-your-name is implemented in this initial sketch writer.")
    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_bytes(build_before_your_name())


if __name__ == "__main__":
    main()
