## Why

The project now has a canonical father/son musical story arc and song map in `docs/story-arc.md`, but it does not yet have a repeatable workflow for turning those song slots into lyrics, musical parts, MIDI sketches, or sung demos. A dedicated skill will keep song creation tied to dramatic function, character arc, and the two-voice/two-guitar language instead of producing disconnected standalone songs.

## What Changes

- Add a repository-local Codex skill for writing and revising songs from the song list in `docs/story-arc.md`.
- Support lyric drafts, song forms, melody/chord sketches, guitar/voice parts, lead sheets, and arrangement notes.
- Support MIDI output for musical parts when deterministic generation is feasible.
- Support optional ElevenLabs singing-voice demo generation through a guarded integration that requires configured credentials and avoids assuming live network/API access.
- Define song artifact conventions so each song can keep lyrics, structure, arrangement, MIDI, vocal-demo metadata, and revision notes together.
- Require the skill to preserve story continuity, song function, character voice, motif progression, and the father/son two-guitar or two-voice dramatic device.
- No breaking changes.

## Capabilities

### New Capabilities
- `musical-song-production`: Covers the skill, role prompt, song artifact model, lyric drafting, musical part drafting, MIDI generation, ElevenLabs vocal-demo workflow, and continuity-preserving song revisions based on `docs/story-arc.md`.

### Modified Capabilities
- None.

## Impact

- Adds a new skill under `.codex/skills/` for musical song writing and production.
- Adds references for songwriting craft, musical-theatre lyric rules, two-voice/two-guitar arrangement, MIDI artifact generation, and ElevenLabs vocal-demo guardrails.
- Adds a repository output convention for generated song artifacts under `music/<song-slug>/`.
- May add scripts for deterministic MIDI generation and optional vocal-demo request packaging.
- Does not require ElevenLabs access for core lyric or MIDI drafting; live vocal generation remains conditional on user-provided credentials and approved network access.
