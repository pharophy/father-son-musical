# Backing-Track Overlay Workflow

Use this path when the user already has a piece of music and wants to add a voice on top of it.

## Core Stages

1. Analyze the source audio.
2. Identify candidate vocal-entry regions.
3. Choose one target region and fit lyrics to its phrasing constraints.
4. Prepare provider metadata and guardrail checks.
5. Generate an overlay-ready dry vocal stem only if timing confidence and rights prerequisites are satisfied.
6. Export an integration package for DAW placement even if no provider call happens.

## Required Artifacts

- `overlay-source-brief.md`
- `overlay-analysis.json`
- `overlay-region-map.json`
- `overlay-lyrics-fit.md`
- `overlay-vocal-request.json`
- `overlay-vocal-demo.md`
- `overlay-integration-notes.md`
- optional `<song-slug>-overlay-vocal-only.mp3`
- optional `overlay-stem-package/`

## Source-Audio Rules

- Record source path, title, duration, file format, and provenance status.
- Prefer WAV analysis for deterministic timing extraction.
- If the source is a format the local scripts cannot analyze deeply, preserve partial metadata and require user-supplied timing or a manual review step.
- Do not assume a final vocal entry point from one low-confidence heuristic. Expose the candidate regions and explain why they were chosen.

## Candidate Region Rules

Each candidate region should include:

- `id`
- `startSeconds`
- `endSeconds`
- estimated bar count
- phrase count
- approximate syllable budget
- confidence
- rationale

Bias toward regions that:

- avoid stepping on intros or dense transitions
- have enough phrase length for a complete lyrical thought
- can be described and imported cleanly in a DAW

## Lyric-Fit Rules

- Draft for the selected region, not for the song in general.
- Use section labels if the region carries a verse, chorus, bridge, tag, or callout role.
- State the planned number of phrases and the target syllable budget per phrase.
- If the lyric overruns the selected region, revise it or mark the fit problem before any provider call.

## Guardrails

- Require explicit user approval, network approval, source authorization, and voice authorization before live provider calls.
- Do not imitate a protected voice or generate against unclear source rights.
- If timing confidence is too low for safe automation, stop after writing the planning artifacts and mark the run as deferred.

## DAW Hand-Off

- Treat the vocal output as a dry overlay-ready stem unless a deterministic merge path exists.
- Always write placement notes, offsets, and target timestamps into `overlay-integration-notes.md`.
- When possible, package the source reference, vocal stem, region map, and request metadata into `overlay-stem-package/`.
