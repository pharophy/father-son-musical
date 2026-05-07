# MIDI Generation

Use MIDI for deterministic sketches: guide melody, motif fragments, chord pulses, bass motion, drums, piano, pads, strings, and optional color instruments.

Project rule: never generate guitar MIDI for backing parts. Guitar is reserved for live/user performance or explicit father/son motif work. If the user asks for backing music, use non-guitar instrumentation unless they explicitly override this rule.

Default conventions:

- Resolution: 480 ticks per quarter note.
- File naming: use full-track names such as `music/<song-slug>/<song-slug>-backing-combined.mid`, `<song-slug>-bass.mid`, and `<song-slug>-drums.mid`.
- Track names should identify role and instrument.
- Include tempo and time signature.
- Keep velocities expressive but simple.
- For DAW import, prefer separate MIDI files per part plus one combined backing file.
- Full-track rule: generated MIDI must cover the complete current song form. Do not stop at the first verse, chorus, or motif sketch unless the filename and arrangement notes explicitly mark it as a `sketch`, `excerpt`, or `loop`.

Use `scripts/write_midi_sketch.py` only for explicitly labeled guide sketches:

```powershell
python .\.codex\skills\musical-song-production\scripts\write_midi_sketch.py --song-slug before-your-name --out music\before-your-name\before-your-name-sketch.mid
```

Use `scripts/write_backing_midi.py` for no-guitar backing files:

```powershell
python .\.codex\skills\musical-song-production\scripts\write_backing_midi.py --song-slug before-your-name --out-dir music\before-your-name
```

If a request needs notation beyond the script, write `arrangement.md` and explain the MIDI limitation instead of pretending the file is complete.
