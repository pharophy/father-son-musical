## Why

The current song-production workflow can draft songs and generate demo vocals, but it does not accept an existing piece of music and build a fitted vocal on top of that source. Adding an overlay workflow closes the gap between lyric ideation and usable production output by letting the system analyze a backing track, identify likely vocal entry regions, write lyrics for those regions, and generate an aligned voice track.

## What Changes

- Add a new vocal-overlay production capability for ingesting an existing audio file, segmenting it into candidate vocal regions, and producing a timing plan for lyric placement.
- Extend the musical song-production workflow so it can create lyrics and vocal-demo artifacts against an existing backing track, not only against songs derived from `docs/story-arc.md`.
- Add stable artifact outputs for overlay analysis, lyric fit decisions, vocal generation requests, aligned vocal stems, and integration notes.
- Add guardrails for provider use, rights, source-audio provenance, and failure modes when timing confidence is too low for automatic voice generation.

## Capabilities

### New Capabilities
- `vocal-overlay-production`: Analyze an existing music file, identify viable vocal entry sections, fit lyrics to those sections, and generate an aligned vocal track for integration with the source song.

### Modified Capabilities
- `musical-song-production`: Expand the existing song-production skill so it can write and revise lyrics, create vocal-demo metadata, and store outputs for backing-track overlay workflows in addition to story-arc-native songs.

## Impact

- Affected specs: `openspec/specs/musical-song-production/spec.md` and a new `openspec/specs/vocal-overlay-production/spec.md`
- Likely affected skill assets under `.codex/skills/musical-song-production/`, especially prompt metadata, workflow references, artifact guidance, and vocal-generation scripts
- New or updated scripts for audio analysis, timing manifests, lyric fitting, and aligned vocal-stem generation
- Provider integrations for optional vocal synthesis and possible audio preprocessing, with explicit approval and credential requirements
