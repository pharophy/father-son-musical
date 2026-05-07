## Why

The project needs a dedicated creative-writing skill for developing and revising a musical storyline about a father and son, with a recurring two-voice or two-guitar dramatic device that evolves across the child's life. Capturing this as a skill will make future story work consistent, musically grounded, and specific to this concept instead of generic musical-theatre assistance.

## What Changes

- Add a repository-local Codex skill for creating, extending, and modifying the musical's storyline, scenes, song moments, character arcs, and recurring father/son musical motifs.
- Add a role/system prompt that makes the agent operate as a musical-theatre book writer, dramaturg, lyric-development partner, and producer for this specific father/son concept.
- Define story guardrails from before the child is born through the son's departure for college and independent adulthood.
- Define the two-voice or two-guitar language: Voice/Guitar 1 represents the father with mature lead ability from the beginning, while Voice/Guitar 2 enters later with basic ability and matures until it can surpass Voice/Guitar 1.
- Support iterative modifications while preserving continuity, emotional arc, musical motif logic, and the canonical `docs/story-arc.md` story artifact.
- No breaking changes.

## Capabilities

### New Capabilities
- `father-son-musical-storycraft`: Covers the skill, role prompt, storyline artifact model, two-voice/two-guitar motif progression, and revision workflow for the father/son musical.

### Modified Capabilities
- None.

## Impact

- Adds a new skill under `.codex/skills/` for musical storyline creation and modification.
- Adds skill references for the required role/system prompt, story bible, two-voice/two-guitar motif rules, and `docs/story-arc.md` artifact format.
- Adds a repository output convention requiring generated and revised story-arc material to be written to `docs/story-arc.md`.
- Adds validation tasks for skill metadata, role-prompt coverage, and example storyline generation or revision.
