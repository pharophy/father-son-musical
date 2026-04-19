# GP-200 Desired-State JSON Format

Use desired-state JSON when a tone should be reproducible, reviewable, or generated from a structured target instead of a one-off hardcoded preset function.

Schema file: [gp200-tone-desired-state.schema.json](gp200-tone-desired-state.schema.json)

## Minimal Example

```json
{
  "version": 1,
  "name": "AI STRINGS 42A",
  "description": "Bow-like guitar string pad with slow attack, octave layering, ensemble spread, tape delay, and shimmer reverb.",
  "source": {
    "prst": "tones/42-A It's GP-200.example.prst"
  },
  "output": {
    "prst": "tones/AI STRINGS 42A.prst",
    "trace": "tones/AI STRINGS 42A.trace.json",
    "summary": "tones/AI STRINGS 42A.summary.md"
  },
  "routing": "headphones",
  "savePolicy": "named-variant",
  "tags": ["ambient", "strings", "pad"],
  "modules": {
    "PRE": {
      "active": true,
      "algorithm": "Pitch",
      "parameters": {
        "Hi Pitch": 12,
        "Low Pitch": -12,
        "Dry": 35,
        "Hi Vol": 42,
        "Low Vol": 28
      }
    },
    "WAH": {
      "active": false,
      "algorithm": "V-Wah",
      "parameters": {}
    },
    "DST": {
      "active": false,
      "algorithm": "Green OD",
      "parameters": {}
    },
    "AMP": {
      "active": true,
      "algorithm": "Silver Twin",
      "parameters": {
        "Gain": 18,
        "Volume": 48,
        "Bass": 45,
        "Middle": 58,
        "Treble": 32
      }
    },
    "NR": {
      "active": true,
      "algorithm": "Auto Swell",
      "parameters": {
        "Attack": 1350,
        "Curve": 1
      }
    },
    "CAB": {
      "active": true,
      "algorithm": "DARK LUX",
      "parameters": {
        "Volume": 50,
        "Low Cut": 120,
        "High Cut": 5200
      }
    },
    "EQ": {
      "active": true,
      "algorithm": "Guitar EQ 1",
      "parameters": {
        "125Hz": -3,
        "400Hz": 1,
        "800Hz": 2,
        "1.6kHz": 1,
        "4kHz": -4,
        "Volume": 50
      }
    },
    "MOD": {
      "active": true,
      "algorithm": "Detune",
      "parameters": {
        "Detune": -9,
        "Wet": 45,
        "Dry": 65
      }
    },
    "DLY": {
      "active": true,
      "algorithm": "Tape Delay S",
      "parameters": {
        "Mix": 18,
        "Time": 720,
        "Feedback": 28,
        "Time R%": 61.8,
        "Spread": 100,
        "Wow &": 25,
        "Age": 1,
        "Scrape": 20,
        "Drive": 0,
        "Level": 45,
        "Sync": 0,
        "Trail": 1
      }
    },
    "RVB": {
      "active": true,
      "algorithm": "Shimmer",
      "parameters": {
        "Mix": 38,
        "Pre Delay": 25,
        "Decay": 70,
        "Lo End": 5,
        "Hi End": -8,
        "Trail": 1
      }
    },
    "VOL": {
      "active": true,
      "algorithm": "Volume",
      "parameters": {
        "Volume": 100
      }
    }
  }
}
```

## How To Use It

1. Choose or export a source `.prst`.
2. Write a desired-state JSON file with all 11 modules.
3. Use exact module names: `PRE`, `WAH`, `DST`, `AMP`, `NR`, `CAB`, `EQ`, `MOD`, `DLY`, `RVB`, `VOL`.
4. Use algorithm/model names exactly as they appear in `algorithm.xml`.
5. Use parameter names exactly as they appear in `algorithm.xml`.
6. Use numeric values inside `Dmin` and `Dmax`.
7. Use numeric menu IDs for `Switch` and `Combox` parameters unless generator code explicitly supports label-to-ID mapping.
8. Generate the `.prst` into `tones/`.
9. Recalculate the GP-200 checksum after writing bytes.
10. Import into a safe GP-200 slot first.

Render a desired-state file:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\gp200\gp200-prst.ps1 -Command apply-state -StatePath ".\tones\AI STRINGS 42A.desired-state.json"
```

Override the source or output paths without editing the JSON:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\gp200\gp200-prst.ps1 -Command apply-state -StatePath ".\tones\AI STRINGS 42A.desired-state.json" -Path ".\tones\42-A It's GP-200.example.prst" -OutPath ".\tones\AI STRINGS ALT.prst" -Name "AI STRINGS ALT"
```

## How To Find Available Algorithms

The installed GP-200 metadata is here:

```text
C:\Program Files\Valeton\GP-200\Resource\GP-200\File\algorithm.xml
```

Find all algorithms for one module:

```powershell
[xml]$xml = Get-Content 'C:\Program Files\Valeton\GP-200\Resource\GP-200\File\algorithm.xml'
$xml.'GP-200'.Catalog |
  Where-Object { $_.Name -eq 'MOD' } |
  ForEach-Object { $_.Alg | Select-Object Name, Code, Index }
```

Search by keyword:

```powershell
Select-String -LiteralPath 'C:\Program Files\Valeton\GP-200\Resource\GP-200\File\algorithm.xml' -Pattern 'Shimmer|Detune|Swell|Pitch' -Context 0,12
```

## How To Find Available Parameters And Values

Each `<Alg>` contains `Knob`, `Slider`, `Switch`, or `Combox` children.

- `Name` is the JSON parameter key.
- `idx` is the parameter slot written into the `.prst`.
- `default` is the factory/default value.
- `Dmin` and `Dmax` are numeric bounds for knobs/sliders.
- `Menu` child `ID` values are the numeric values for switches/combos.

Example query for a specific algorithm:

```powershell
[xml]$xml = Get-Content 'C:\Program Files\Valeton\GP-200\Resource\GP-200\File\algorithm.xml'
$alg = $xml.'GP-200'.Catalog |
  Where-Object { $_.Name -eq 'RVB' } |
  ForEach-Object { $_.Alg } |
  Where-Object { $_.Name -eq 'Shimmer' }
$alg.ChildNodes |
  Where-Object { $_.NodeType -eq 'Element' } |
  Select-Object LocalName, Name, idx, default, Dmin, Dmax
```

For switches/combos, inspect menu IDs:

```powershell
$alg.ChildNodes |
  Where-Object { $_.NodeType -eq 'Element' -and $_.LocalName -in @('Switch', 'Combox') } |
  ForEach-Object {
    $_.Name
    $_.Menu | Select-Object Name, ID
  }
```

## Validation Checklist

- Patch name is ASCII and no more than 16 bytes.
- Output path is under `tones/`.
- `.prst` file is exactly 1224 bytes.
- Magic is `TSRP`.
- Every algorithm exists for the expected module.
- Every parameter exists for the selected algorithm.
- Every numeric value is inside its documented range.
- Stored checksum equals computed checksum.
