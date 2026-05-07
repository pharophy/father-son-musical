## MODIFIED Requirements

### Requirement: Repository-local song production skill
The system SHALL provide a repository-local Codex skill for writing and revising songs from the father/son musical song list and for creating overlay vocals against an existing backing track.

#### Scenario: User asks for story-arc song creation
- **WHEN** the user asks to write lyrics, draft a song, create musical parts, generate MIDI, or create a singing demo for a song from the musical
- **THEN** the system uses the song production skill and reads `docs/story-arc.md` before creating song artifacts

#### Scenario: User asks for backing-track overlay work
- **WHEN** the user asks to add a voice to an existing piece of music
- **THEN** the system uses the song production skill, reads the backing-track analysis context, and routes the request through the overlay workflow before creating vocal artifacts

#### Scenario: Skill metadata is discoverable
- **WHEN** Codex lists available skills
- **THEN** the song production skill metadata describes lyric writing, song forms, musical parts, MIDI generation, backing-track overlay analysis, and vocal-demo generation for the father/son musical

### Requirement: Song brief from story arc
The system SHALL create or update a production brief before producing lyrics, MIDI, or vocal-demo outputs.

#### Scenario: Song exists in story arc
- **WHEN** the requested song appears in `docs/story-arc.md`
- **THEN** the system derives the production brief from the song's dramatic function, characters, turn, motif state, and placement in the lifecycle arc

#### Scenario: Backing track is supplied
- **WHEN** the user provides an existing piece of music for vocal-overlay work
- **THEN** the system derives the production brief from the source-song analysis, target section, intended vocal role, and any user-provided dramatic or stylistic direction

#### Scenario: Song is missing from story arc
- **WHEN** the requested song does not appear in `docs/story-arc.md` and no backing track is provided
- **THEN** the system asks whether to add it to the story arc or create an exploratory song draft outside the canonical song list

### Requirement: ElevenLabs vocal-demo workflow
The system SHALL support optional ElevenLabs singing-voice demo generation with explicit guardrails.

#### Scenario: Story-arc vocal demo requested with credentials
- **WHEN** the user requests an ElevenLabs vocal demo and required credentials, voice authorization, and network approval are available
- **THEN** the system generates or prepares vocal-demo output and records provider, voice, source lyric, request metadata, and resulting file path

#### Scenario: Backing-track vocal overlay requested with credentials
- **WHEN** the user requests a generated vocal for an existing backing track and required credentials, voice authorization, timing context, and network approval are available
- **THEN** the system generates or prepares vocal-only output aligned to the selected source-song region and records provider, voice, lyric version, timing metadata, and resulting file path

#### Scenario: Vocal demo requested without prerequisites
- **WHEN** the user requests a vocal demo or vocal overlay but credentials, voice authorization, network approval, or required timing context are missing
- **THEN** the system creates the lyric, production brief, and vocal direction artifacts without calling ElevenLabs and reports the missing prerequisite

### Requirement: Per-song artifact storage
The system SHALL store song outputs in dedicated per-song folders under `music/`.

#### Scenario: Story-arc song artifact is created
- **WHEN** the system creates song lyrics, arrangements, MIDI, vocal-demo metadata, or revision notes
- **THEN** it writes them under `music/<song-slug>/` using stable filenames for brief, lyrics, arrangement, MIDI, vocal metadata, and revisions

#### Scenario: Backing-track overlay artifact is created
- **WHEN** the system creates source analysis, lyric-fit notes, vocal timing manifests, vocal-only outputs, or integration notes for an existing piece of music
- **THEN** it writes them under `music/<song-slug>/` or another stable user-approved folder using stable filenames for the source brief, region map, lyrics, vocal metadata, aligned vocal output, and integration notes

#### Scenario: Song artifact is revised
- **WHEN** the user asks to revise an existing song artifact
- **THEN** the system reads the existing `music/<song-slug>/` folder, any relevant backing-track analysis, and `docs/story-arc.md` when applicable, applies a continuity-preserving revision, and records what changed
