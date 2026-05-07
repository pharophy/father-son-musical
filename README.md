# father-son-musical

This repository is an experiment in treating AI as a creative collaborator in music production rather than as a one-shot generator. The working question is simple: what happens when a human keeps authorship, taste, revision control, and final judgment, while AI contributes structure, drafts, analysis, arrangement support, voice-over planning, tone design, and production scaffolding?

The project is centered on an original father-and-son musical, but the larger subject is the workflow itself. The repo captures how story, lyrics, arrangement, audio analysis, MIDI generation, vocal rendering, pedal-tone design, and revision notes can all live in one versioned workspace where a human and AI iterate together.

## What this repo can do

### 1. Write original music

The repo can develop songs from dramatic intent through production artifacts, including:

- story-driven song briefs sourced from the musical arc
- lyric drafting and revision
- arrangement notes for the two-voice / two-guitar theatrical language
- MIDI sketch generation and backing-part generation
- vocal-demo planning and generated voice assets

Example working song:

- [Before Your Name brief](music/before-your-name/brief.md)
- [Before Your Name lyrics](music/before-your-name/lyrics.md)
- [Before Your Name arrangement](music/before-your-name/arrangement.md)

### 2. Read existing music and craft voice over it

The repo also supports a backing-track overlay workflow: analyze an existing track, identify a usable vocal region, write lyrics that fit the section, and generate or package a vocal-only layer for later DAW integration.

That workflow includes:

- backing-track analysis
- section and timing selection
- lyric-fit planning
- vocal-only render generation
- export bundles for import into a DAW

Example overlay project:

- [The Time is Now overlay brief](music/again/brief.md)
- [The Time is Now overlay notes](music/again/overlay-integration-notes.md)

### 3. Craft tones for the Valeton GP-200 pedal

The repo can create and document GP-200 preset tones, including generated preset files, trace artifacts, and summaries for later refinement or import.

It also applies infrastructure-as-code style discipline to tone design. Instead of treating the proprietary `.prst` file as the only source of truth, the workflow supports a readable desired-state JSON representation that can be versioned, diffed, reviewed, generated, and reapplied.

That enables two useful directions:

- define a target tone in JSON and compile or apply it into an importable GP-200 preset
- export an existing preset into structured JSON state instead of relying only on the opaque `.prst` format

In practice, that means the tone-design workflow becomes more auditable and repeatable: a musician can describe the target state, revise it over time, compare changes in Git, and regenerate a hardware-ready preset from the same declarative source.

Examples:

- [FATHER BYN preset summary](tones/FATHER%20BYN.summary.md)
- [FATHER BYN desired state JSON](tones/FATHER%20BYN.desired-state.json)
- [LULLABY BYN preset summary](tones/LULLABY%20BYN.summary.md)
- [LULLABY BYN desired state JSON](tones/LULLABY%20BYN.desired-state.json)
- [GP-200 automation scripts](scripts/gp200/README.md)

### 4. Preserve the full creative paper trail

This repo is not just for final outputs. It stores briefs, revisions, spec changes, generated assets, and process notes so the collaboration remains inspectable. That is part of the experiment: AI work becomes more useful when it is versioned, reviewable, and revisable instead of hidden behind a chat transcript.

## Produced songs and audio

### Final or near-final full-song renders

- [The Time is Now](music/again/The%20Time%20is%20Now.mp3)
- [Before Your Name sung demo](music/before-your-name/before-your-name-eleven-music.mp3)
- [Before Your Name final song](https://drive.google.com/file/d/1GqSItyq8TA5TP_okDlBEbutrfo9WWZDx/view?usp=drive_link)

### Vocal-only or guide renders

- [Again overlay vocal-only](music/again/again-overlay-vocal-only.mp3)
- [Before Your Name vocal-only stem](music/before-your-name/before-your-name-vocal-only.mp3)
- [Before Your Name voice guide](music/before-your-name/before-your-name-voice.mp3)

### Backing or stem references

- [The Time is Now no-lead backing](music/again/The%20Time%20is%20Now_no_lead.mp3)
- [Before Your Name Cakewalk vocal-only import asset](music/before-your-name/cakewalk-sonar-project/Audio/before-your-name-vocal-only.mp3)
- [Again overlay stem-package vocal-only](music/again/overlay-stem-package/again-overlay-vocal-only.mp3)
- [Again overlay stem-package backing](music/again/overlay-stem-package/The%20Time%20is%20Now_no_lead.mp3)

## Repo structure

- `docs/`: story arc and higher-level project direction
- `music/`: per-song folders with briefs, lyrics, arrangements, MIDI, renders, and revision history
- `tones/`: GP-200 presets and supporting artifacts
- `scripts/`: automation, including GP-200 tooling
- `openspec/`: specs and change history for the workflows themselves
- `.codex/skills/`: repo-local AI skills that drive the repeatable collaboration workflows

## Notes

- Large audio and preset assets are tracked with Git LFS.
- Local secrets such as `.env` are intentionally ignored.
- The aim is not to prove that AI replaces musicians. The aim is to test whether AI can become a disciplined collaborator inside a human-led music production process.
