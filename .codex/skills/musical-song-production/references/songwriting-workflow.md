# Songwriting Workflow

## Derive The Song Brief

For every song, read `docs/story-arc.md` and capture:

- Title
- Lifecycle placement
- Dramatic function
- Singer or singers
- Want
- Obstacle
- Turn
- Ending state
- Motif state
- Required artifacts

## Backing-Track Overlay Workflow

When the request starts from an existing piece of music instead of `docs/story-arc.md`:

1. Analyze the source audio and write `overlay-analysis.json`, `overlay-region-map.json`, and `overlay-source-brief.md`.
2. Choose or confirm a candidate region before drafting lyrics.
3. Draft lyrics against the selected region's syllable budget, phrase count, and intended dramatic role.
4. Write `overlay-lyrics-fit.md` before any provider call so the phrasing assumptions are inspectable.
5. Prepare `overlay-vocal-request.json` and `overlay-vocal-demo.md` with source provenance, voice authorization, timing confidence, and output targets.
6. If timing confidence is low or prerequisites are missing, stop at the planning artifacts and record the deferral.

## Draft The Song

1. Choose a song form that fits the dramatic pressure.
2. Write the lyric in sections, not as a prose block.
3. Define the musical conversation between Voice/Guitar 1 and Voice/Guitar 2.
4. Add arrangement notes that a musician can act on.
5. Generate a MIDI sketch when the part can be represented deterministically.
6. Record revisions.

## Revision Rules

- Preserve the story placement unless the user requests a story change.
- If a lyric revision changes character intent, update the brief.
- If an arrangement revision changes the father/son motif state, update arrangement notes and revisions.
- If the user asks for a missing song, ask whether it should be added to `docs/story-arc.md` or created as exploratory material.
- If a backing-track overlay revision changes the target timestamps, update `overlay-region-map.json`, `overlay-lyrics-fit.md`, `overlay-vocal-request.json`, and `overlay-integration-notes.md` together.
