## ADDED Requirements

### Requirement: Repository-local song production skill
The system SHALL provide a repository-local Codex skill for writing and revising songs from the father/son musical song list.

#### Scenario: User asks for song creation
- **WHEN** the user asks to write lyrics, draft a song, create musical parts, generate MIDI, or create a singing demo for a song from the musical
- **THEN** the system uses the song production skill and reads `docs/story-arc.md` before creating song artifacts

#### Scenario: Skill metadata is discoverable
- **WHEN** Codex lists available skills
- **THEN** the song production skill metadata describes lyric writing, song forms, musical parts, MIDI generation, ElevenLabs vocal demos, and continuity-preserving revisions for the father/son musical

### Requirement: Song brief from story arc
The system SHALL create or update a song brief before producing lyrics, MIDI, or vocal-demo outputs.

#### Scenario: Song exists in story arc
- **WHEN** the requested song appears in `docs/story-arc.md`
- **THEN** the system derives the song brief from the song's dramatic function, characters, turn, motif state, and placement in the lifecycle arc

#### Scenario: Song is missing from story arc
- **WHEN** the requested song does not appear in `docs/story-arc.md`
- **THEN** the system asks whether to add it to the story arc or create an exploratory song draft outside the canonical song list

### Requirement: Musical-theatre lyric drafting
The system SHALL generate lyrics that serve the song's dramatic function and preserve character voice.

#### Scenario: Lyrics are drafted
- **WHEN** the system writes a lyric draft
- **THEN** it includes song title, dramatic function, speaker or singers, song form, lyric sections, and notes on what changes by the end of the song

#### Scenario: Lyrics conflict with character or story continuity
- **WHEN** a requested lyric direction conflicts with `docs/story-arc.md`
- **THEN** the system explains the conflict and proposes a compatible adjustment before overwriting the song direction

### Requirement: Two-voice or two-guitar musical parts
The system SHALL create musical parts that preserve the father/son two-voice or two-guitar dramatic language.

#### Scenario: Father part is created
- **WHEN** a song includes Voice/Guitar 1
- **THEN** the father part reflects maturity, harmonic grounding, lead capability, restraint, or accompaniment according to the song's placement in the arc

#### Scenario: Son part is created
- **WHEN** a song includes Voice/Guitar 2
- **THEN** the son part reflects the son's current developmental stage from simple echo through independent lead capability

### Requirement: MIDI sketch generation
The system SHALL support generating MIDI sketches for song musical parts.

#### Scenario: MIDI requested
- **WHEN** the user requests MIDI for a song
- **THEN** the system writes one or more `.mid` files with track names that identify the song, role, instrument or voice, tempo, key, and part purpose

#### Scenario: MIDI cannot be generated deterministically
- **WHEN** the requested MIDI output requires unsupported notation, timing, instrument, or performance detail
- **THEN** the system writes a textual arrangement plan and explains the unsupported detail before skipping or simplifying MIDI generation

### Requirement: ElevenLabs vocal-demo workflow
The system SHALL support optional ElevenLabs singing-voice demo generation with explicit guardrails.

#### Scenario: Vocal demo requested with credentials
- **WHEN** the user requests an ElevenLabs vocal demo and required credentials, voice authorization, and network approval are available
- **THEN** the system generates or prepares vocal-demo output and records provider, voice, source lyric, request metadata, and resulting file path

#### Scenario: Vocal demo requested without prerequisites
- **WHEN** the user requests an ElevenLabs vocal demo but credentials, voice authorization, or network approval are missing
- **THEN** the system creates the lyric, song brief, and vocal direction artifacts without calling ElevenLabs and reports the missing prerequisite

### Requirement: Per-song artifact storage
The system SHALL store song outputs in dedicated per-song folders under `music/`.

#### Scenario: Song artifact is created
- **WHEN** the system creates song lyrics, arrangements, MIDI, vocal-demo metadata, or revision notes
- **THEN** it writes them under `music/<song-slug>/` using stable filenames for brief, lyrics, arrangement, MIDI, vocal metadata, and revisions

#### Scenario: Song artifact is revised
- **WHEN** the user asks to revise an existing song artifact
- **THEN** the system reads the existing `music/<song-slug>/` folder and `docs/story-arc.md`, applies a continuity-preserving revision, and records what changed

### Requirement: Rights and safety guardrails
The system SHALL avoid unsafe or unauthorized song and voice generation requests.

#### Scenario: User requests imitation of protected material
- **WHEN** the user asks to imitate a living artist, copyrighted song, or unauthorized voice
- **THEN** the system redirects to original creative choices that serve the musical without copying or impersonating the protected source

#### Scenario: User provides authorized voice material
- **WHEN** the user provides or selects a voice for generated singing
- **THEN** the system records that user authorization is required before any provider call and does not hard-code private voice credentials in the repository
