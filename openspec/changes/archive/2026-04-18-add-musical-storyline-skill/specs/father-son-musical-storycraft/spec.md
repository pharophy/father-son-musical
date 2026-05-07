## ADDED Requirements

### Requirement: Repository-local musical storycraft skill
The system SHALL provide a repository-local Codex skill for creating, modifying, and maintaining the storyline of the father/son musical.

#### Scenario: User asks for musical storyline work
- **WHEN** the user asks to create, modify, outline, revise, or continue the father/son musical storyline
- **THEN** the system uses the musical storycraft skill and follows its workflow before generating story changes

#### Scenario: Skill metadata is discoverable
- **WHEN** Codex lists available skills
- **THEN** the musical storycraft skill metadata describes its use for father/son musical story development, scene work, song mapping, motif mapping, and continuity-preserving revisions

### Requirement: Required musical-theatre producer role prompt
The system SHALL include a required role/system prompt that is used whenever the musical storycraft skill is active.

#### Scenario: Skill is activated
- **WHEN** the musical storycraft skill is used
- **THEN** the agent first applies the role prompt before making story, scene, song, character, or motif decisions

#### Scenario: Role prompt guides creative judgment
- **WHEN** the agent evaluates or produces story material
- **THEN** the role prompt frames the agent as a musical-theatre book writer, dramaturg, lyric-development partner, and producer with specific responsibility for the father/son concept

### Requirement: Father and son lifecycle story arc
The system SHALL maintain the musical's core lifecycle arc from before the child's birth through the son's departure for college and independent adulthood.

#### Scenario: Full arc requested
- **WHEN** the user asks for the full storyline or act structure
- **THEN** the system covers pre-birth anticipation, birth or arrival, early childhood, learning and imitation, adolescence, conflict and independence, departure for college, and the beginning of the son's own life

#### Scenario: Partial scene requested
- **WHEN** the user asks for a scene or song moment within the musical
- **THEN** the system places the moment within the lifecycle arc and identifies what has changed in the father, the son, and their musical relationship

### Requirement: Two-voice or two-guitar dramatic language
The system SHALL treat the back-and-forth between Voice/Guitar 1 and Voice/Guitar 2 as a central storytelling device.

#### Scenario: Voice/Guitar 1 represents the father
- **WHEN** the system describes or writes the father's musical role
- **THEN** Voice/Guitar 1 begins with mature technique, established lead capability, harmonic authority, and emotional restraint or depth appropriate to the father

#### Scenario: Voice/Guitar 2 represents the son
- **WHEN** the system describes or writes the son's musical role
- **THEN** Voice/Guitar 2 enters after the child's arrival, begins with simple limited musical ability, and grows in complexity over time

#### Scenario: Son surpasses father
- **WHEN** the story reaches late adolescence, college departure, or independent adulthood
- **THEN** Voice/Guitar 2 can match, answer, challenge, surpass, or transform Voice/Guitar 1 to represent the son's growth

### Requirement: Musical-writing best-practice guardrails
The system SHALL apply musical-theatre storycraft best practices while preserving the specific flavor of this father/son musical.

#### Scenario: Story material is generated
- **WHEN** the system creates an outline, scene, song map, or revision
- **THEN** it considers character want, obstacle, turning point, subtext, song function, escalation, reprise potential, and emotional payoff

#### Scenario: Song moment is proposed
- **WHEN** the system proposes a song or musical sequence
- **THEN** it identifies the dramatic function of the song and how the two voices or guitars interact within that function

### Requirement: Canonical story arc document
The system SHALL save generated and revised storyline material to `docs/story-arc.md` as the canonical repository story artifact.

#### Scenario: Story arc document is created
- **WHEN** the system creates the initial father/son musical story arc
- **THEN** it writes `docs/story-arc.md` with sections for premise, character arcs, lifecycle structure, two-voice/two-guitar motif progression, act outline, scene or song map, and revision notes

#### Scenario: Story arc document is revised
- **WHEN** the user asks to modify prior story material
- **THEN** the system reads `docs/story-arc.md`, applies a continuity-preserving revision, and records what changed in the document

### Requirement: Continuity-preserving revisions
The system SHALL modify existing storyline material without discarding established character, plot, and motif continuity unless the user explicitly requests a reset.

#### Scenario: User requests a revision
- **WHEN** the user asks to change a beat, scene, song, character choice, or arc
- **THEN** the system identifies affected continuity, updates `docs/story-arc.md` as needed, and preserves unaffected decisions

#### Scenario: Revision conflicts with established arc
- **WHEN** a requested change conflicts with the established lifecycle arc or two-voice/two-guitar progression
- **THEN** the system explains the conflict and proposes a compatible alternative or asks for confirmation before overriding the prior direction
