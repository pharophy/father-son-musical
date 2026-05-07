# Cakewalk/Sonar Import - before-your-name

## Project Setup

1. Create a new empty Cakewalk/Sonar project.
2. Set tempo to `100 BPM`.
3. Set meter to `4/4`.
4. Import `Audio/before-your-name-vocal-only.mp3` to an audio track at bar 1 beat 1.
5. Import the MIDI files from `MIDI/` as separate MIDI tracks.
6. Assign each MIDI track to the recommended soft synth listed below.

## Track Routing

- Lead Vocal: `Audio/before-your-name-vocal-only.mp3` -> Audio track. Import at bar 1 beat 1. Keep this isolated for mixing.
- Bass: `MIDI/before-your-name-bass.mid` -> SI-Bass Guitar or TTS-1 bass. No guitar backing; bass is permitted.
- Drums: `MIDI/before-your-name-drums.mid` -> SI-Drum Kit, Session Drummer, or TTS-1 drums. Use MIDI channel 10 if your drum synth expects General MIDI drums.
- Piano: `MIDI/before-your-name-piano.mid` -> SI-Electric Piano, TTS-1 piano, or piano VST. Sparse chord bed.
- Pad: `MIDI/before-your-name-pad.mid` -> TTS-1 pad/string patch or pad synth. Warm support pad.
- Celeste: `MIDI/before-your-name-celeste.mid` -> TTS-1 celesta/glockenspiel-style patch. Optional nursery-light color.

## Native Project File Limitation

This bundle does not include a native `.cwp` file. Cakewalk/Sonar project files are proprietary.
For one-click native project creation, create a Cakewalk template with your preferred synth rack and provide it as a source template for future automation.
