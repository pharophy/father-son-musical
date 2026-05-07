## 1. Skill Structure

- [x] 1.1 Create the repository-local song production skill folder under `.codex/skills/`.
- [x] 1.2 Add skill metadata that triggers on lyric writing, song drafting, song revisions, musical parts, MIDI generation, and ElevenLabs vocal-demo requests.
- [x] 1.3 Add `agents/openai.yaml` metadata for the skill.

## 2. Role Prompt and References

- [x] 2.1 Add a required musical-theatre songwriter, arranger, and demo-producer role prompt.
- [x] 2.2 Add a songwriting workflow reference for deriving song briefs from `docs/story-arc.md`.
- [x] 2.3 Add a lyric-writing reference covering dramatic function, character voice, song form, reprises, and lyrical revision.
- [x] 2.4 Add a two-voice/two-guitar arrangement reference for father and son parts across the lifecycle arc.
- [x] 2.5 Add a MIDI generation reference defining track conventions, file naming, and deterministic sketch limits.
- [x] 2.6 Add an ElevenLabs vocal-demo reference covering prerequisites, metadata, credential handling, rights guardrails, and fail-closed behavior.

## 3. Song Artifact Model

- [x] 3.1 Define the `music/<song-slug>/` folder convention.
- [x] 3.2 Define stable filenames for song brief, lyrics, arrangement notes, MIDI files, vocal-demo metadata, and revision notes.
- [x] 3.3 Ensure the skill reads `docs/story-arc.md` before creating or revising any song artifact.
- [x] 3.4 Document how the skill handles requested songs that are missing from `docs/story-arc.md`.

## 4. MIDI and Vocal Demo Support

- [x] 4.1 Implement or document a deterministic MIDI sketch generation path for basic song parts.
- [x] 4.2 Validate MIDI generation with at least one song part or document why generation is deferred.
- [x] 4.3 Implement or document the ElevenLabs vocal-demo request path without hard-coding credentials.
- [x] 4.4 Ensure ElevenLabs calls are optional and require user approval, credentials, voice authorization, and network access.

## 5. Validation

- [x] 5.1 Validate the skill folder metadata with the skill validation script.
- [x] 5.2 Run a sample use of the skill against one song from `docs/story-arc.md`.
- [x] 5.3 Verify the sample song artifact includes a brief, lyric draft, arrangement notes, and either MIDI output or a documented MIDI deferral.
- [x] 5.4 Verify rights and provider guardrails are documented and discoverable from the skill.
