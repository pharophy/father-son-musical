## 1. Skill Structure

- [x] 1.1 Create the repository-local musical storycraft skill folder under `.codex/skills/`.
- [x] 1.2 Add skill metadata that triggers on father/son musical storyline, scene, song-map, motif-map, and continuity revision requests.
- [x] 1.3 Add `agents/openai.yaml` metadata for the skill.

## 2. Role Prompt and References

- [x] 2.1 Add a required producer/book-writer/dramaturg role prompt reference for this musical concept.
- [x] 2.2 Add a storycraft workflow reference covering musical-theatre best practices, character wants, obstacles, turning points, song function, reprises, and emotional payoff.
- [x] 2.3 Add a two-voice/two-guitar motif reference defining Voice/Guitar 1 as the father and Voice/Guitar 2 as the son.
- [x] 2.4 Add a `docs/story-arc.md` format reference that defines required sections and update rules.

## 3. Story Arc Artifact

- [x] 3.1 Create `docs/story-arc.md` if it does not already exist.
- [x] 3.2 Seed `docs/story-arc.md` with the core father/son premise, lifecycle arc, and two-voice/two-guitar progression.
- [x] 3.3 Include sections for premise, character arcs, lifecycle structure, motif progression, act outline, scene or song map, and revision notes.
- [x] 3.4 Ensure the skill instructs agents to read `docs/story-arc.md` before modifying existing story material.

## 4. Revision Workflow

- [x] 4.1 Document how the skill applies continuity-preserving changes to `docs/story-arc.md`.
- [x] 4.2 Document how the skill identifies conflicts with the lifecycle arc or two-voice/two-guitar progression.
- [x] 4.3 Document how the skill records revision notes after modifying `docs/story-arc.md`.

## 5. Validation

- [x] 5.1 Validate the skill folder metadata with the skill validation script.
- [x] 5.2 Run a sample use of the skill to create or revise `docs/story-arc.md`.
- [x] 5.3 Verify the resulting `docs/story-arc.md` includes the required sections and preserves the father/son two-voice/two-guitar concept.
