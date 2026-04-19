[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [ValidateSet('inspect', 'generate-edge', 'generate-strings', 'apply-state')]
  [string] $Command,

  [string] $Path = '',

  [string] $OutPath = '',
  [string] $Name = '',

  [string] $StatePath = ''
)

Set-StrictMode -Version Latest

$AlgorithmPath = 'C:\Program Files\Valeton\GP-200\Resource\GP-200\File\algorithm.xml'
$ModuleOrder = @('PRE', 'WAH', 'DST', 'AMP', 'NR', 'CAB', 'EQ', 'MOD', 'DLY', 'RVB', 'VOL')
$SlotBase = 168
$SlotSize = 72
$SlotHeaderDelta = -8
$ParamCount = 15
$PatchNameOffset = 68
$PatchNameLength = 16
$ChecksumOffset = 0x4C6

function Get-UInt32LE {
  param([byte[]] $Bytes, [int] $Offset)
  [BitConverter]::ToUInt32($Bytes, $Offset)
}

function Get-FloatLE {
  param([byte[]] $Bytes, [int] $Offset)
  [BitConverter]::ToSingle($Bytes, $Offset)
}

function Set-UInt32LE {
  param([byte[]] $Bytes, [int] $Offset, [uint32] $Value)
  [BitConverter]::GetBytes($Value).CopyTo($Bytes, $Offset)
}

function Set-FloatLE {
  param([byte[]] $Bytes, [int] $Offset, [single] $Value)
  [BitConverter]::GetBytes($Value).CopyTo($Bytes, $Offset)
}

function Load-AlgorithmIndex {
  [xml]$xml = Get-Content -LiteralPath $AlgorithmPath
  $byCode = @{}
  $byModuleCode = @{}
  $byModuleName = @{}

  foreach ($catalog in $xml.'GP-200'.Catalog) {
    $module = [string]$catalog.Name
    foreach ($alg in $catalog.Alg) {
      $code = [uint32]$alg.Code
      $knobs = @()
      foreach ($child in $alg.ChildNodes) {
        if ($child.NodeType -ne 'Element') {
          continue
        }
        $elementName = [string]$child.LocalName
        if ($elementName -notin @('Knob', 'Slider', 'Switch', 'Combox')) {
          continue
        }
        $knobs += [ordered]@{
          type = $elementName
          name = $elementName
          label = $elementName
          paramName = [string]$child.GetAttribute('Name')
          idx = if ($child.HasAttribute('idx')) { [int]$child.GetAttribute('idx') } else { [int]$child.GetAttribute('ID') }
          id = if ($child.HasAttribute('ID')) { [int]$child.GetAttribute('ID') } else { $null }
          default = $child.GetAttribute('default')
          min = $child.GetAttribute('Dmin')
          max = $child.GetAttribute('Dmax')
          step = $child.GetAttribute('step')
        }
      }

      $record = [ordered]@{
        module = $module
        name = [string]$alg.Name
        code = $code
        index = [int]$alg.Index
        knobs = $knobs
      }
      if (-not $byCode.ContainsKey([string]$code)) {
        $byCode[[string]$code] = $record
      }
      $byModuleCode["$module::$code"] = $record
      $byModuleName["$module::$($alg.Name)"] = $record
    }
  }

  [ordered]@{
    byCode = $byCode
    byModuleCode = $byModuleCode
    byModuleName = $byModuleName
  }
}

function Get-PatchName {
  param([byte[]] $Bytes)
  $raw = $Bytes[$PatchNameOffset..($PatchNameOffset + $PatchNameLength - 1)]
  $nameBytes = @($raw | Where-Object { $_ -ne 0 })
  if ($nameBytes.Count -eq 0) {
    return ''
  }
  [Text.Encoding]::ASCII.GetString([byte[]]$nameBytes)
}

function Set-PatchName {
  param([byte[]] $Bytes, [string] $Name)
  $encoded = [Text.Encoding]::ASCII.GetBytes($Name)
  if ($encoded.Length -gt $PatchNameLength) {
    throw "Patch name '$Name' is too long. Max $PatchNameLength ASCII bytes."
  }
  for ($i = 0; $i -lt $PatchNameLength; $i++) {
    $Bytes[$PatchNameOffset + $i] = 0
  }
  $encoded.CopyTo($Bytes, $PatchNameOffset)
}

function Update-PrstChecksum {
  param([byte[]] $Bytes)
  if ($Bytes.Length -le ($ChecksumOffset + 1)) {
    throw "Preset is too short for checksum offset 0x$($ChecksumOffset.ToString('X'))."
  }
  $sum = 0
  for ($i = 0; $i -lt $ChecksumOffset; $i++) {
    $sum = ($sum + $Bytes[$i]) -band 0xFFFF
  }
  $Bytes[$ChecksumOffset] = [byte](($sum -shr 8) -band 0xFF)
  $Bytes[($ChecksumOffset + 1)] = [byte]($sum -band 0xFF)
}

function Read-Prst {
  param([string] $Path)
  if (-not $Path) {
    throw 'A .prst path is required for this command.'
  }
  $resolved = (Resolve-Path -LiteralPath $Path).Path
  $bytes = [IO.File]::ReadAllBytes($resolved)
  if ($bytes.Length -ne 1224) {
    throw "Unexpected .prst size $($bytes.Length). Expected 1224 bytes."
  }
  $magic = [Text.Encoding]::ASCII.GetString($bytes[0..3])
  if ($magic -ne 'TSRP') {
    throw "Unexpected .prst magic '$magic'. Expected TSRP."
  }
  [ordered]@{
    path = $resolved
    bytes = $bytes
    sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $resolved).Hash
  }
}

function Resolve-PrstInputPath {
  param([string] $Path, [string] $ExpectedSha256 = '')
  if ($Path -and (Test-Path -LiteralPath $Path)) {
    return (Resolve-Path -LiteralPath $Path).Path
  }
  if ($ExpectedSha256) {
    $expected = $ExpectedSha256.ToUpperInvariant()
    $match = Get-ChildItem -Path . -Recurse -Force -File -Filter '*.prst' |
      Where-Object { (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash -eq $expected } |
      Select-Object -First 1
    if ($match) {
      return $match.FullName
    }
  }
  if ($Path) {
    throw "Could not resolve source .prst '$Path'."
  }
  throw 'Source .prst path is required.'
}

function Resolve-RequiredPath {
  param([string] $Path, [string] $Purpose)
  if (-not $Path) {
    throw "$Purpose path is required."
  }
  (Resolve-Path -LiteralPath $Path).Path
}

function Ensure-ParentDirectory {
  param([string] $Path)
  $parent = Split-Path -Parent $Path
  if ($parent -and -not (Test-Path -LiteralPath $parent)) {
    [IO.Directory]::CreateDirectory($parent) | Out-Null
  }
}

function Convert-ParametersToHashtable {
  param([object] $Parameters)
  $values = @{}
  if (-not $Parameters) {
    return $values
  }
  foreach ($property in $Parameters.PSObject.Properties) {
    $values[$property.Name] = $property.Value
  }
  $values
}

function Assert-DesiredState {
  param([object] $State)
  if (-not $State) {
    throw 'Desired state JSON is empty.'
  }
  if ([int]$State.version -ne 1) {
    throw "Unsupported desired state version '$($State.version)'. Expected 1."
  }
  if (-not $State.name) {
    throw 'Desired state requires name.'
  }
  $encodedName = [Text.Encoding]::ASCII.GetBytes([string]$State.name)
  if ($encodedName.Length -gt $PatchNameLength) {
    throw "Patch name '$($State.name)' is too long. Max $PatchNameLength ASCII bytes."
  }
  foreach ($module in $ModuleOrder) {
    if (-not $State.modules.PSObject.Properties[$module]) {
      throw "Desired state is missing module '$module'."
    }
  }
}

function Validate-ModuleState {
  param(
    [string] $Module,
    [object] $ModuleState,
    [object] $Algorithm
  )
  if (-not $ModuleState.algorithm) {
    throw "Module '$Module' requires algorithm."
  }
  $validParams = @{}
  foreach ($knob in $Algorithm['knobs']) {
    $validParams[[string]$knob['paramName']] = $knob
  }
  $values = Convert-ParametersToHashtable -Parameters $ModuleState.parameters
  foreach ($key in $values.Keys) {
    if (-not $validParams.ContainsKey($key)) {
      throw "Parameter '$key' is not valid for $Module::$($ModuleState.algorithm)."
    }
    $knob = $validParams[$key]
    if ($values[$key] -is [string]) {
      throw "Parameter '$key' for $Module::$($ModuleState.algorithm) must be numeric. Use menu ID values for Switch/Combox parameters."
    }
    $value = [double]$values[$key]
    $min = [string]$knob['min']
    $max = [string]$knob['max']
    if ($min -ne '' -and $value -lt [double]$min) {
      throw "Parameter '$key' for $Module::$($ModuleState.algorithm) is below minimum $min."
    }
    if ($max -ne '' -and $value -gt [double]$max) {
      throw "Parameter '$key' for $Module::$($ModuleState.algorithm) is above maximum $max."
    }
  }
  $values
}

function Inspect-Prst {
  param([string] $Path)
  $preset = Read-Prst -Path $Path
  $algorithms = Load-AlgorithmIndex
  $slots = @()

  for ($slot = 0; $slot -lt $ModuleOrder.Count; $slot++) {
    $offset = $SlotBase + ($slot * $SlotSize)
    $code = Get-UInt32LE -Bytes $preset.bytes -Offset $offset
    $expectedModule = $ModuleOrder[$slot]
    $alg = $algorithms.byModuleCode["$expectedModule::$code"]
    if (-not $alg) {
      $alg = $algorithms.byCode[[string]$code]
    }
    $params = @()
    for ($i = 0; $i -lt $ParamCount; $i++) {
      $value = Get-FloatLE -Bytes $preset.bytes -Offset ($offset + 4 + ($i * 4))
      $paramMeta = $null
      if ($alg -and $i -lt $alg['knobs'].Count) {
        $paramMeta = $alg['knobs'][$i]
      }
      $params += [ordered]@{
        index = $i
        name = if ($paramMeta) { $paramMeta['paramName'] } else { $null }
        value = [Math]::Round([double]$value, 4)
      }
    }

    $slots += [ordered]@{
      slot = $slot
      expectedModule = $expectedModule
      offset = $offset
      code = $code
      active = $preset.bytes[$offset + $SlotHeaderDelta + 5] -eq 1
      module = if ($alg) { $alg['module'] } else { $null }
      algorithm = if ($alg) { $alg['name'] } else { $null }
      params = $params
      headerHex = (($preset.bytes[($offset + $SlotHeaderDelta)..($offset - 1)] | ForEach-Object { $_.ToString('X2') }) -join ' ')
      trailerHex = (($preset.bytes[($offset + 64)..($offset + 71)] | ForEach-Object { $_.ToString('X2') }) -join ' ')
    }
  }

  [ordered]@{
    path = $preset.path
    size = $preset.bytes.Length
    sha256 = $preset.sha256
    magic = 'TSRP'
    patchName = Get-PatchName -Bytes $preset.bytes
    checksum = '{0:X4}' -f (([int]$preset.bytes[$ChecksumOffset] * 256) + [int]$preset.bytes[($ChecksumOffset + 1)])
    slots = $slots
  }
}

function Set-Algorithm {
  param(
    [byte[]] $Bytes,
    [int] $Slot,
    [uint32] $Code
  )
  Set-UInt32LE -Bytes $Bytes -Offset ($SlotBase + ($Slot * $SlotSize)) -Value $Code
}

function Set-SlotActive {
  param(
    [byte[]] $Bytes,
    [int] $Slot,
    [bool] $Active
  )
  $Bytes[($SlotBase + ($Slot * $SlotSize) + $SlotHeaderDelta + 5)] = if ($Active) { [byte]1 } else { [byte]0 }
}

function Set-Param {
  param(
    [byte[]] $Bytes,
    [int] $Slot,
    [int] $Index,
    [single] $Value
  )
  Set-FloatLE -Bytes $Bytes -Offset ($SlotBase + ($Slot * $SlotSize) + 4 + ($Index * 4)) -Value $Value
}

function Set-SlotFromAlgorithm {
  param(
    [byte[]] $Bytes,
    [object] $Algorithm,
    [int] $Slot,
    [hashtable] $Values,
    [AllowNull()]
    [object] $Active = $null
  )
  if ($null -ne $Active) {
    Set-SlotActive -Bytes $Bytes -Slot $Slot -Active ([bool]$Active)
  }
  Set-Algorithm -Bytes $Bytes -Slot $Slot -Code ([uint32]$Algorithm['code'])
  for ($i = 0; $i -lt $ParamCount; $i++) {
    Set-Param -Bytes $Bytes -Slot $Slot -Index $i -Value 0
  }
  foreach ($knob in $Algorithm['knobs']) {
    $idx = [int]$knob['idx']
    $paramName = [string]$knob['paramName']
    $default = [string]$knob['default']
    $value = if ($Values.ContainsKey($paramName)) { [single]$Values[$paramName] } elseif ($default -ne '') { [single]$default } else { [single]0 }
    Set-Param -Bytes $Bytes -Slot $Slot -Index $idx -Value $value
  }
}

function Generate-EdgePreset {
  param([string] $Path, [string] $OutPath, [string] $Name)
  if (-not $Name) {
    $Name = 'AI EDGE 42A'
  }
  $preset = Read-Prst -Path $Path
  $bytes = [byte[]]::new($preset.bytes.Length)
  $preset.bytes.CopyTo($bytes, 0)
  $algorithms = Load-AlgorithmIndex

  Set-PatchName -Bytes $bytes -Name $Name

  $plan = @(
    @{ slot = 0; key = 'PRE::Micro Boost'; values = @{ Gain = 18 } }
    @{ slot = 2; key = 'DST::Green OD'; values = @{ Gain = 12; Tone = 58; Volume = 55 } }
    @{ slot = 3; key = 'AMP::Tweedy'; values = @{ Gain = 38; Tone = 52; Volume = 50 } }
    @{ slot = 4; key = 'NR::Gate 1'; values = @{ Threshold = 20 } }
    @{ slot = 5; key = 'CAB::SUP ZEP'; values = @{ Volume = 50; 'Low Cut' = 80; 'High Cut' = 6200 } }
    @{ slot = 6; key = 'EQ::Guitar EQ 1'; values = @{ '125Hz' = 0; '400Hz' = 1; '800Hz' = 0; '1.6kHz' = 1; '4kHz' = -1; Volume = 50 } }
    @{ slot = 8; key = 'DLY::BBD Delay S'; values = @{ Mix = 14; Time = 420; Feedback = 22 } }
    @{ slot = 9; key = 'RVB::Room'; values = @{ Mix = 16; 'Pre Delay' = 30; Decay = 28 } }
    @{ slot = 10; key = 'VOL::Volume'; values = @{ Volume = 100 } }
  )

  foreach ($item in $plan) {
    $alg = $algorithms.byModuleName[$item.key]
    if (-not $alg) {
      throw "Algorithm '$($item.key)' not found in algorithm.xml."
    }
    $active = if ($item.ContainsKey('active')) { [bool]$item.active } else { $null }
    Set-SlotFromAlgorithm -Bytes $bytes -Algorithm $alg -Slot $item.slot -Values $item.values -Active $active
  }

  Update-PrstChecksum -Bytes $bytes

  if (-not $OutPath) {
    $OutPath = Join-Path (Split-Path -Parent (Resolve-Path -LiteralPath $Path)) "$Name.prst"
  }
  [IO.File]::WriteAllBytes($OutPath, $bytes)
  $inspection = Inspect-Prst -Path $OutPath
  $tracePath = [IO.Path]::ChangeExtension((Resolve-Path -LiteralPath $OutPath).Path, '.trace.json')
  [ordered]@{
    generatedAt = (Get-Date).ToString('o')
    command = 'generate-edge'
    sourcePath = $preset.path
    sourceSha256 = $preset.sha256
    outputPath = (Resolve-Path -LiteralPath $OutPath).Path
    outputSha256 = $inspection.sha256
    patchName = $Name
    savePolicy = 'named-variant'
    plan = $plan
    inspection = $inspection
  } | ConvertTo-Json -Depth 14 | Set-Content -LiteralPath $tracePath -Encoding UTF8
  $inspection
}

function Generate-StringsPreset {
  param([string] $Path, [string] $OutPath, [string] $Name)
  if (-not $Name) {
    $Name = 'AI STRINGS 42A'
  }
  $preset = Read-Prst -Path $Path
  $bytes = [byte[]]::new($preset.bytes.Length)
  $preset.bytes.CopyTo($bytes, 0)
  $algorithms = Load-AlgorithmIndex

  Set-PatchName -Bytes $bytes -Name $Name

  $plan = @(
    @{ slot = 0; key = 'PRE::Pitch'; active = $true; values = @{ 'Hi Pitch' = 12; 'Low Pitch' = -12; Dry = 35; 'Hi Vol' = 42; 'Low Vol' = 28 } }
    @{ slot = 1; key = 'WAH::V-Wah'; active = $false; values = @{} }
    @{ slot = 2; key = 'DST::Green OD'; active = $false; values = @{} }
    @{ slot = 3; key = 'AMP::Silver Twin'; active = $true; values = @{ Gain = 18; Volume = 48; Bass = 45; Middle = 58; Treble = 32 } }
    @{ slot = 4; key = 'NR::Auto Swell'; active = $true; values = @{ Attack = 1350; Curve = 1 } }
    @{ slot = 5; key = 'CAB::DARK LUX'; active = $true; values = @{ Volume = 50; 'Low Cut' = 120; 'High Cut' = 5200 } }
    @{ slot = 6; key = 'EQ::Guitar EQ 1'; active = $true; values = @{ '125Hz' = -3; '400Hz' = 1; '800Hz' = 2; '1.6kHz' = 1; '4kHz' = -4; Volume = 50 } }
    @{ slot = 7; key = 'MOD::Detune'; active = $true; values = @{ Detune = -9; Wet = 45; Dry = 65 } }
    @{ slot = 8; key = 'DLY::Tape Delay S'; active = $true; values = @{ Mix = 18; Time = 720; Feedback = 28; 'Time R%' = 61.8; Spread = 100; 'Wow &' = 25; Age = 1; Scrape = 20; Drive = 0; Level = 45; Sync = 0; Trail = 1 } }
    @{ slot = 9; key = 'RVB::Shimmer'; active = $true; values = @{ Mix = 38; 'Pre Delay' = 25; Decay = 70; 'Lo End' = 5; 'Hi End' = -8; Trail = 1 } }
    @{ slot = 10; key = 'VOL::Volume'; active = $true; values = @{ Volume = 100 } }
  )

  foreach ($item in $plan) {
    $alg = $algorithms.byModuleName[$item.key]
    if (-not $alg) {
      throw "Algorithm '$($item.key)' not found in algorithm.xml."
    }
    Set-SlotFromAlgorithm -Bytes $bytes -Algorithm $alg -Slot $item.slot -Values $item.values -Active ([bool]$item.active)
  }

  Update-PrstChecksum -Bytes $bytes

  if (-not $OutPath) {
    $OutPath = Join-Path (Split-Path -Parent (Resolve-Path -LiteralPath $Path)) "$Name.prst"
  }
  [IO.File]::WriteAllBytes($OutPath, $bytes)
  $inspection = Inspect-Prst -Path $OutPath
  $tracePath = [IO.Path]::ChangeExtension((Resolve-Path -LiteralPath $OutPath).Path, '.trace.json')
  [ordered]@{
    generatedAt = (Get-Date).ToString('o')
    command = 'generate-strings'
    sourcePath = $preset.path
    sourceSha256 = $preset.sha256
    outputPath = (Resolve-Path -LiteralPath $OutPath).Path
    outputSha256 = $inspection.sha256
    patchName = $Name
    savePolicy = 'named-variant'
    intent = 'Bow-like guitar string pad: slow attack, octave layering, detune ensemble spread, tape delay, and shimmer reverb.'
    plan = $plan
    inspection = $inspection
  } | ConvertTo-Json -Depth 14 | Set-Content -LiteralPath $tracePath -Encoding UTF8
  $inspection
}

function Apply-DesiredState {
  param([string] $StatePath, [string] $Path, [string] $OutPath, [string] $Name)
  $stateFile = Resolve-RequiredPath -Path $StatePath -Purpose 'Desired state JSON'
  $state = Get-Content -LiteralPath $stateFile -Raw | ConvertFrom-Json
  Assert-DesiredState -State $state

  $requestedSourcePath = if ($Path) { $Path } else { [string]$state.source.prst }
  $sourcePath = Resolve-PrstInputPath -Path $requestedSourcePath -ExpectedSha256 ([string]$state.source.expectedSha256)
  $preset = Read-Prst -Path $sourcePath
  if ($state.source.expectedSha256 -and $preset.sha256 -ne ([string]$state.source.expectedSha256).ToUpperInvariant()) {
    throw "Source SHA256 mismatch. Expected $($state.source.expectedSha256), got $($preset.sha256)."
  }

  $patchName = if ($Name) { $Name } else { [string]$state.name }
  $targetPath = if ($OutPath) { $OutPath } else { [string]$state.output.prst }
  if (-not $targetPath) {
    $targetPath = Join-Path 'tones' "$patchName.prst"
  }
  Ensure-ParentDirectory -Path $targetPath

  $bytes = [byte[]]::new($preset.bytes.Length)
  $preset.bytes.CopyTo($bytes, 0)
  $algorithms = Load-AlgorithmIndex
  Set-PatchName -Bytes $bytes -Name $patchName

  $plan = @()
  for ($slot = 0; $slot -lt $ModuleOrder.Count; $slot++) {
    $module = $ModuleOrder[$slot]
    $moduleState = $state.modules.$module
    $key = "$module::$($moduleState.algorithm)"
    $alg = $algorithms.byModuleName[$key]
    if (-not $alg) {
      throw "Algorithm '$key' not found in algorithm.xml."
    }
    $values = Validate-ModuleState -Module $module -ModuleState $moduleState -Algorithm $alg
    Set-SlotFromAlgorithm -Bytes $bytes -Algorithm $alg -Slot $slot -Values $values -Active ([bool]$moduleState.active)
    $plan += [ordered]@{
      slot = $slot
      module = $module
      key = $key
      active = [bool]$moduleState.active
      values = $values
    }
  }

  Update-PrstChecksum -Bytes $bytes
  [IO.File]::WriteAllBytes($targetPath, $bytes)
  $inspection = Inspect-Prst -Path $targetPath
  $resolvedOut = (Resolve-Path -LiteralPath $targetPath).Path
  $tracePath = if ($state.output.trace) { [string]$state.output.trace } else { [IO.Path]::ChangeExtension($resolvedOut, '.trace.json') }
  Ensure-ParentDirectory -Path $tracePath
  [ordered]@{
    generatedAt = (Get-Date).ToString('o')
    command = 'apply-state'
    desiredStatePath = $stateFile
    sourcePath = $preset.path
    sourceSha256 = $preset.sha256
    outputPath = $resolvedOut
    outputSha256 = $inspection.sha256
    patchName = $patchName
    routing = $state.routing
    savePolicy = if ($state.savePolicy) { $state.savePolicy } else { 'named-variant' }
    description = $state.description
    plan = $plan
    desiredState = $state
    inspection = $inspection
  } | ConvertTo-Json -Depth 16 | Set-Content -LiteralPath $tracePath -Encoding UTF8

  if ($state.output.summary) {
    Ensure-ParentDirectory -Path ([string]$state.output.summary)
    @(
      "# $patchName"
      ''
      $state.description
      ''
      "Source: $($preset.path)"
      "Output: $resolvedOut"
      "Routing: $($state.routing)"
      "Checksum: $($inspection.checksum)"
      ''
      '## Modules'
      ($inspection.slots | ForEach-Object { "- $($_.expectedModule): $(if ($_.active) { 'on' } else { 'off' }) $($_.algorithm)" })
    ) | Set-Content -LiteralPath ([string]$state.output.summary) -Encoding UTF8
  }

  $inspection
}

try {
  switch ($Command) {
    'inspect' {
      Inspect-Prst -Path $Path | ConvertTo-Json -Depth 12
    }
    'generate-edge' {
      Generate-EdgePreset -Path $Path -OutPath $OutPath -Name $Name | ConvertTo-Json -Depth 12
    }
    'generate-strings' {
      Generate-StringsPreset -Path $Path -OutPath $OutPath -Name $Name | ConvertTo-Json -Depth 12
    }
    'apply-state' {
      Apply-DesiredState -StatePath $StatePath -Path $Path -OutPath $OutPath -Name $Name | ConvertTo-Json -Depth 12
    }
  }
} catch {
  [ordered]@{
    status = 'error'
    message = $_.Exception.Message
  } | ConvertTo-Json -Depth 6
  exit 1
}
