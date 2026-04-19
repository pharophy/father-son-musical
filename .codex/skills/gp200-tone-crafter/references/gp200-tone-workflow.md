# GP-200 Tone Workflow Reference

## Preset Format Essentials

- File extension: `.prst`
- Magic: `TSRP`
- Expected size for single GP-200 patches: `1224` bytes
- Patch name offset: `0x44`
- Patch name length: `16` ASCII bytes
- Algorithm code slot base: `0xA8`
- Slot size: `72` bytes
- Module order: `PRE`, `WAH`, `DST`, `AMP`, `NR`, `CAB`, `EQ`, `MOD`, `DLY`, `RVB`, `VOL`
- Module active flag: eight bytes before each algorithm-code slot, offset `+5` in that header
- Checksum: `sum(bytes[0x0000..0x04C5]) & 0xFFFF`, stored big-endian at `0x04C6`

Use `C:\Program Files\Valeton\GP-200\Resource\GP-200\File\algorithm.xml` for valid module algorithm names, codes, defaults, and parameter names.

## Output Convention

Save all generated user-facing tones to the repository `tones/` folder:

```text
tones/<PATCH NAME>.prst
tones/<PATCH NAME>.trace.json
tones/<PATCH NAME>.summary.md
```

Keep source exports in place and keep experimental or older artifacts out of `tones/` unless they are meant for import.

## Tone Planning Heuristics

- Full-range routes (`headphones`, `interface`, `FRFR`) usually keep `AMP` and `CAB` active.
- `amp front` usually disables `AMP` and `CAB`.
- `amp return` may keep `AMP` active but should avoid double cabinet simulation.
- `4CM` usually disables internal `AMP` and `CAB`, keeping drive before the amp and time effects in the loop.
- Clean/edge tones prioritize compression or boost, clean amp, cab filtering, modest delay/reverb, and level matching.
- High-gain tones prioritize low-end tightening before the amp, noise control, focused post-EQ, and controlled ambience.
- Ambient/instrument-like tones prioritize pitch, swell, detune/chorus, delay, shimmer/hall reverb, and softer high-end EQ.

## Useful Models

- Bowed/string-like pad: `PRE::Pitch`, `NR::Auto Swell`, `AMP::Silver Twin`, `CAB::DARK LUX`, `MOD::Detune`, `DLY::Tape Delay S`, `RVB::Shimmer`
- Edge-of-breakup: `PRE::Micro Boost`, `DST::Green OD`, `AMP::Tweedy`, `CAB::SUP ZEP`, `DLY::BBD Delay S`, `RVB::Room`
- Clean wide ambience: clean `AMP`, filtered `CAB`, `MOD::G-Chorus` or `MOD::Detune`, stereo-compatible delay, `RVB::Hall` or `RVB::Shimmer`

## Import Safety

Always tell the user to import new presets into an unused/safe patch slot first. If import fails, test an exact copy of the source export and a checksum-only/name-only variant to separate file-path issues, checksum issues, and invalid parameter/model content.
