## Context

The father/son musical has a canonical story artifact at `docs/story-arc.md`, including a scene and song map. The existing storycraft skill maintains the story arc; this change adds a separate song-production skill that converts song slots into usable creative artifacts: lyrics, song forms, melodic/chord concepts, guitar or voice parts, MIDI sketches, and optional vocal demos.

The skill must operate like a musical-theatre songwriter and arranger, not a generic lyric generator. Every song draft should answer why the moment must be sung, what changes during the song, who controls the musical line, and how the father/son two-voice or two-guitar device evolves.

## Goals / Non-Goals

**Goals:**
- Create a repository-local skill for writing and revising songs based on the song list in `docs/story-arc.md`.
- Define artifact conventions for per-song lyrics, song briefs, arrangement notes, MIDI files, vocal-demo metadata, and revision notes.
- Include a required role/system prompt for musical-theatre songwriting and production.
- Provide deterministic MIDI-generation guidance or scripts for basic parts such as melody, harmony, bass, rhythm, and two-guitar/voice call-and-response sketches.
- Provide guarded ElevenLabs workflow guidance for singing-voice demos when credentials and network access are available.

**Non-Goals:**
- Do not require ElevenLabs to create lyrics, lead sheets, or MIDI.
- Do not hard-code private API credentials or voice IDs.
- Do not imitate living artists or copyrighted songs on request.
- Do not replace the storycraft skill as the owner of `docs/story-arc.md`.
- Do not require full production-quality audio mixing in this change.

## Decisions

### Create a separate song-production skill

The skill will be separate from `father-son-musical-storycraft` because it has a different job: turning approved story/song-map material into song deliverables. The storycraft skill should remain responsible for story continuity; this skill should read `docs/story-arc.md` and write song artifacts.

Alternative considered: expand the storycraft skill. This was rejected because lyrics, arrangements, MIDI, and vocal rendering introduce extra workflow and integration concerns that would bloat the story skill.

### Store song artifacts under `music/`

The implementation should create `music/<song-slug>/` folders. Each folder can contain a song brief, lyric draft, arrangement notes, MIDI outputs, vocal-demo metadata, and revision notes. This keeps `docs/story-arc.md` readable while allowing songs to develop independently.

Alternative considered: write all song drafts into `docs/story-arc.md` or use a `songs/` folder. This was rejected because the story arc should remain a map, and the user requested `music/` as the root output folder.

### Use MIDI as the deterministic musical interchange format

MIDI generation should be scriptable and deterministic for sketches. The skill should support separate tracks for father voice/guitar, son voice/guitar, accompaniment, bass, rhythm, and guide melody where relevant.

Alternative considered: only write textual music descriptions. This was rejected because the user explicitly asked for musical parts in MIDI.

### Treat ElevenLabs generation as optional and guarded

The skill should prepare or invoke ElevenLabs singing-voice demo generation only when the user provides credentials, voice selection, and approval for network access. The skill should record request metadata and output paths but fail closed when credentials, permissions, or API behavior are unavailable.

Alternative considered: make ElevenLabs required for all songs. This was rejected because lyric and MIDI generation should work offline, and network/API access may not be available.

## Risks / Trade-offs

- Generated lyrics may drift from story function -> Mitigate by requiring a song brief tied to `docs/story-arc.md` before lyrics.
- MIDI sketches may sound mechanical -> Mitigate by treating MIDI as a draftable guide, not a final performance.
- ElevenLabs APIs, available voice models, or singing support can change -> Mitigate by isolating provider details in references/scripts and validating against current credentials at implementation time.
- Voice cloning or generated vocals can raise consent and rights issues -> Mitigate by requiring user-provided voice authorization and avoiding impersonation.
- Song folders can fragment continuity -> Mitigate by requiring each song artifact to cite its story-arc source song and revision notes.
