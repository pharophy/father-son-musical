## Context

The repository already supports local Codex skills for repeatable creative and technical workflows. This change introduces a story-development skill for a specific musical concept: a father and son relationship traced from before birth through the son's departure for college and adult independence. The musical's defining language is a dialogue between two guitars or voices, where the father's part begins mature and capable while the son's part enters later, starts simply, and grows until it can exceed the father's facility.

The skill must help generate and revise story material without flattening the concept into generic family-drama advice. It should preserve continuity across revisions, treat musical structure as story structure, and keep the two-voice/two-guitar motif central to scene and song decisions.

## Goals / Non-Goals

**Goals:**
- Create a repository-local skill for developing, modifying, and maintaining the father/son musical storyline.
- Include a required role/system prompt for musical-theatre story work with specific father/son and two-guitar/voice flavor.
- Provide reference material for story arc, character progression, musical motif progression, artifact formats, and revision rules.
- Establish a durable output convention for story artifacts such as outlines, scene beats, song maps, motif maps, and revisions.
- Validate the skill with at least one example generation or revision task.

**Non-Goals:**
- Do not write the full musical as part of this proposal.
- Do not generate final lyrics, full book scenes, or complete score notation unless requested during implementation or later use.
- Do not require external musical-theatre research or copyrighted style imitation.
- Do not implement audio rendering, MIDI generation, notation export, or GP-200 tone generation in this change.

## Decisions

### Create a dedicated skill instead of expanding the GP-200 tone skill

The skill will live separately from `gp200-tone-crafter` because story dramaturgy and guitar-tone generation have different triggers, workflows, and reference material. Keeping them separate avoids bloating the tone skill and allows this skill to trigger on musical storyline, book, dramaturgy, scene, and song-map requests.

Alternative considered: extend `gp200-tone-crafter` to include musical story work. This was rejected because it would mix production-tone tasks with narrative-development tasks and make both skills less precise.

### Use references for role prompt and storycraft rules

`SKILL.md` should stay concise and point to reference files for deeper material. The role/system prompt, story bible, two-voice/two-guitar motif language, and artifact templates should live in `references/` so agents load only what is needed for the task.

Alternative considered: put all instructions directly in `SKILL.md`. This was rejected because the concept benefits from richer dramaturgical detail, and a large skill body would waste context on every use.

### Store generated work in `docs/story-arc.md`

The implementation should use `docs/story-arc.md` as the canonical mutable story artifact. The file should contain or link the story bible, act outline, scene list, song map, motif map, and revision notes needed to keep the musical coherent across sessions.

Alternative considered: store outputs beside the skill or in a dedicated `musical/` folder. This was rejected because the user requested `docs/story-arc.md`, and documentation is the right repository-local place for a human-readable canonical story arc.

### Treat the two-voice/two-guitar device as a structural requirement

The skill should require each major story stage to consider how Voice/Guitar 1 and Voice/Guitar 2 relate musically and dramatically. The son's voice/guitar should not appear fully formed; it should enter after birth, begin with limited capability, develop through imitation and resistance, and eventually surpass or transcend the father's line.

Alternative considered: make the device optional flavor. This was rejected because the device is the user's central concept.

## Risks / Trade-offs

- Generic musical advice could dilute the concept -> Mitigate with a required role prompt and motif-specific reference rules.
- The father/son arc could become sentimental or predictable -> Mitigate with dramaturgical checks for conflict, agency, reversals, subtext, and earned emotional turns.
- Iterative revisions could contradict prior story decisions -> Mitigate with a persistent `docs/story-arc.md` story bible and revision notes section.
- The son's musical growth could become too literal or mechanical -> Mitigate by allowing the two voices/guitars to represent emotional maturity, independence, imitation, conflict, reconciliation, and silence, not only technical skill.
- Scope could expand into full book, lyrics, and score generation -> Mitigate by separating story, song-map, lyric, and notation tasks and requiring explicit user request for full drafts.
