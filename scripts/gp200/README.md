# GP-200 Automation Harness

This folder contains the local automation harness for `GP-200 Edit`.

## Commands

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\gp200\gp200-control.ps1 -Command status
powershell -ExecutionPolicy Bypass -File .\scripts\gp200\gp200-control.ps1 -Command plan -Patch 42-A -Style edge-of-breakup -Routing headphones
powershell -ExecutionPolicy Bypass -File .\scripts\gp200\gp200-control.ps1 -Command takeover -Patch 42-A -Style edge-of-breakup -Routing headphones
powershell -ExecutionPolicy Bypass -File .\scripts\gp200\gp200-control.ps1 -Command refine -Patch 42-A -Style edge-of-breakup -Routing headphones -Feedback "too bright"
powershell -ExecutionPolicy Bypass -File .\scripts\gp200\gp200-control.ps1 -Command self-test
powershell -ExecutionPolicy Bypass -File .\scripts\gp200\gp200-prst.ps1 -Command inspect -Path ".\tones\42-A It's GP-200.example.prst"
powershell -ExecutionPolicy Bypass -File .\scripts\gp200\gp200-prst.ps1 -Command generate-edge -Path ".\tones\42-A It's GP-200.example.prst" -OutPath ".\tones\AI EDGE 42A.prst" -Name "AI EDGE 42A"
powershell -ExecutionPolicy Bypass -File .\scripts\gp200\gp200-prst.ps1 -Command generate-strings -Path ".\tones\42-A It's GP-200.example.prst" -OutPath ".\tones\AI STRINGS 42A.prst" -Name "AI STRINGS 42A"
powershell -ExecutionPolicy Bypass -File .\scripts\gp200\gp200-prst.ps1 -Command apply-state -StatePath ".\tones\AI STRINGS 42A.desired-state.json"
```

## Safety Model

The harness is fail-closed by default. `takeover` launches or attaches to `GP-200 Edit`, foregrounds the editor, checks the current window and UI automation surface, creates a structured tone recipe, and writes trace files under the configured output directory.

It does not write patch parameters unless `-AllowMutation` is supplied. Even then, mutation is currently gated until target patch readback and parameter controls are verified. This prevents accidental overwrites while the selector layer is still being validated.

The first live run confirmed that `GP-200 Edit` exposes only minimal UI Automation text in this environment. Treat the editor as custom-rendered until image-based selectors or another reliable readback method is implemented.

## `.prst` Variant Workflow

`gp200-prst.ps1` can inspect exported GP-200 patch files and generate a named variant without modifying the source export. The current file format support is intentionally narrow: GP-200 `.prst` files with `TSRP` magic, 1224-byte length, 11 module slots, and metadata from the installed `algorithm.xml`.

Generated variants write a sidecar `.trace.json` next to the `.prst` file. The trace includes source hash, output hash, save policy, recipe plan, and decoded inspection data.

The GP-200 editor validates a checksum before import. The checksum is the 16-bit sum of bytes `0x0000` through `0x04C5`, stored big-endian at `0x04C6`.

Desired-state JSON is the preferred repeatable input for new tones. Store desired-state files and generated user-facing patches in `tones/`. Use `apply-state` to validate the JSON, render the binary `.prst`, update the checksum, and write trace or summary outputs declared by the JSON.

Safe validation flow:

1. Export the source patch from `GP-200 Edit`.
2. Write or generate desired-state JSON in `tones/`.
3. Import the generated `.prst` into an unused GP-200 patch slot first.
4. Confirm the editor loads the patch name, algorithms, and audible result.
5. Export the imported patch again and compare the decoded inspection output before overwriting an important slot.

## Patch 42-A

Patch `42-A` is the current takeover target. The harness validates the patch identifier, produces a recipe for that patch, and records whether the target patch was visible to UI Automation. If UI Automation cannot read the custom-rendered editor controls, the trace records `needs-manual-confirmation` and relies on the foregrounded editor state for manual confirmation.
