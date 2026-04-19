# GP-200 Operator Index

Source manual: `docs/gp-200 manual.md`

Purpose: condensed operating reference for building tones in `GP-200 Edit` and on the hardware without rereading the full manual.

## Confirmed Environment

- `GP-200.exe` is installed at `C:\Program Files\Valeton\GP-200\GP-200.exe`.
- The editor is currently running and reports `V1.8.0`.
- The manual text in this folder matches the firmware generation and states that the desktop software can adjust tones, import/export patches, upgrade firmware, and load third-party IRs.

## Software Capabilities

Manual basis: lines 1269-1279.

- `GP-200 Edit` on Windows/Mac can:
- Adjust tones
- Import/export patches
- Upgrade firmware
- Load third-party IRs
- It requires `Global Settings > USB Audio > USB Mode = Normal` for computer connection.
- `Legacy` USB mode is 2x USB audio without MIDI and breaks the software connection.
- `Normal` USB mode is 6-in/4-out USB audio with MIDI and is the correct mode for editor use.

## Core Patch Architecture

Manual basis: lines 518-526, 537-560, 579-633.

- A patch contains 11 movable modules.
- Default chain:
- `PRE -> WAH -> DST -> AMP -> NR -> CAB -> EQ -> MOD -> DLY -> RVB -> VOL`
- Any module can be moved in the signal chain.
- Dark icon means module off; bright icon means module on.
- Saving is mandatory. Unsaved edits are lost on patch change or power-off.
- The `*` beside the patch name means the patch has changed and is not saved yet.

## Patch Editing Workflow

Manual basis: lines 510-576 and 635-642.

1. Enter `Edit Menu`.
2. Select a module.
3. Choose an effect model inside that module.
4. Use quick-access knobs or editor parameters to change values.
5. Hold `PARA` in module view to manage signal-chain position.
6. Save the patch explicitly.

Practical production rule:

- Build tone in this order: `AMP/CAB -> gain staging -> gate -> EQ -> modulation -> delay/reverb -> controller assignments -> save`.

## Patch Settings That Matter For Tone Design

Manual basis: lines 579-633.

- `Patch VOL`, `Patch PAN`, and `BPM` are per-patch.
- `Knob 1-3` can be assigned to selected patch parameters.
- `EXP Settings`:
- `EXP 1A`, `EXP 1B`, and `EXP 2` can each control up to 3 parameters with independent min/max values.
- `CTRL Settings`:
- 8 patch-level control assignments are available.
- A single CTRL can toggle one or multiple modules.
- `FX Loop`:
- Send and return positions are movable.
- Return cannot be placed before send.
- `Parallel` mixes returned external effects back into the chain.
- `Series` pauses the internal chain at the loop and passes only the external return onward.
- If `Series` is selected with nothing connected in the loop, output is silent.

## Input, Output, And Gain Staging

Manual basis: lines 693-720.

- `Input Mode` options:
- `Acoustic Guitar`: `4.7MΩ`
- `Electric Guitar`: `1MΩ`
- `Line In`: `10kΩ`
- `Input Level` range: `-20 dB` to `+20 dB`
- `No CAB Mode (L/R)` disables cabinet simulation only on the selected analog output channel.

Use this to prevent double speaker simulation when feeding a guitar amp instead of FRFR monitors.

## USB Audio And Re-Amping

Manual basis: lines 723-785.

- `Rec Level` controls USB record output level.
- `Rec Mode L/R` can be `Dry` or `Wet`.
- This enables `monitor wet / record dry`.
- `AUX To USB` mixes AUX input into the USB stream for livestreaming or backing tracks.
- `Monitor Level` controls USB playback level.
- In `Normal` USB mode, GP-200 acts as a `6-in / 4-out` interface.

Re-amp workflow from the manual:

1. Set `USB Audio > Rec Mode L/R` to `Dry`.
2. Record/import dry guitar to DAW Track A.
3. Set Track A output to `Output 3-4`.
4. Set Track B input to `Input 3-4`.
5. Monitor the processed signal through GP-200.
6. Record the re-amped result on Track B.

## Footswitch And Expression Control

Manual basis: lines 788-992.

- Bank select modes:
- `Initial`: bank changes switch immediately.
- `Wait`: bank changes arm first, then require explicit patch selection.
- Footswitch modes:
- `Patch`
- `Stomp`
- `User`
- Each switch supports separate `Tap` and `Hold` assignments.
- External control through `EXP 2 / Footswitch` can be configured for:
- External expression pedal
- Single footswitch
- Dual footswitch

Useful assign targets from the manual:

- `Patch +/-`
- `Bank +/-`
- `A/B/C/D`
- `LOOPER`
- `DRUM`
- `EXP 1 A/B`
- `MIDI`
- `TUNER`
- `CTRL 1-8`
- `Tap Tempo`

Expression calibration:

- Calibrate heel, toe, then toe-switch press.
- `EXP 1` curve options: `Line`, `Expo`, `Log`.

## MIDI And External Control

Manual basis: lines 457-488 and 994-1067.

- GP-200 can enter a dedicated MIDI control interface.
- Each footswitch can carry up to 3 groups of MIDI information.
- MIDI message types supported in that interface: `CC` and `PC`.
- MIDI input source can be `DIN Only`, `USB Only`, or `Mixed`.
- Separate input/output channels exist for DIN and USB.
- Clock source can be internal, DIN, USB, external, or mixed.
- If clock source is external-only, internal tap tempo does not run.

High-value MIDI mappings called out later in the manual begin at lines 4892+ and include:

- Patch volume
- `EXP 1`
- `EXP 1 A/B`
- Individual module on/off for `PRE`, `DST`, `AMP`, `NR`, `CAB`, `EQ`, `MOD`, `DLY`, `RVB`, `WAH`

## Display, Auto CAB Match, And Global EQ

Manual basis: lines 1068-1193.

- Display modes:
- `Footswitch`
- `Patch`
- `Signal chain`
- `Auto CAB Match`:
- When on, changing the amp model also changes the cabinet model accordingly.
- Good starting point for quick auditioning.
- Turn it off when you want deliberate amp/cab mismatches.
- `Global EQ`:
- Low cut
- High cut
- 4 fully parametric bands
- Affects overall hardware output voicing
- Does **not** affect USB audio output

Production rule:

- Use `Global EQ` for room, speaker, or monitoring correction.
- Use patch EQ for the actual tone design.

## Recommended Routing By Output Scenario

Manual basis: lines 1286-1382.

### FRFR, monitors, PA, headphones

- Keep `AMP` on.
- Keep `CAB` on.
- Keep `No CAB` off.

### Guitar amp front input

- Connect GP-200 output to amp input.
- Turn `AMP` off.
- Turn `CAB` off.

### Guitar amp FX return / power amp in

- Connect GP-200 output to amp return.
- Use `AMP` on if you want GP-200 amp models.
- Turn `CAB` off or enable `No CAB`.

### Guitar amp effects loop post-preamp

- Modules before `AMP` are muted in this setup.
- Effects after `AMP` sit between the amp preamp and power amp.
- Default return node is after `AMP`.
- Turn `CAB` off or enable `No CAB`.
- Watch clipping and lower `Input Level` or use `Line` mode if needed.

### 4 cable method

- Put `PRE` and `DST` before the amp preamp.
- Put `EQ`, `MOD`, `DLY`, and `RVB` in the loop.
- Keep `AMP` off.
- Keep `CAB` off.
- Set patch `FX Loop` to `Series`.

## IR And NAM Support

Manual basis: lines 1271-1273, 3557, 3774-3776, 4760-4762.

- User IR support:
- `User IR 1-20`
- Expected format: `WAV`, `44 kHz`, `1024 sample`
- SnapTone / NAM support:
- The software can load `.nam` timbre files.
- `.nam` loading is available in both `AMP` and `DST` modules.

This is the most important modern extension point for producer-grade tone matching on the GP-200.

## Practical Tone-Building Strategy

Use these heuristics when creating tones in the editor:

### Clean

- Low-to-mid gain amp
- Cab on unless feeding guitar amp
- Moderate compression in `PRE`
- Light noise gate
- High cut to remove hash
- Delay/reverb after amp

### Edge-of-breakup

- Use `PRE` boost before amp instead of stacking too much gain in the amp block
- Keep patch volume matched to bypass
- Use `Auto CAB Match` on for first pass, off for refinement

### Modern high gain

- Tighten lows before amp with a boost or EQ
- Put gate after amp if hiss is excessive, but avoid over-gating sustain
- Use cab low cut / high cut aggressively
- Avoid excess bass in the amp block; let cab and post EQ shape weight

### Ambient / cinematic

- Put modulation before or after delay depending on smear vs clarity
- Use stereo delay/reverb in FRFR or interface contexts
- Keep patch BPM correct so time-based effects sync cleanly

## Fast Operating References

- Main edit architecture: lines 508-576
- Per-patch settings and FX loop: lines 577-633
- Global I/O and USB audio: lines 693-785
- Footswitch and EXP setup: lines 786-992
- MIDI setup: lines 994-1067
- Display, cab matching, global EQ: lines 1068-1193
- Desktop software requirements: lines 1269-1279
- Real-world routing scenarios: lines 1286-1382
- User IR support: lines 3774-3776
- NAM / SnapTone support: lines 4760-4762

## Working Assumption For Future Tone Requests

When asked to make a tone, default to this decision tree:

1. Ask what the output target is: `FRFR`, `headphones`, `interface`, `amp front`, `amp return`, or `4CM`.
2. Set `AMP/CAB` and `No CAB` according to the routing rules above.
3. Pick the amp family first.
4. Match a cabinet or IR.
5. Set gain staging and noise control.
6. Shape with EQ.
7. Add space and modulation.
8. Assign footswitch/EXP controls if the tone needs performance interaction.
9. Save to a named patch.

## Local Automation Workflow

Automation harness: `scripts/gp200/README.md`

The local harness can launch or attach to `GP-200 Edit`, foreground the editor, validate patch identifiers such as `42-A`, generate structured expert-tone recipes, and write trace files under the configured output directory. Current user-facing tone artifacts live under `tones/`.

Safe patch takeover command:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\gp200\gp200-control.ps1 -Command takeover -Patch 42-A -Style edge-of-breakup -Routing headphones
```

Current limitation:

- `GP-200 Edit` exposes very little readable UI Automation text, so the patch grid and parameter controls should be treated as custom-rendered.
- The harness intentionally skips parameter mutation unless target patch readback and parameter control selectors are verified.
- Patch `42-A` has been foregrounded and traced, but parameter writing remains blocked by the safety gate.

## Current Preferred Tone Workflow

Use desired-state JSON plus `.prst` rendering for new tones:

1. Create `tones/<PATCH NAME>.desired-state.json`.
2. Render with `scripts/gp200/gp200-prst.ps1 -Command apply-state`.
3. Import the generated `tones/<PATCH NAME>.prst` into a safe GP-200 slot first.
4. Refine the desired-state JSON from listening feedback and render again.
