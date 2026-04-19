## ADDED Requirements

### Requirement: Tone request normalization
The system SHALL convert each tone request into a normalized tone brief before planning editor actions.

#### Scenario: Complete tone request
- **WHEN** the user provides a target style, routing context, and intended use
- **THEN** the system creates a tone brief containing those inputs and any relevant constraints

#### Scenario: Missing routing context
- **WHEN** the user requests a tone without specifying output routing
- **THEN** the system MUST ask for or infer a routing context before planning `AMP`, `CAB`, and `No CAB` behavior

### Requirement: Structured patch recipe generation
The system SHALL compile a normalized tone brief into a structured GP-200 patch recipe before controlling the editor.

#### Scenario: Expert recipe created
- **WHEN** the tone brief is valid
- **THEN** the system creates a recipe with module choices, signal-chain assumptions, parameter targets, validation checkpoints, and save metadata

#### Scenario: Unsupported request
- **WHEN** the tone brief requires GP-200 behavior outside supported module or routing capabilities
- **THEN** the system rejects the recipe with a clear unsupported-capability reason

### Requirement: Desired-state tone representation
The system SHALL support a JSON desired-state format that can represent a complete GP-200 tone before binary rendering.

#### Scenario: Desired state generated from user intent
- **WHEN** the user asks for a new GP-200 tone from a sound description
- **THEN** the system can create desired-state JSON under `tones/` containing patch name, source export, output paths, routing, save policy, tags, and all 11 module states

#### Scenario: Desired state is reviewable
- **WHEN** desired-state JSON is created
- **THEN** each module entry includes an active flag, an algorithm name, and parameter values keyed by names from `algorithm.xml`

#### Scenario: Desired state is invalid
- **WHEN** desired-state JSON references an unknown algorithm, unknown parameter, missing module, overlong patch name, or out-of-range value
- **THEN** the system rejects rendering with a clear validation error before writing a `.prst`

### Requirement: Desired-state PRST rendering
The system SHALL render valid desired-state JSON into an importable GP-200 `.prst` file.

#### Scenario: Desired state rendered successfully
- **WHEN** desired-state JSON is valid and the source `.prst` is available
- **THEN** the system writes the generated `.prst` under `tones/`, recalculates the GP-200 checksum, and writes trace JSON and optional summary files declared by the desired state

#### Scenario: Source guardrail mismatch
- **WHEN** desired-state JSON includes `expectedSha256` and the source `.prst` hash differs
- **THEN** the system stops before rendering and reports the mismatch

#### Scenario: Output inspection
- **WHEN** desired-state rendering completes
- **THEN** the system can inspect the generated `.prst` and report patch name, checksum, active modules, algorithms, and parameter values

### Requirement: Repository-local tone crafting skill
The system SHALL provide repository-local skill instructions for future GP-200 tone generation sessions.

#### Scenario: User asks for a new GP-200 tone
- **WHEN** a future session receives a request to create or refine a GP-200 tone
- **THEN** the `gp200-tone-crafter` skill instructs the agent to create or read desired-state JSON, save artifacts under `tones/`, render `.prst` with `apply-state`, and validate checksum/import readiness

#### Scenario: Skill role is activated
- **WHEN** the `gp200-tone-crafter` skill is used
- **THEN** the agent first applies the producer/tone-designer role prompt from the skill references before making tone decisions

#### Scenario: Available options are needed
- **WHEN** the agent needs valid algorithms, parameters, ranges, or menu IDs
- **THEN** the skill points to `algorithm.xml` lookup instructions and the desired-state format reference

### Requirement: Routing-aware amp and cabinet decisions
The system MUST choose `AMP`, `CAB`, and `No CAB` behavior according to the selected output routing context.

#### Scenario: Full-range monitoring route
- **WHEN** the routing context is `FRFR`, `headphones`, or `interface`
- **THEN** the recipe keeps amp and cabinet modeling enabled unless the tone brief explicitly requires otherwise

#### Scenario: Guitar amp front input route
- **WHEN** the routing context is `amp front`
- **THEN** the recipe disables amp and cabinet modeling unless the tone brief explicitly requires a special-case configuration

#### Scenario: Guitar amp return route
- **WHEN** the routing context is `amp return`
- **THEN** the recipe may enable amp modeling and MUST avoid double cabinet simulation by disabling cabinet modeling or using an equivalent no-cab routing decision

#### Scenario: Four cable method route
- **WHEN** the routing context is `4CM`
- **THEN** the recipe places drive-oriented preamp effects before the external amp preamp, time-based effects in the loop, and avoids internal amp and cabinet modeling by default

### Requirement: Expert gain and effects staging
The system SHALL apply tone-building heuristics that stage gain, noise reduction, EQ, modulation, delay, and reverb in an expert order.

#### Scenario: High gain tone
- **WHEN** the requested tone is modern high gain
- **THEN** the recipe tightens low end before the amp stage, controls noise without choking sustain, and uses cabinet or post-EQ cuts to manage harshness

#### Scenario: Clean or edge-of-breakup tone
- **WHEN** the requested tone is clean or edge-of-breakup
- **THEN** the recipe prioritizes amp/cab selection, moderate compression or boost behavior, level matching, and tasteful ambience

#### Scenario: Ambient tone
- **WHEN** the requested tone is ambient or cinematic
- **THEN** the recipe prioritizes stereo-compatible modulation, delay, reverb, and BPM-aware time effects where supported by the routing context

### Requirement: Iterative refinement support
The system SHALL support refinement of a generated tone using listening feedback without discarding the original recipe trace.

#### Scenario: User requests refinement
- **WHEN** the user provides feedback such as too bright, too muddy, too compressed, too dry, or too noisy
- **THEN** the system creates a revised recipe that preserves prior settings and records the targeted adjustments

#### Scenario: Refinement is applied
- **WHEN** a revised recipe is executed successfully
- **THEN** the system updates the saved patch or creates a new variant according to the requested save policy
