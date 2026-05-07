# ElevenLabs Vocal Demo Guardrails

ElevenLabs vocal demos are optional. Core song work must still succeed without ElevenLabs.

Default to vocal-only outputs for DAW workflows. A Cakewalk/Sonar user usually needs the generated voice as an isolated audio stem, not a mixed full song. Only generate full accompaniment when the user explicitly asks for a complete generated backing track.

Full-track rule: generated voice files must cover the complete current song form from first vocal entrance through final tag/release. Do not generate partial vocal clips unless the user explicitly asks for a short preview, excerpt, or loop, and label the file accordingly.

For backing-track overlays:

- Do not call a provider until `overlay-region-map.json` exists and the selected region has usable timing confidence.
- Treat generated output as an overlay-ready dry stem plus placement metadata unless the provider or tooling can prove sample-accurate alignment.
- Save overlay-ready stems as `<song-slug>-overlay-vocal-only.mp3`.
- Save provider request metadata as `overlay-vocal-request.json` and user-facing status notes as `overlay-vocal-demo.md`.

Before any provider call:

- Confirm the user wants a live ElevenLabs call.
- Confirm network access is approved in the current environment.
- Confirm credentials are available through a secure environment variable or secret store.
- Confirm the source audio is authorized for this use and record its provenance.
- Confirm the selected voice is authorized for this use.
- Do not hard-code API keys, voice IDs, or private credentials in the repository.

Always create `vocal-demo.md` first with:

- Provider
- Intended singer role
- Voice authorization status
- Source lyric path
- Delivery notes
- Pending prerequisites or output path

For overlay requests, also record:

- Source audio path
- Selected region ID and timestamps
- Timing-confidence summary
- Expected alignment notes or DAW offset
- Whether provider execution is blocked or deferred

For vocal-only Eleven Music plans:

- Use styles such as `a cappella male vocal`, `solo lead vocal only`, and `dry vocal stem`.
- Use negative styles such as `guitar`, `piano`, `drums`, `bass`, `strings`, `synth`, `backing track`, `instrumental accompaniment`, and `reverb-heavy mix`.
- Save output as `<song-slug>-vocal-only.mp3`.
- Confirm the generated vocal-only file is intended to align with the full-song MIDI arrangement before reporting it as complete.

For text-to-speech or singing generation against an existing backing track:

- Pass the selected region metadata into the generation command or sidecar metadata file.
- If the tool cannot embed or render silence/offset into the stem deterministically, write the lead-in or placement offset into `overlay-integration-notes.md`.
- If timing confidence is below the configured threshold, do not call ElevenLabs. Preserve the lyric-fit and request metadata as a deferral.

If prerequisites are missing, do not call ElevenLabs. Report what is missing and leave the song artifacts usable.
