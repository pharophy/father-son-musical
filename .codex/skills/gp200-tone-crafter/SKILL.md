---
name: gp200-tone-crafter
description: Create importable Valeton GP-200 preset tones from user sound descriptions. Use when the user asks Codex to make, craft, generate, refine, or export a GP-200 patch or .prst file that sounds like a described amp, artist, genre, effect, instrument, mood, or texture, including requests like "make a strings patch", "create a Hendrix tone", "make this less bright", or "generate another GP-200 preset".
---

# GP-200 Tone Crafter

Use this skill to create checksum-valid GP-200 `.prst` files on demand from tone requests.

## Workflow

1. Read and follow [references/producer-role.md](references/producer-role.md) as the active role/system prompt for all tone-creation decisions.
2. Identify the requested sound, routing context, and save name.
3. If routing is missing, infer `headphones/interface/FRFR` unless the user mentions an amp front, amp return, or 4CM rig.
4. Read [references/gp200-tone-workflow.md](references/gp200-tone-workflow.md) before editing preset-generation logic.
5. For structured or repeatable requests, create desired-state JSON using [references/desired-state-format.md](references/desired-state-format.md).
6. Use `tones/42-A It's GP-200.example.prst` as the source export unless the user provides another `.prst`.
7. Save generated outputs under `tones/` by default:
   - `tones/<PATCH NAME>.prst`
   - `tones/<PATCH NAME>.trace.json`
   - optionally `tones/<PATCH NAME>.summary.md`
8. Use ASCII patch names no longer than 16 bytes.
9. Recalculate the GP-200 checksum before writing any modified `.prst`.
10. Inspect the generated file and validate that stored checksum equals computed checksum.
11. Report the final `.prst` path and key modules/settings. Tell the user to import into a safe slot first.

## Implementation Notes

- Prefer extending or invoking `scripts/gp200/gp200-prst.ps1` instead of rewriting binary patch logic.
- If the current request matches an existing command, run it with `-OutPath ".\tones\<name>.prst"`.
- If the user provides desired-state JSON, validate it against `references/gp200-tone-desired-state.schema.json` before generating.
- If the request needs a new tone type, add a focused generator function or a reusable recipe map to `scripts/gp200/gp200-prst.ps1`, then generate the preset into `tones/`.
- Preserve the original source `.prst`; never overwrite it.
- Keep the workflow fail-closed: if a model name, parameter, checksum, or import format is uncertain, stop and explain the blocker.

## Validation Commands

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\gp200\gp200-prst.ps1 -Command apply-state -StatePath ".\tones\<PATCH NAME>.desired-state.json"
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\gp200\gp200-prst.ps1 -Command inspect -Path ".\tones\<PATCH NAME>.prst"
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\gp200\gp200-control.ps1 -Command self-test
```

For checksum validation, compute the 16-bit sum of bytes `0x0000` through `0x04C5` and compare it to the big-endian value at `0x04C6`.
