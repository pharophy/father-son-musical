## ADDED Requirements

### Requirement: Existing-song analysis
The system SHALL accept an existing song or instrumental mix as source material for vocal-overlay planning.

#### Scenario: Source audio is provided
- **WHEN** the user provides an existing audio file for overlay work
- **THEN** the system records the source path, duration, detected tempo or timing grid when available, and enough analysis metadata to support vocal placement decisions

#### Scenario: Source audio cannot be analyzed confidently
- **WHEN** the system cannot derive a reliable timing or section map from the provided audio
- **THEN** the system reports the low-confidence analysis, preserves the partial findings, and avoids claiming a final vocal alignment

### Requirement: Candidate vocal-entry mapping
The system SHALL identify one or more candidate regions where a vocal can be added to the source song.

#### Scenario: Candidate regions are found
- **WHEN** the source analysis succeeds
- **THEN** the system outputs a region map that labels likely vocal-entry windows with timestamps, phrase lengths, and notes about why each region is viable

#### Scenario: User constrains the target section
- **WHEN** the user specifies a desired section, timestamp range, or song role for the vocal
- **THEN** the system prioritizes or limits the candidate-region map to the requested range

### Requirement: Lyric fitting against source timing
The system SHALL write lyrics that fit a selected vocal-entry region rather than only drafting unconstrained text.

#### Scenario: Lyrics are written for a target region
- **WHEN** the user selects or accepts a candidate vocal region
- **THEN** the system produces lyrics and vocal phrasing notes aligned to that region's approximate beat count, syllable budget, and dramatic intent

#### Scenario: Initial lyrics do not fit
- **WHEN** the drafted lyric exceeds or undershoots the selected region's phrasing constraints
- **THEN** the system revises the lyric or flags the fit issue before proceeding to voice generation

### Requirement: Aligned vocal-track generation
The system SHALL support generating a standalone vocal track aligned to the chosen source-song region.

#### Scenario: Generation prerequisites are available
- **WHEN** timing data, lyrics, provider access, credentials, and voice authorization are available
- **THEN** the system generates or prepares an aligned vocal-only output plus metadata that ties the output to the source region and lyric version

#### Scenario: Generation prerequisites are missing
- **WHEN** any required provider, credential, authorization, or timing prerequisite is missing
- **THEN** the system stops before provider execution and writes the lyric, alignment plan, and missing-prerequisite report

### Requirement: Overlay integration artifacts
The system SHALL emit artifacts that make the generated vocal usable in a DAW or follow-up mixing workflow.

#### Scenario: Vocal overlay output is created
- **WHEN** an aligned vocal track is produced
- **THEN** the system writes integration notes that include source-song reference, target timestamps, gain or mix notes if known, and the file paths for the generated vocal assets

#### Scenario: Preview mix is not deterministic
- **WHEN** the system cannot safely create a final merged mix with deterministic alignment or level control
- **THEN** it writes a reusable stem package and integration instructions instead of claiming a finished master

### Requirement: Source rights and provenance
The system SHALL preserve provenance and rights guardrails for source audio and generated voices.

#### Scenario: Authorized source and voice are provided
- **WHEN** the user supplies source audio and an authorized voice for overlay generation
- **THEN** the system records the source provenance and voice authorization alongside the generation metadata

#### Scenario: Rights are unclear
- **WHEN** the system lacks confidence that the source audio or requested voice use is authorized
- **THEN** the system declines provider execution and requests clarification or a safer alternative workflow
