# Before Your Name - Revisions

- 2026-04-18: Created initial song brief, lyric draft, arrangement notes, vocal-demo plan, and MIDI sketch plan from `docs/story-arc.md`.
- 2026-04-18: Added full song draft, chord map, ElevenLabs-ready vocal text, and provider generation script.
- 2026-04-18: Generated ElevenLabs voice guide using `George - Warm, Captivating Storyteller` and saved it to `before-your-name-voice.mp3`.
- 2026-04-18: Added vocal melody guide, updated MIDI sketch with guide vocal and chord tracks, and added Eleven Music composition plan for sung demo generation.
- 2026-04-18: Attempted Eleven Music sung demo generation. API returned `402 paid_plan_required`, so no sung MP3 was created. Preserved `eleven-music-plan.json`, `melody.md`, and the regenerated MIDI guide for later generation.
- 2026-04-18: Retried Eleven Music generation after user upgraded. API still returned `402 paid_plan_required` for the key in `.env`; likely the local key is still tied to a free project or account.
- 2026-04-18: Retried Eleven Music generation successfully and saved sung demo to `before-your-name-eleven-music.mp3`.
- 2026-04-18: Updated song-production skill to prefer vocal-only stems for DAW import and added `eleven-music-vocal-only-plan.json` for Cakewalk/Sonar workflow.
- 2026-04-18: Generated vocal-only Eleven Music stem and saved it to `before-your-name-vocal-only.mp3`.
- 2026-04-18: Updated skill to forbid generated guitar backing parts and generated no-guitar MIDI backing files for bass, drums, piano, pad, celeste, and combined backing.
- 2026-04-18: Extended no-guitar backing MIDI generator to cover the full song form instead of the short sketch length.
- 2026-04-18: Rewrote backing MIDI event scheduling to use absolute tick positions so every part shares one 100 BPM tempo grid and the same song-length timeline.
- 2026-04-18: Corrected backing form to match the vocal stem instead of repeating sections past the vocal ending.
- 2026-04-18: Added skill rule requiring all generated MIDI and voice files to be full-song tracks by default, with partial outputs allowed only when explicitly labeled as sketches, excerpts, or loops.
- 2026-04-18: Regenerated full-song package with vocal-only plan updated to include intro alignment before the first vocal entrance.
- 2026-04-18: Updated song-production skill with Cakewalk/Sonar import bundle workflow and native `.cwp` limitation guidance.
- 2026-05-02: Added backing-track overlay workflow artifacts: source analysis, candidate region map, lyric-fit plan, deferred provider manifest, and an overlay stem package for `before your name, Track 13, Rec (120).wav`.
