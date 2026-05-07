#!/usr/bin/env python3
"""Write deterministic no-guitar backing MIDI files for musical songs."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path


TPQ = 480
MEASURE = TPQ * 4


@dataclass(frozen=True)
class Event:
    tick: int
    data: bytes


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


def program_event(tick: int, channel: int, program_number: int) -> Event:
    return Event(tick, bytes([0xC0 | channel, program_number]))


def note_events(tick: int, channel: int, pitch: int, velocity: int, duration: int) -> list[Event]:
    return [
        Event(tick, bytes([0x90 | channel, pitch, velocity])),
        Event(tick + duration, bytes([0x80 | channel, pitch, 0])),
    ]


def render_events(name: str, events: list[Event]) -> bytes:
    named = [Event(0, bytes([0xFF, 0x03]) + vlq(len(name)) + name.encode("ascii"))]
    ordered = sorted(named + events, key=lambda event: event.tick)
    data = b""
    cursor = 0
    for event in ordered:
        data += vlq(event.tick - cursor) + event.data
        cursor = event.tick
    data += meta(0, 0x2F, b"")
    return b"MTrk" + len(data).to_bytes(4, "big") + data


def midi_file(tracks: list[bytes]) -> bytes:
    header = (
        b"MThd"
        + (6).to_bytes(4, "big")
        + (1).to_bytes(2, "big")
        + len(tracks).to_bytes(2, "big")
        + TPQ.to_bytes(2, "big")
    )
    return header + b"".join(tracks)


def conductor() -> bytes:
    tempo = 600000  # 100 BPM
    data = (
        meta(0, 0x03, b"Conductor")
        + meta(0, 0x51, tempo.to_bytes(3, "big"))
        + meta(0, 0x58, bytes([4, 2, 24, 8]))
        + meta(0, 0x59, bytes([0, 0]))
        + meta(0, 0x2F, b"")
    )
    return b"MTrk" + len(data).to_bytes(4, "big") + data


FORM = [
    ("intro", "intro"),
    ("verse_1", "verse"),
    ("verse_2", "verse"),
    ("chorus_1", "chorus"),
    ("bridge", "bridge"),
    ("final_chorus", "chorus"),
    ("tag", "tag"),
]

PROGRESSIONS = {
    "intro": [48, 47, 45, 41],
    "verse": [48, 47, 45, 41, 40, 43, 48, 48],
    "chorus": [41, 40, 43, 45, 41, 40, 43, 48],
    "bridge": [45, 41, 48, 43, 45, 41, 40, 43],
    "tag": [48, 47, 45, 41, 48, 48],
}

VOICINGS = {
    48: (60, 62, 64, 67),
    47: (59, 62, 67, 71),
    45: (57, 60, 64, 67),
    41: (53, 57, 60, 64),
    40: (52, 55, 60, 64),
    43: (55, 60, 62, 67),
}


def song_sections() -> list[tuple[int, str, int]]:
    measures: list[tuple[int, str, int]] = []
    measure_index = 0
    for section_name, progression_name in FORM:
        for root in PROGRESSIONS[progression_name]:
            measures.append((measure_index, section_name, root))
            measure_index += 1
    return measures


def section_family(section: str) -> str:
    if section.startswith("verse"):
        return "verse"
    if section.startswith("chorus") or section == "final_chorus":
        return "chorus"
    return section


def bass_track() -> bytes:
    events = [program_event(0, 0, 32)]
    for measure_index, section, root in song_sections():
        tick = measure_index * MEASURE
        family = section_family(section)
        velocity = 38 if family == "intro" else 50 if family in {"verse", "tag"} else 58
        events += note_events(tick, 0, root, velocity, TPQ * 2)
        events += note_events(tick + TPQ * 2, 0, root + 12, max(velocity - 8, 30), TPQ * 2)
    return render_events("Bass - Warm Root Motion", events)


def drums_track() -> bytes:
    events: list[Event] = []
    for measure_index, section, _root in song_sections():
        tick = measure_index * MEASURE
        family = section_family(section)
        if family == "intro":
            events += note_events(tick, 9, 42, 14, TPQ // 4)
            events += note_events(tick + TPQ * 3, 9, 42, 12, TPQ // 4)
            continue
        kick_vel = 34 if family in {"verse", "tag"} else 42
        snare_vel = 24 if family in {"verse", "tag"} else 32
        hat_vel = 18 if family in {"verse", "tag"} else 24
        events += note_events(tick, 9, 36, kick_vel, TPQ // 4)
        events += note_events(tick + TPQ, 9, 38, snare_vel, TPQ // 4)
        events += note_events(tick + TPQ * 2, 9, 36, max(kick_vel - 8, 24), TPQ // 4)
        events += note_events(tick + TPQ * 3, 9, 38, snare_vel, TPQ // 4)
        for offset in range(0, MEASURE, TPQ // 2):
            events += note_events(tick + offset, 9, 42, hat_vel, TPQ // 8)
    return render_events("Drums - Soft Pulse", events)


def piano_track() -> bytes:
    events = [program_event(0, 1, 0)]
    for measure_index, section, root in song_sections():
        tick = measure_index * MEASURE
        family = section_family(section)
        velocity = 26 if family == "intro" else 34 if family in {"verse", "tag"} else 42
        for pitch in VOICINGS[root]:
            events += note_events(tick, 1, pitch, velocity, MEASURE)
    return render_events("Piano - Sparse Chords", events)


def pad_track() -> bytes:
    events = [program_event(0, 2, 88)]
    for measure_index, section, root in song_sections():
        tick = measure_index * MEASURE
        family = section_family(section)
        velocity = 18 if family in {"intro", "verse", "tag"} else 26
        events += note_events(tick, 2, root + 12, velocity, MEASURE)
    return render_events("Pad - Warm Air", events)


def celeste_track() -> bytes:
    events = [program_event(0, 3, 8)]
    phrase = [72, 76, 79, 76]
    for measure_index, section, _root in song_sections():
        if section_family(section) not in {"intro", "verse", "tag"}:
            continue
        tick = measure_index * MEASURE
        for i, pitch in enumerate(phrase):
            events += note_events(tick + i * TPQ, 3, pitch, 28, TPQ // 2)
    return render_events("Celeste - Nursery Light", events)


def write(path: Path, tracks: list[bytes]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(midi_file([conductor(), *tracks]))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--song-slug", required=True)
    parser.add_argument("--out-dir", required=True)
    args = parser.parse_args()
    if args.song_slug != "before-your-name":
        raise SystemExit("Only before-your-name is implemented in this backing writer.")

    out_dir = Path(args.out_dir)
    parts = {
        "bass": bass_track(),
        "drums": drums_track(),
        "piano": piano_track(),
        "pad": pad_track(),
        "celeste": celeste_track(),
    }
    for name, part in parts.items():
        write(out_dir / f"{args.song_slug}-{name}.mid", [part])
    write(out_dir / f"{args.song_slug}-backing-combined.mid", list(parts.values()))


if __name__ == "__main__":
    main()
