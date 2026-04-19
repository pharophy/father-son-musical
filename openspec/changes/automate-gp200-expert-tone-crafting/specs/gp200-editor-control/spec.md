## ADDED Requirements

### Requirement: Editor session startup
The system SHALL launch or attach to `GP-200 Edit` and establish a controlled editor session before attempting patch changes.

#### Scenario: Editor is not running
- **WHEN** the user starts a GP-200 automation workflow and `GP-200 Edit` is not running
- **THEN** the system launches the editor from the configured executable path and waits until the main window is ready

#### Scenario: Editor is already running
- **WHEN** the user starts a GP-200 automation workflow and `GP-200 Edit` is already running
- **THEN** the system attaches to the existing editor window without launching a duplicate instance

### Requirement: Device and editor readiness checks
The system MUST verify that the editor is controllable and the GP-200 connection state is acceptable before mutating a patch.

#### Scenario: Device is connected
- **WHEN** the editor session starts and the GP-200 is detected as connected
- **THEN** the system reports the session as ready for patch navigation and mutation

#### Scenario: Device is disconnected
- **WHEN** the editor session starts and the GP-200 is not detected as connected
- **THEN** the system stops before mutation and reports a recoverable connection error

### Requirement: Recognized navigation state
The system SHALL maintain a known editor navigation state before applying module or parameter operations.

#### Scenario: Recognized patch editing view
- **WHEN** the editor is in a recognized patch editing view
- **THEN** the system can select modules, inspect expected controls, and execute the next planned action

#### Scenario: Unknown editor view
- **WHEN** the editor is in an unknown or unsupported view
- **THEN** the system MUST stop or navigate back to a known safe state before applying any patch changes

### Requirement: Safe patch mutation
The system MUST apply patch mutations only after confirming the target patch context and handling unsaved changes.

#### Scenario: Target patch confirmed
- **WHEN** the target bank and patch are confirmed and unsaved-change policy is satisfied
- **THEN** the system applies the planned module and parameter changes in the requested order

#### Scenario: Unsaved changes are present
- **WHEN** the editor indicates unsaved changes and the workflow has not authorized overwrite or preservation
- **THEN** the system pauses before mutation and reports that user intent is required

### Requirement: Patch persistence and traceability
The system SHALL save completed patch changes and produce a trace of the applied operations.

#### Scenario: Patch saved successfully
- **WHEN** all planned patch operations complete and save is requested
- **THEN** the system saves the patch and records the patch name, target location, routing context, module selections, and parameter values

#### Scenario: Save fails
- **WHEN** the editor fails to save or the saved state cannot be verified
- **THEN** the system reports the failed save state and preserves the operation trace for recovery

#### Scenario: File-rendered patch saved
- **WHEN** the workflow renders a desired-state JSON file into `.prst` instead of mutating the live editor
- **THEN** the system saves the `.prst`, records source and output hashes, records checksum, and keeps a trace of the desired state and rendered inspection

#### Scenario: Current canonical tone artifact location
- **WHEN** the workflow creates user-facing tone artifacts
- **THEN** desired-state JSON, rendered `.prst`, trace JSON, and optional summaries are written under `tones/` by default
