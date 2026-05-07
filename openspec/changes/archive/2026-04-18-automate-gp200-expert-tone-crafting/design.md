## Context

The current workspace already contains the GP-200 firmware manual, an operator index, and evidence that `GP-200 Edit` is installed on Windows. That gives us domain knowledge for patch architecture and routing rules, but there is no automation layer yet for launching the editor, confirming device readiness, navigating views, or applying parameter changes consistently.

This change introduces both safe editor automation and expert tone-authoring logic. The automation side must tolerate editor-state drift and unsaved patch state, but live device mutation is no longer required for completion because manual import/export is acceptable. The authoring side must convert tone intent into concrete GP-200 module choices and parameter values while respecting routing context such as `FRFR`, `headphones`, `interface`, `amp front`, `amp return`, and `4CM`.

The current implemented workflow favors desired-state JSON rendered to `.prst` files under `tones/` because GP-200 Edit exposes limited readable UI Automation state. A repository-local Codex skill now captures this workflow and always applies a dedicated producer/tone-designer role prompt for future tone-generation sessions.

## Goals / Non-Goals

**Goals:**
- Provide a deterministic support layer for `GP-200 Edit` on Windows.
- Separate editor interaction from tone-planning logic so each can be validated independently.
- Encode repeatable tone-building heuristics using the manual-derived routing and module constraints already captured in the workspace.
- Make automation safe by detecting unexpected screens and unsaved edits before taking destructive actions.
- Persist the finished tone with a readable summary of what was applied.
- Persist generated user-facing tone files under `tones/`.
- Provide a repository-local skill that can generate desired-state JSON, read desired-state JSON, and render it into `.prst` on demand.

**Non-Goals:**
- Reverse engineer the GP-200 USB/MIDI protocol or require undocumented live device control.
- Guarantee sonic perfection from fully autonomous parameter search without human listening feedback.
- Cover every GP-200 feature in the first iteration, such as looper, drum, MIDI-device-control mode, or firmware management.
- Build a cross-platform solution outside Windows.

## Decisions

### Decision: Use a layered architecture with editor control below tone authoring

The implementation should be split into:
- A `session/controller` layer that launches or attaches to `GP-200 Edit`, identifies known editor state where possible, and exposes safe editor actions.
- A `navigation/selectors` layer that knows how to reach patch-editing views and interact with modules and parameters.
- A `tone planner` layer that translates user intent into a patch recipe.
- A `desired state` layer that records the full target patch as JSON before binary rendering.
- A repository-local `gp200-tone-crafter` skill that tells future agents how to use the desired-state layer and producer role prompt.
- A `validation/persistence` layer that verifies expected editor state or `.prst` integrity and saves the patch plus a machine-readable summary.

This separation keeps tone logic independent from fragile UI selectors and makes recovery logic reusable.

Alternatives considered:
- A single end-to-end automation script was rejected because UI changes and tone logic changes would be tightly coupled.
- Driving tone creation purely from ad hoc prompts was rejected because it would be hard to validate, replay, or debug.

### Decision: Represent tones as an intermediate patch recipe before touching the UI

Each requested tone should first be compiled into a structured recipe containing:
- Output context and routing assumptions
- Ordered module decisions such as `PRE`, `DST`, `AMP`, `CAB`, `EQ`, `MOD`, `DLY`, `RVB`
- Parameter targets and allowed ranges
- Validation checkpoints and save metadata

The controller should only execute a validated recipe, not free-form instructions. This enables dry-run review, logging, and retries at specific failed steps.

Alternatives considered:
- Writing parameters directly from the natural-language request was rejected because it provides no stable contract between planning and execution.

### Decision: Persist desired-state JSON as the reviewable source of generated tones

The current working path uses exported GP-200 `.prst` files as the safe mutation surface because the editor UI is custom-rendered and does not expose reliable parameter controls through UI Automation. Each generated tone should therefore be represented by desired-state JSON before rendering:
- `version`, patch `name`, source `.prst`, output paths, routing, save policy, and tags
- all 11 modules in GP-200 order: `PRE`, `WAH`, `DST`, `AMP`, `NR`, `CAB`, `EQ`, `MOD`, `DLY`, `RVB`, `VOL`
- each module's active flag, algorithm name, and parameter map using names from `algorithm.xml`

The renderer validates that algorithms and parameters exist, validates numeric ranges, writes the binary `.prst`, recalculates the GP-200 checksum, and writes trace output under `tones/`.

Alternatives considered:
- Keeping only generated `.prst` binaries was rejected because it is not reviewable or easy to refine.
- Encoding every tone as a hardcoded script function was rejected because it does not scale to arbitrary user tone requests.

### Decision: Store reusable tone workflow knowledge in a repository-local skill with a required producer role

The project now includes `.codex/skills/gp200-tone-crafter`, which documents how to convert a user sound description into desired-state JSON, where to save generated outputs, and how to validate `.prst` rendering. The skill starts by loading `references/producer-role.md`, a dedicated producer/tone-designer system prompt that guides sonic decisions, routing assumptions, artifact creation, validation, and concise user responses. This keeps future sessions from rediscovering GP-200 file layout, checksum behavior, `algorithm.xml` lookup rules, or the intended production mindset.

Alternatives considered:
- Relying only on conversation history was rejected because future sessions may not have this context.
- Keeping the workflow only in `scripts/gp200/README.md` was rejected because skills are the triggerable mechanism for agent behavior.

### Decision: Use explicit guardrails for patch safety and state recovery

Before live editor mutation, the automation must verify:
- The software is running and foregroundable
- The current view is recognized
- The target patch and bank context are known
- Unsaved changes are either intentionally overwritten or preserved

If any checkpoint fails, the system must stop and surface a recoverable error instead of guessing.

For the accepted workflow, manual import/export plus desired-state `.prst` rendering is sufficient and does not require live GP-200 connection readiness detection.

Alternatives considered:
- Blind retries were rejected because accidental patch overwrites are a worse failure mode than a paused run.

### Decision: Start with deterministic expert heuristics instead of autonomous audio optimization

The first implementation should rely on explicit expert rules derived from the manual and operator index:
- Routing-aware `AMP/CAB/No CAB` decisions
- Genre and gain-structure templates
- Module ordering heuristics
- Save and validation checklists

This provides a stable foundation before attempting audio-loop feedback or iterative tone matching.

Alternatives considered:
- Audio-in-the-loop optimization was deferred because it introduces more dependencies, more ambiguity, and weaker debuggability in the initial release.

## Risks / Trade-offs

- [UI layout or selector drift] -> Mitigation: centralize selectors, require view verification before each action, and fail closed on unknown screens.
- [Binary `.prst` corruption] -> Mitigation: desired-state validation, exact `algorithm.xml` lookup, 1224-byte format checks, and checksum recomputation before import.
- [Live device/editor state is unreadable] -> Mitigation: use manual import/export with checksum-valid `.prst` rendering and stop before unsafe mutation.
- [Automation overwrites the wrong patch] -> Mitigation: require explicit target patch selection and confirm patch identity before applying the recipe.
- [Tone recipe quality is inconsistent across routing contexts] -> Mitigation: make routing context mandatory for expert-tone workflows and encode routing-specific defaults.
- [The system can apply settings but not confirm sound quality] -> Mitigation: log the resulting recipe and support iterative refinement requests based on listening feedback.

## Migration Plan

1. Introduce the editor-control capability with launch, readiness, navigation, and safe patch mutation primitives.
2. Add the expert-tone-authoring capability on top of the control layer using structured recipes.
3. Add desired-state JSON and `.prst` rendering for importable patch generation while UI control remains limited.
4. Add a repository-local skill and keep its references aligned with the renderer and `tones/` output convention.
5. Validate the workflow on a small set of representative tones across common routing contexts.
6. Expand recipe coverage only after the base workflow proves reliable.

Rollback is straightforward because this change adds artifacts and automation logic without requiring a persistent data migration.

## Open Questions

- Should future desired-state rendering support menu labels in addition to numeric `Switch` and `Combox` IDs?
