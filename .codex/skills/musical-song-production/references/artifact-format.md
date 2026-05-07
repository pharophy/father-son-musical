# Song Artifact Format

Store each song under:

```text
music/<song-slug>/
```

Use stable filenames:

- `brief.md`: dramatic and musical brief
- `lyrics.md`: current lyric draft
- `arrangement.md`: musical parts, form, tempo, key, and performance notes
- `overlay-source-brief.md`: source-audio provenance, timing summary, and target overlay role
- `overlay-analysis.json`: raw analysis metadata including duration, tempo estimate, confidence, and section stats
- `overlay-region-map.json`: candidate vocal-entry windows with timestamps, phrase lengths, rationale, and confidence
- `overlay-lyrics-fit.md`: lyric-placement notes, syllable budgets, and selected-region constraints
- `overlay-vocal-request.json`: provider request metadata, guardrail status, selected region, and output targets
- `overlay-vocal-demo.md`: overlay-specific generation notes, prerequisites, and fail-closed status
- `overlay-integration-notes.md`: DAW import, alignment offset, and stem/package guidance
- `<song-slug>-overlay-vocal-only.mp3`: overlay-ready dry vocal stem when available
- `overlay-stem-package/`: reusable overlay package with source reference, vocal stem, manifests, and import instructions
- `<song-slug>-sketch.mid`: deterministic MIDI sketch only when explicitly requested or documented as a sketch
- `<song-slug>-backing-combined.mid`: combined no-guitar backing MIDI
- `<song-slug>-bass.mid`, `<song-slug>-drums.mid`, etc.: separate backing MIDI files for DAW import
- `<song-slug>-vocal-only.mp3`: generated vocal-only stem for DAW import when available
- `<song-slug>-full-demo.mp3`: full generated song demo with accompaniment when requested
- `cakewalk-sonar-project/`: DAW-ready import bundle with full-track files, manifest, and import instructions
- `vocal-demo.md`: ElevenLabs or other vocal-demo plan and metadata
- `revisions.md`: dated revision notes

Slug rules:

- Lowercase ASCII.
- Replace spaces and punctuation with hyphens.
- Keep titles stable after first creation unless the song is renamed intentionally.

Full-track rule:

- MIDI and voice outputs are full-song artifacts by default.
- Partial outputs must be explicitly named with `sketch`, `excerpt`, or `loop` and documented in `arrangement.md` or `vocal-demo.md`.

Overlay rule:

- `overlay-region-map.json` is the timing source of truth for backing-track overlay work.
- If no provider call is made, `overlay-vocal-request.json` and `overlay-vocal-demo.md` must explain why and still leave the lyric-fit artifacts usable.
- If the generated vocal is intended for manual DAW placement, `overlay-integration-notes.md` must name the target region start time and any lead-in or trim assumptions.
