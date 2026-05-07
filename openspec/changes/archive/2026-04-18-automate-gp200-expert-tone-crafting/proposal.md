## Why

Crafting high-quality tones on the GP-200 is currently manual, slow, and dependent on repeated interaction with the `GP-200 Edit` desktop software. We need a repeatable automation layer that can take control of the editor, apply expert patch-building decisions, and converge on polished tones without treating the device like a black box.

## What Changes

- Add an automation capability that can launch or attach to `GP-200 Edit` on Windows, identify editor state where possible, and fail closed when reliable live control is unavailable.
- Add a tone-authoring capability that can translate a requested target sound into a structured patch plan, desired-state JSON, and importable `.prst` file with traceable settings.
- Add a desired-state JSON capability that can represent the complete target GP-200 patch, save it under `tones/`, and render it into an importable checksum-valid `.prst` file on demand.
- Add a repository-local Codex skill and dedicated producer role/system prompt that reuses the desired-state workflow for on-demand GP-200 tone creation from user sound descriptions.
- Define guardrails for editor state, patch safety, manual import/export, save behavior, and recovery when the editor is in an unexpected view or fails to reflect expected values.
- Establish a validation workflow for confirming that generated tones match the intended routing context such as `FRFR`, `headphones`, `interface`, `amp front`, `amp return`, or `4CM`.

## Capabilities

### New Capabilities
- `gp200-editor-control`: Control the GP-200 desktop editor safely enough to open or attach to the software, detect known views where possible, and stop before unsafe live mutation.
- `expert-tone-authoring`: Build expert-grade GP-200 tones from musical intent, routing context, and stylistic targets by planning, applying, validating, and saving patch settings.
- `gp200-desired-state-rendering`: Store complete desired tone states as JSON and convert them into importable GP-200 `.prst` files with trace output.
- `gp200-tone-crafter-skill`: Provide repository-local skill instructions, producer role prompt, desired-state references, schema, and output conventions so future sessions can generate GP-200 tones on demand.

### Modified Capabilities

None.

## Impact

- Affects Windows automation tooling, editor session handling, `.prst` rendering, and local scripts or agents that support GP-200 tone generation.
- Introduces a tone-planning layer that maps user intent to GP-200 modules, parameter changes, desired-state JSON, and validation steps.
- Adds repository `tones/` outputs for generated `.prst`, desired-state JSON, trace JSON, and optional summaries.
- Adds `.codex/skills/gp200-tone-crafter` as the reusable local skill for this workflow.
- Requires robust handling for UI drift, unsaved patch state, safe patch persistence, and manual import/export expectations.
