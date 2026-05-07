## 1. Discovery And Harness

- [x] 1.1 Confirm the installed `GP-200 Edit` executable path and document the launch command used by automation.
- [x] 1.2 Evaluate the available Windows automation surface for the editor, including UI Automation and image-based fallback viability.
- [x] 1.3 Create a minimal automation harness that can launch or attach to `GP-200 Edit` and foreground the main window.
- [x] 1.4 Add logging for editor process state, window identity, detected view, and workflow step outcomes.

## 2. Editor Session Control

- [x] 2.1 Implement editor startup and attach behavior for both not-running and already-running states.
- [x] 2.3 Implement known-view detection for patch editing and a safe recovery path from unsupported views.
- [x] 2.4 Implement target patch context confirmation before any patch mutation.
- [x] 2.5 Implement unsaved-change detection or a conservative manual confirmation gate when readback is unavailable.

## 3. Patch Mutation Primitives

- [x] 3.1 Implement module selection primitives for the core tone modules `PRE`, `DST`, `AMP`, `NR`, `CAB`, `EQ`, `MOD`, `DLY`, `RVB`, and `VOL`.
- [x] 3.2 Implement model selection primitives for modules that expose model choices.
- [x] 3.3 Implement parameter write primitives with range validation and per-step verification where possible.
- [x] 3.4 Implement ordered recipe execution with fail-closed behavior when an expected control or value cannot be confirmed.
- [x] 3.5 Implement patch save behavior and capture the result as a traceable operation record.

## 4. Expert Tone Authoring

- [x] 4.1 Define the normalized tone brief schema with target style, routing context, intended use, constraints, and save policy.
- [x] 4.2 Implement routing-context normalization for `FRFR`, `headphones`, `interface`, `amp front`, `amp return`, and `4CM`.
- [x] 4.3 Implement structured GP-200 patch recipe generation from a normalized tone brief.
- [x] 4.4 Encode routing-aware `AMP`, `CAB`, and `No CAB` defaults from the manual-derived operator index.
- [x] 4.5 Encode first-pass expert templates for clean, edge-of-breakup, modern high-gain, and ambient or cinematic tones.
- [x] 4.6 Add unsupported-request detection for tone briefs that require behavior outside the supported modules or routing contexts.

## 5. Persistence And Refinement

- [x] 5.1 Persist a readable tone summary containing patch name, target location, routing context, modules, model choices, and parameter values.
- [x] 5.2 Persist a machine-readable recipe trace that can be replayed or inspected after failure.
- [x] 5.3 Implement refinement input handling for feedback such as too bright, too muddy, too noisy, too dry, or too compressed.
- [x] 5.4 Implement revised recipe generation that preserves the prior recipe and records targeted adjustments.
- [x] 5.5 Implement save-policy handling for updating the existing patch versus creating a named variant.

## 6. Validation

- [x] 6.1 Add dry-run validation that checks tone briefs and recipes without controlling the editor.
- [x] 6.2 Add control-layer smoke tests for launch, attach, readiness, and known-view detection.
- [x] 6.3 Add recipe tests for each supported routing context and first-pass tone template.
- [x] 6.4 Run an end-to-end manual validation on at least one safe target patch and record the resulting tone trace.
- [x] 6.5 Update the GP-200 operator documentation with the supported automation workflow, known limitations, and recovery steps.

## 7. Desired-State Rendering

- [x] 7.1 Define a desired-state JSON schema for complete GP-200 tone targets.
- [x] 7.2 Document how to find available algorithms, parameters, ranges, and menu IDs from `algorithm.xml`.
- [x] 7.3 Add a desired-state example for the generated strings patch under `tones/`.
- [x] 7.4 Implement desired-state JSON loading and validation before binary rendering.
- [x] 7.5 Implement desired-state to checksum-valid `.prst` rendering with trace and optional summary output.
- [x] 7.6 Validate JSON-to-`.prst` rendering with the strings desired-state fixture.

## 8. Repository Skill And Current Documentation

- [x] 8.1 Create the repository-local `gp200-tone-crafter` Codex skill.
- [x] 8.2 Document the `tones/` output convention in the skill and GP-200 script docs.
- [x] 8.3 Add desired-state schema and desired-state usage documentation to the skill references.
- [x] 8.4 Update the operator index and script README away from stale root `.prst` and old `output/` examples.
- [x] 8.5 Validate the skill metadata and `apply-state` rendering path after documentation updates.
- [x] 8.6 Add a required producer/tone-designer role prompt for use whenever `gp200-tone-crafter` is active.
