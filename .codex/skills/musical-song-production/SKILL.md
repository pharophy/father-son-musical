---
name: musical-song-production
description: Write and revise father-son musical songs, or fit a vocal overlay to an existing backing track.
---

# Musical Song Production

Use this skill to either:

- turn song slots from `docs/story-arc.md` into lyrics, musical parts, MIDI sketches, and optional vocal-demo plans under `music/<song-slug>/`, or
- analyze an existing backing track, identify vocal-entry regions, fit lyrics to a selected region, and prepare an overlay-ready vocal stem workflow under `music/<song-slug>/`.

## Workflow

1. Read and follow [references/role-prompt.md](references/role-prompt.md) before making songwriting or arrangement decisions.
2. If the user provides an existing backing track, follow [references/backing-track-overlay.md](references/backing-track-overlay.md) and [references/artifact-format.md](references/artifact-format.md) before drafting lyrics or planning vocal generation.
3. If the request is for a story-arc song, read `docs/story-arc.md` and identify the requested song's title, dramatic function, characters, turn, lifecycle placement, and two-voice/two-guitar motif state.
4. If the requested story-arc song is not in `docs/story-arc.md`, ask whether to add it to the story arc or draft it as exploratory material.
5. Create or update `music/<song-slug>/` using [references/artifact-format.md](references/artifact-format.md).
6. Draft or revise:
   - `brief.md`
   - `lyrics.md`
   - `arrangement.md`
   - `vocal-demo.md`
   - `revisions.md`
   - overlay files such as `overlay-source-brief.md`, `overlay-region-map.json`, `overlay-lyrics-fit.md`, `overlay-vocal-request.json`, `overlay-vocal-demo.md`, and `overlay-integration-notes.md` when the request starts from an existing backing track
   - optional `*.mid` files
7. Use [references/lyric-writing.md](references/lyric-writing.md) for lyric craft and [references/two-voice-arrangement.md](references/two-voice-arrangement.md) for father/son musical parts.
8. For backing-track overlay analysis, use [scripts/analyze_backing_track.py](scripts/analyze_backing_track.py) to create source metadata and candidate vocal regions, then use [scripts/plan_vocal_overlay.py](scripts/plan_vocal_overlay.py) to write a production brief, lyric-fit notes, and provider metadata before any live synthesis call.
9. For MIDI, use [scripts/write_midi_sketch.py](scripts/write_midi_sketch.py) or [scripts/write_backing_midi.py](scripts/write_backing_midi.py), but generate full-song tracks by default. Partial MIDI is only allowed when the file is explicitly named and documented as a sketch. When generating backing parts, never generate guitar MIDI unless the user explicitly reverses this project rule.
10. For ElevenLabs vocal demos or overlays, follow [references/elevenlabs-vocal-demo.md](references/elevenlabs-vocal-demo.md). Prefer vocal-only stem outputs for DAW import unless the user requests a full generated backing track. Never hard-code credentials or call the provider without explicit user approval, source authorization, voice authorization, timing context, and network access.
11. For DAW export, use [references/cakewalk-sonar-export.md](references/cakewalk-sonar-export.md), [scripts/create_cakewalk_bundle.py](scripts/create_cakewalk_bundle.py), and [scripts/create_overlay_bundle.py](scripts/create_overlay_bundle.py) to create import-ready folders, manifests, and integration instructions.

## Output Rules

- Save all song-specific outputs under `music/<song-slug>/`.
- Keep lyrics original. Do not imitate living artists, copyrighted songs, or unauthorized voices.
- Keep `docs/story-arc.md` as the source of truth for the song list and dramatic placement when the request is a story-arc song. For backing-track overlay work, keep the source-audio analysis artifacts as the timing source of truth.
- Record meaningful changes in `music/<song-slug>/revisions.md`.
- Prefer usable creative artifacts over abstract notes: write the lyric, define the form, describe the arrangement, and create a MIDI sketch when feasible.
- For Cakewalk/Sonar workflows, generate or request vocal-only files separately from accompaniment so the user can import the voice track onto its own audio track.
- For backing tracks in this project, generate bass, drums, piano, pad, strings, or color instruments as needed, but never guitar. Guitar is reserved for live/user performance or explicit father/son motif work.
- Full-track rule: all generated MIDI and voice files must span the complete current song form from first intended downbeat through final tag/release. Do not create partial stems unless the user explicitly asks for a short sketch, preview, excerpt, or loop, and label those files with `sketch`, `excerpt`, or `loop`.
- Cakewalk/Sonar rule: generate a Cakewalk-ready bundle folder with copied full-track files, `project-manifest.json`, and `IMPORT_INSTRUCTIONS.md`. Do not claim to create a native `.cwp` file unless a reliable template or automation path exists.
- Overlay rule: if timing confidence is low or rights are unclear, stop before provider execution, preserve the analysis and lyric-fit artifacts, and mark the workflow as a deferral rather than claiming an aligned vocal output.
