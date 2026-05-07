## 1. Skill and Artifact Model

- [x] 1.1 Update the `musical-song-production` skill metadata so overlay requests against an existing backing track trigger the skill.
- [x] 1.2 Add or revise reference docs for source-audio analysis, vocal-entry mapping, lyric fitting, and overlay artifact naming.
- [x] 1.3 Define stable filenames and folder conventions for source briefs, region maps, lyric-fit notes, vocal metadata, aligned vocal outputs, and integration notes.

## 2. Audio Analysis Workflow

- [x] 2.1 Implement a source-audio analysis path that records provenance, duration, and candidate timing or section metadata for an existing song.
- [x] 2.2 Implement candidate vocal-region output with timestamps, phrase-length notes, and confidence indicators.
- [x] 2.3 Add fail-closed behavior for low-confidence analysis so the workflow preserves findings without claiming final alignment.

## 3. Lyric Fit and Vocal Generation

- [x] 3.1 Implement a lyric-planning step that writes or revises lyrics against a selected vocal-entry region and its phrasing constraints.
- [x] 3.2 Extend vocal-generation metadata and scripts so a lyric version can be tied to a source-song region and exported as a vocal-only output.
- [x] 3.3 Enforce provider, credential, network, provenance, and voice-authorization guardrails for overlay generation requests.

## 4. Integration Outputs

- [x] 4.1 Write integration notes that connect the generated vocal stem to the source-song timestamps, files, and mix guidance.
- [x] 4.2 Ensure the workflow emits a reusable stem package when a deterministic merged-song export is not available.
- [x] 4.3 Update existing per-song revision handling so overlay artifacts can be revised without losing prior analysis context.

## 5. Validation

- [x] 5.1 Validate the updated skill metadata and references with the repository’s skill validation approach.
- [x] 5.2 Run the workflow on at least one existing audio asset under `music/` and verify the output includes analysis, lyric fit, and either an aligned vocal stem or a documented generation deferral.
- [x] 5.3 Verify the rights, provenance, and provider guardrails are documented and enforced for backing-track overlay requests.
