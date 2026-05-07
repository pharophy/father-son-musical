## Context

The repository already has a `musical-song-production` skill with references, per-song artifact conventions, MIDI helpers, and optional ElevenLabs vocal-generation scripts. That workflow assumes the system is originating or revising a song from `docs/story-arc.md`. The new request adds a different entry point: start from an existing audio file, determine where a vocal can fit, write lyrics that conform to that space, and generate a vocal stem that can be dropped into the song.

The design has to bridge prompt-level songwriting work and concrete timing data. The main technical constraint is that timing confidence may vary based on the source audio. The workflow therefore needs a fail-closed path that can stop at analysis and lyric planning when alignment is not strong enough for trustworthy synthesis.

## Goals / Non-Goals

**Goals:**
- Extend the existing song-production skill instead of creating an unrelated parallel workflow
- Produce a deterministic artifact chain from source-audio intake through lyric-fit decisions and vocal-generation metadata
- Support optional provider-backed vocal synthesis only when credentials, authorization, and timing confidence are present
- Emit artifacts that are usable in a DAW even when a final merged mix is not generated automatically

**Non-Goals:**
- Build a full DAW or mastering pipeline inside the repo
- Guarantee studio-quality beat detection or phrase segmentation for every arbitrary mix
- Automatically imitate copyrighted singers or use unauthorized voices
- Promise a finished stereo master when only a vocal stem and integration plan can be produced reliably

## Decisions

### Reuse the existing `musical-song-production` skill as the orchestration surface
The user-facing behavior is close to the current songwriting workflow, and the repository already has the relevant prompt assets and output conventions. Extending that skill keeps discovery simple and lets the existing lyric and vocal-demo scripts share metadata and guardrails.

Alternative considered: create a separate overlay-only skill. Rejected because it would duplicate lyric-writing, artifact, and provider logic that already exists in the current song-production flow.

### Introduce a dedicated overlay-analysis artifact set
The workflow needs more than a normal song brief. It should create stable files for source provenance, candidate vocal regions, lyric-fit revisions, generation requests, and integration notes. These files should live alongside the existing `music/<song-slug>/` outputs so the user can inspect and revise each step without rerunning provider calls.

Alternative considered: store timing data only inside prompt transcripts or provider request JSON. Rejected because it would make revision and manual DAW integration brittle.

### Separate three stages: analyze, fit, generate
The system should model the workflow as:
1. Source-audio analysis and region mapping
2. Lyric drafting and phrase fitting against a chosen region
3. Vocal generation and export of an aligned vocal stem

This lets the workflow stop cleanly after stage 1 or 2 if confidence is low or provider access is unavailable.

Alternative considered: a single end-to-end command that goes from audio file to vocal stem in one pass. Rejected because it hides failure modes and makes revisions expensive.

### Treat final mix generation as optional, but aligned vocal-stem export as required
The core deliverable should be a vocal-only file and integration metadata. A preview mix can be added later if there is a deterministic and reviewable way to align and level it, but the spec should not depend on a fully automated final merge.

Alternative considered: require automatic merged-song export. Rejected because level balancing, effects, and timing nudges are likely DAW tasks, not deterministic repo tasks.

### Fail closed on timing uncertainty and rights ambiguity
If the source-audio analysis does not produce reliable timing markers, or if rights and voice authorization are unclear, the workflow should stop before synthesis and emit planning artifacts instead. This matches the existing provider-approval guardrails and reduces the chance of unusable or unsafe outputs.

Alternative considered: generate best-effort vocals regardless of confidence. Rejected because it would create misleading outputs and increase cleanup work.

## Risks / Trade-offs

- [Risk] Beat or section detection may be unreliable for dense or rubato source audio. → Mitigation: write confidence notes, preserve partial analysis, and require explicit user confirmation or manual timestamps before synthesis.
- [Risk] The existing song-production prompts may overfit to story-arc song creation. → Mitigation: split the prompt workflow so overlay requests use backing-track analysis context before lyric drafting.
- [Risk] Provider-generated vocals may not land exactly on the desired beat grid. → Mitigation: export timestamp manifests and integration notes so the user can nudge in a DAW without losing provenance.
- [Risk] Source-audio ownership may be unclear. → Mitigation: require provenance metadata and block provider execution when authorization is not established.
- [Risk] Artifact sprawl under `music/` may become inconsistent. → Mitigation: define stable overlay filenames and folder conventions in the updated skill references.

## Migration Plan

1. Update the `musical-song-production` skill metadata and references to include backing-track overlay requests.
2. Add analysis and alignment scripts that can read an existing audio file and emit a candidate-region manifest.
3. Add lyric-fit and vocal-generation metadata conventions that point at a chosen region and lyric revision.
4. Extend the existing vocal-generation scripts so they can create a vocal-only output aligned to the stored timing manifest.
5. Validate the workflow on at least one existing song asset in `music/` and confirm that the output includes analysis, lyrics, metadata, and either a vocal stem or a documented generation deferral.

Rollback is low risk because the work is additive and localized to the skill, scripts, and per-song artifacts.

## Open Questions

- Which audio-analysis library or external tool should be used for tempo, onset, and section detection in a way that fits the repo environment?
- Should the default output folder remain `music/<song-slug>/` for all overlay work, or should non-canonical source songs use a separate stable root such as `music/overlays/`?
- Do we want to support a deterministic preview mix export in this change, or defer that until after aligned-stem generation is proven reliable?
