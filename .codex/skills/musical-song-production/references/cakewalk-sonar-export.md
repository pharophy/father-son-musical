# Cakewalk/Sonar Export

Native Cakewalk/Sonar `.cwp` project files are proprietary. Do not claim to generate a complete `.cwp` unless the user provides a working template project or a documented automation surface that can be safely driven.

Default export is a Cakewalk-ready bundle:

```text
music/<song-slug>/cakewalk-sonar-project/
```

The bundle must include:

- `Audio/<song-slug>-vocal-only.mp3`
- `MIDI/<song-slug>-bass.mid`
- `MIDI/<song-slug>-drums.mid`
- `MIDI/<song-slug>-piano.mid`
- `MIDI/<song-slug>-pad.mid`
- optional `MIDI/<song-slug>-celeste.mid`
- `project-manifest.json`
- `IMPORT_INSTRUCTIONS.md`

Recommended Cakewalk setup:

- Project tempo: `100 BPM`
- Meter: `4/4`
- Vocal-only audio: import to an audio track starting at bar 1, beat 1.
- Bass MIDI: route to SI-Bass Guitar, TTS-1 bass, or another bass synth.
- Drums MIDI: route to SI-Drum Kit, Session Drummer, TTS-1 drums, or another drum synth. Use MIDI channel 10 when required by the synth.
- Piano MIDI: route to SI-Electric Piano, TTS-1 piano, or a piano VST.
- Pad MIDI: route to TTS-1 pad/string patch or a soft pad synth.
- Celeste MIDI: route to TTS-1 celesta/glockenspiel-style patch or any bell-like synth.

If the user wants true one-click `.cwp` project creation, ask them to create and provide a Cakewalk template project with the desired synth rack and routing. Then future automation can target that template as a source artifact instead of reverse-engineering `.cwp`.
