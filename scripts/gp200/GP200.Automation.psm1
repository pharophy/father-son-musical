Set-StrictMode -Version Latest

$script:DefaultExePath = 'C:\Program Files\Valeton\GP-200\GP-200.exe'
$script:KnownModules = @('PRE', 'WAH', 'DST', 'AMP', 'NR', 'CAB', 'EQ', 'MOD', 'DLY', 'RVB', 'VOL')
$script:PatchPattern = '^(?<bank>\d+)-(?<slot>[A-D])$'

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class NativeWindow {
  [DllImport("user32.dll")]
  public static extern bool SetForegroundWindow(IntPtr hWnd);

  [DllImport("user32.dll")]
  public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
}
'@

function New-GP200LogEntry {
  param(
    [Parameter(Mandatory)][string] $Step,
    [Parameter(Mandatory)][string] $Status,
    [hashtable] $Data = @{}
  )

  [ordered]@{
    timestamp = (Get-Date).ToString('o')
    step = $Step
    status = $Status
    data = $Data
  }
}

function Write-GP200Trace {
  param(
    [Parameter(Mandatory)][array] $Entries,
    [Parameter(Mandatory)][string] $Path
  )

  $dir = Split-Path -Parent $Path
  if ($dir -and -not (Test-Path $dir)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
  }

  $Entries | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Get-GP200ExePath {
  param([string] $ExePath = $script:DefaultExePath)

  if (-not (Test-Path -LiteralPath $ExePath)) {
    throw "GP-200 editor executable was not found at '$ExePath'."
  }

  (Resolve-Path -LiteralPath $ExePath).Path
}

function Get-GP200Process {
  Get-Process -Name 'GP-200' -ErrorAction SilentlyContinue |
    Where-Object { $_.MainWindowHandle -ne 0 } |
    Select-Object -First 1
}

function Start-GP200Editor {
  param(
    [string] $ExePath = $script:DefaultExePath,
    [int] $TimeoutSeconds = 20
  )

  $resolved = Get-GP200ExePath -ExePath $ExePath
  $existing = Get-GP200Process
  if ($existing) {
    return [ordered]@{
      process = $existing
      launched = $false
      exePath = $resolved
    }
  }

  $process = Start-Process -FilePath $resolved -PassThru
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  do {
    Start-Sleep -Milliseconds 500
    $attached = Get-GP200Process
    if ($attached) {
      return [ordered]@{
        process = $attached
        launched = $true
        exePath = $resolved
      }
    }
  } while ((Get-Date) -lt $deadline)

  throw "GP-200 editor launched as PID $($process.Id), but no main window was available within $TimeoutSeconds seconds."
}

function Set-GP200Foreground {
  param([Parameter(Mandatory)] $Process)

  if ($Process.MainWindowHandle -eq 0) {
    throw "Cannot foreground GP-200 editor because the process has no main window handle."
  }

  [NativeWindow]::ShowWindowAsync($Process.MainWindowHandle, 5) | Out-Null
  [NativeWindow]::SetForegroundWindow($Process.MainWindowHandle) | Out-Null
}

function Get-GP200WindowSnapshot {
  param([Parameter(Mandatory)] $Process)

  $process.Refresh()
  $startTime = try { $Process.StartTime.ToString('o') } catch { $null }
  [ordered]@{
    processName = $Process.ProcessName
    id = $Process.Id
    mainWindowTitle = $Process.MainWindowTitle
    mainWindowHandle = "0x{0:X}" -f $Process.MainWindowHandle.ToInt64()
    path = $Process.Path
    startTime = $startTime
    responding = $Process.Responding
  }
}

function Get-GP200AutomationSurface {
  $uiaAvailable = $false
  $uiaError = $null
  try {
    Add-Type -AssemblyName UIAutomationClient
    Add-Type -AssemblyName UIAutomationTypes
    $uiaAvailable = $true
  } catch {
    $uiaError = $_.Exception.Message
  }

  [ordered]@{
    uiAutomationAvailable = $uiaAvailable
    uiAutomationError = $uiaError
    imageFallbackAvailable = $true
    recommendation = if ($uiaAvailable) { 'hybrid-uia-with-image-fallback' } else { 'image-fallback' }
  }
}

function Get-GP200UiText {
  param(
    [Parameter(Mandatory)] $Process,
    [int] $MaxDepth = 5
  )

  Add-Type -AssemblyName UIAutomationClient
  Add-Type -AssemblyName UIAutomationTypes

  $root = [System.Windows.Automation.AutomationElement]::FromHandle($Process.MainWindowHandle)
  if (-not $root) {
    return @()
  }

  $results = New-Object System.Collections.Generic.List[object]

  function WalkElement {
    param($Element, [int] $Depth)

    if ($Depth -gt $MaxDepth -or -not $Element) {
      return
    }

    $name = $Element.Current.Name
    $controlType = $Element.Current.ControlType.ProgrammaticName
    if ($name) {
      $results.Add([ordered]@{
        depth = $Depth
        name = $name
        controlType = $controlType
        automationId = $Element.Current.AutomationId
      }) | Out-Null
    }

    $walker = [System.Windows.Automation.TreeWalker]::ControlViewWalker
    $child = $walker.GetFirstChild($Element)
    while ($child) {
      WalkElement -Element $child -Depth ($Depth + 1)
      $child = $walker.GetNextSibling($child)
    }
  }

  WalkElement -Element $root -Depth 0
  $results.ToArray()
}

function Test-GP200KnownView {
  param(
    [Parameter(Mandatory)] $Snapshot,
    [array] $UiText = @()
  )

  $names = @($UiText | ForEach-Object { $_.name })
  $hasPatchSignals = ($names -contains 'Patch List') -or ($names -contains 'Patch Setting') -or ($names -contains 'Patch VOL')
  $titleLooksValid = [string]$Snapshot.mainWindowTitle -match 'V\d+\.\d+\.\d+'

  [ordered]@{
    known = [bool]($titleLooksValid -and ($hasPatchSignals -or $names.Count -eq 0))
    titleLooksValid = [bool]$titleLooksValid
    patchEditingSignals = [bool]$hasPatchSignals
    uiTextCount = $names.Count
  }
}

function Test-GP200PatchId {
  param([Parameter(Mandatory)][string] $Patch)

  if ($Patch -notmatch $script:PatchPattern) {
    throw "Patch '$Patch' is invalid. Expected format like 42-A."
  }

  [ordered]@{
    patch = $Patch
    bank = [int]$Matches.bank
    slot = $Matches.slot
  }
}

function Test-GP200ModuleName {
  param([Parameter(Mandatory)][string] $Module)

  $normalized = $Module.Trim().ToUpperInvariant()
  if ($script:KnownModules -notcontains $normalized) {
    throw "Unsupported GP-200 module '$Module'. Supported modules: $($script:KnownModules -join ', ')."
  }

  $normalized
}

function New-GP200ModuleSelectionOperation {
  param(
    [Parameter(Mandatory)][string] $Module,
    [bool] $Enabled = $true
  )

  [ordered]@{
    type = 'select-module'
    module = Test-GP200ModuleName -Module $Module
    enabled = $Enabled
  }
}

function New-GP200ModelSelectionOperation {
  param(
    [Parameter(Mandatory)][string] $Module,
    [Parameter(Mandatory)][string] $Model
  )

  [ordered]@{
    type = 'select-model'
    module = Test-GP200ModuleName -Module $Module
    model = $Model
  }
}

function Test-GP200ParameterTargets {
  param(
    [Parameter(Mandatory)][string] $Module,
    [Parameter(Mandatory)] $Targets
  )

  $normalizedModule = Test-GP200ModuleName -Module $Module
  $validated = [ordered]@{}

  $pairs = @()
  if ($Targets -is [System.Collections.IDictionary]) {
    foreach ($key in $Targets.Keys) {
      $pairs += [pscustomobject]@{ Name = [string]$key; Value = $Targets[$key] }
    }
  } else {
    $pairs = @($Targets.PSObject.Properties | Where-Object {
      $_.MemberType -in @('NoteProperty', 'Property')
    })
  }

  foreach ($property in $pairs) {
    $name = $property.Name
    $value = $property.Value

    if ($value -isnot [int] -and $value -isnot [double]) {
      throw "Parameter '$name' for module '$normalizedModule' must be numeric."
    }

    $min = 0
    $max = 100
    if ($name -in @('time')) {
      $min = 1
      $max = 2000
    }
    if ($name -in @('lowCut', 'highCut')) {
      $min = 20
      $max = 20000
    }
    if ($normalizedModule -eq 'EQ' -and $name -in @('lowMid', 'highMid', 'mid')) {
      $min = -12
      $max = 12
    }

    if ($value -lt $min -or $value -gt $max) {
      throw "Parameter '$name' for module '$normalizedModule' is $value, outside supported range $min-$max."
    }

    $validated[$name] = $value
  }

  $validated
}

function New-GP200ParameterWriteOperation {
  param(
    [Parameter(Mandatory)][string] $Module,
    [Parameter(Mandatory)] $Targets
  )

  [ordered]@{
    type = 'write-parameters'
    module = Test-GP200ModuleName -Module $Module
    targets = Test-GP200ParameterTargets -Module $Module -Targets $Targets
  }
}

function Convert-GP200RecipeToOperations {
  param([Parameter(Mandatory)] $Recipe)

  $operations = New-Object System.Collections.Generic.List[object]
  foreach ($module in $Recipe.modules) {
    $operations.Add((New-GP200ModuleSelectionOperation -Module $module.module -Enabled $module.enabled)) | Out-Null
    $operations.Add((New-GP200ModelSelectionOperation -Module $module.module -Model $module.model)) | Out-Null
    $operations.Add((New-GP200ParameterWriteOperation -Module $module.module -Targets $module.targets)) | Out-Null
  }

  $operations.ToArray()
}

function Invoke-GP200RecipeExecution {
  param(
    [Parameter(Mandatory)] $Recipe,
    [Parameter(Mandatory)] $KnownView,
    [switch] $AllowMutation
  )

  $operations = Convert-GP200RecipeToOperations -Recipe $Recipe
  if (-not $AllowMutation) {
    return [ordered]@{
      status = 'dry-run'
      operations = $operations
      reason = 'Mutation was not requested.'
    }
  }

  if (-not $KnownView.known) {
    return [ordered]@{
      status = 'blocked'
      operations = $operations
      reason = 'Editor view is not verified strongly enough for mutation.'
    }
  }

  [ordered]@{
    status = 'blocked'
    operations = $operations
    reason = 'Parameter control selectors are not verified for custom-rendered GP-200 editor widgets.'
  }
}

function New-GP200ToneBrief {
  param(
    [Parameter(Mandatory)][string] $Patch,
    [string] $Style = 'edge-of-breakup',
    [string] $Routing = 'headphones',
    [string] $Use = 'general performance',
    [string] $SavePolicy = 'manual-confirm'
  )

  $patchInfo = Test-GP200PatchId -Patch $Patch
  $normalizedRouting = ConvertTo-GP200Routing -Routing $Routing

  [ordered]@{
    patch = $patchInfo.patch
    bank = $patchInfo.bank
    slot = $patchInfo.slot
    style = (Normalize-GP200ToneStyle -Style $Style)
    routing = $normalizedRouting
    intendedUse = $Use
    savePolicy = $SavePolicy
    constraints = @(
      'fail-closed-on-unknown-view',
      'no-parameter-mutation-without-target-confirmation',
      'preserve-trace-before-save'
    )
  }
}

function ConvertTo-GP200Routing {
  param([Parameter(Mandatory)][string] $Routing)

  $value = $Routing.Trim().ToLowerInvariant()
  switch -Regex ($value) {
    '^(frfr|full.?range|pa)$' { return 'FRFR' }
    '^headphones?$' { return 'headphones' }
    '^(interface|usb|recording)$' { return 'interface' }
    '^(amp front|front|guitar amp input)$' { return 'amp front' }
    '^(amp return|return|power amp)$' { return 'amp return' }
    '^(4cm|four cable|four-cable)$' { return '4CM' }
    default { throw "Unsupported routing context '$Routing'." }
  }
}

function Normalize-GP200ToneStyle {
  param([Parameter(Mandatory)][string] $Style)

  $value = $Style.Trim().ToLowerInvariant()
  switch -Regex ($value) {
    '^(clean|pristine)$' { return 'clean' }
    '^(edge|edge-of-breakup|breakup|crunch)$' { return 'edge-of-breakup' }
    '^(high gain|modern high gain|metal|heavy)$' { return 'modern-high-gain' }
    '^(ambient|cinematic|soundscape)$' { return 'ambient-cinematic' }
    default { throw "Unsupported tone style '$Style'." }
  }
}

function New-GP200PatchRecipe {
  param([Parameter(Mandatory)] $Brief)

  $ampEnabled = $true
  $cabEnabled = $true
  $noCab = $false
  switch ($Brief.routing) {
    'amp front' {
      $ampEnabled = $false
      $cabEnabled = $false
      $noCab = $true
    }
    'amp return' {
      $ampEnabled = $true
      $cabEnabled = $false
      $noCab = $true
    }
    '4CM' {
      $ampEnabled = $false
      $cabEnabled = $false
      $noCab = $true
    }
  }

  $template = switch ($Brief.style) {
    'clean' {
      @{
        name = 'Clean Foundation'
        modules = @(
          @{ module = 'PRE'; model = 'COMP'; enabled = $true; targets = @{ sustain = 20; volume = 50 } }
          @{ module = 'AMP'; model = 'clean-low-gain'; enabled = $ampEnabled; targets = @{ gain = 25; bass = 48; mid = 52; treble = 50 } }
          @{ module = 'CAB'; model = 'matched-clean-cab'; enabled = $cabEnabled; targets = @{ lowCut = 80; highCut = 6500 } }
          @{ module = 'EQ'; model = 'Guitar EQ'; enabled = $true; targets = @{ lowCut = 80; highCut = 7000 } }
          @{ module = 'DLY'; model = 'subtle-delay'; enabled = $true; targets = @{ mix = 12; feedback = 18 } }
          @{ module = 'RVB'; model = 'Room'; enabled = $true; targets = @{ mix = 18; decay = 30 } }
        )
      }
    }
    'modern-high-gain' {
      @{
        name = 'Modern High Gain'
        modules = @(
          @{ module = 'DST'; model = 'tight-boost'; enabled = $true; targets = @{ gain = 10; tone = 58; level = 65 } }
          @{ module = 'AMP'; model = 'modern-high-gain'; enabled = $ampEnabled; targets = @{ gain = 58; bass = 42; mid = 48; treble = 55; presence = 52 } }
          @{ module = 'NR'; model = 'Gate 1'; enabled = $true; targets = @{ threshold = 42; decay = 35 } }
          @{ module = 'CAB'; model = '4x12-modern'; enabled = $cabEnabled; targets = @{ lowCut = 90; highCut = 5600 } }
          @{ module = 'EQ'; model = 'Guitar EQ'; enabled = $true; targets = @{ lowCut = 90; highCut = 5800; lowMid = -2; highMid = 1 } }
          @{ module = 'RVB'; model = 'Room'; enabled = $true; targets = @{ mix = 10; decay = 20 } }
        )
      }
    }
    'ambient-cinematic' {
      @{
        name = 'Ambient Cinematic'
        modules = @(
          @{ module = 'AMP'; model = 'clean-wide'; enabled = $ampEnabled; targets = @{ gain = 28; bass = 48; mid = 45; treble = 52 } }
          @{ module = 'CAB'; model = 'matched-clean-cab'; enabled = $cabEnabled; targets = @{ lowCut = 80; highCut = 7000 } }
          @{ module = 'MOD'; model = 'G-Chorus'; enabled = $true; targets = @{ depth = 32; rate = 18; mix = 28 } }
          @{ module = 'DLY'; model = 'stereo-delay'; enabled = $true; targets = @{ time = 480; feedback = 38; mix = 32 } }
          @{ module = 'RVB'; model = 'Hall'; enabled = $true; targets = @{ mix = 38; decay = 60 } }
          @{ module = 'VOL'; model = 'Volume'; enabled = $true; targets = @{ level = 50 } }
        )
      }
    }
    default {
      @{
        name = 'Edge Of Breakup'
        modules = @(
          @{ module = 'PRE'; model = 'Micro Boost'; enabled = $true; targets = @{ gain = 18; level = 58 } }
          @{ module = 'AMP'; model = 'edge-combo'; enabled = $ampEnabled; targets = @{ gain = 38; bass = 48; mid = 55; treble = 50; presence = 45 } }
          @{ module = 'CAB'; model = 'matched-open-back'; enabled = $cabEnabled; targets = @{ lowCut = 80; highCut = 6200 } }
          @{ module = 'EQ'; model = 'Guitar EQ'; enabled = $true; targets = @{ lowCut = 80; highCut = 6500; mid = 1 } }
          @{ module = 'DLY'; model = 'BB Delay'; enabled = $true; targets = @{ mix = 14; feedback = 22 } }
          @{ module = 'RVB'; model = 'Room'; enabled = $true; targets = @{ mix = 16; decay = 28 } }
        )
      }
    }
  }

  [ordered]@{
    schema = 'gp200.patchRecipe.v1'
    createdAt = (Get-Date).ToString('o')
    patch = $Brief.patch
    bank = $Brief.bank
    slot = $Brief.slot
    style = $Brief.style
    routing = $Brief.routing
    intendedUse = $Brief.intendedUse
    savePolicy = $Brief.savePolicy
    noCab = $noCab
    signalChain = $script:KnownModules
    template = $template.name
    modules = $template.modules
    validation = @(
      'editor-running',
      'window-foregrounded',
      'known-patch-edit-view',
      'target-patch-confirmed',
      'unsaved-change-policy-satisfied'
    )
  }
}

function New-GP200RefinedRecipe {
  param(
    [Parameter(Mandatory)] $Recipe,
    [Parameter(Mandatory)][string] $Feedback
  )

  $copy = $Recipe | ConvertTo-Json -Depth 12 | ConvertFrom-Json
  $copy | Add-Member -NotePropertyName refinedAt -NotePropertyValue (Get-Date).ToString('o') -Force
  $copy | Add-Member -NotePropertyName refinementFeedback -NotePropertyValue $Feedback -Force

  $feedbackValue = $Feedback.ToLowerInvariant()
  foreach ($module in $copy.modules) {
    if ($module.module -eq 'EQ') {
      if ($feedbackValue -match 'bright|harsh|ice') {
        if ($module.targets.PSObject.Properties.Name -contains 'highCut') {
          $module.targets.highCut = [Math]::Max(4500, [int]$module.targets.highCut - 700)
        }
      }
      if ($feedbackValue -match 'mud|boomy|dark') {
        if ($module.targets.PSObject.Properties.Name -contains 'lowCut') {
          $module.targets.lowCut = [Math]::Min(160, [int]$module.targets.lowCut + 20)
        }
      }
    }

    if ($module.module -eq 'RVB' -and $feedbackValue -match 'dry') {
      if ($module.targets.PSObject.Properties.Name -contains 'mix') {
        $module.targets.mix = [Math]::Min(45, [int]$module.targets.mix + 6)
      }
    }

    if ($module.module -eq 'NR' -and $feedbackValue -match 'noisy|noise|hiss') {
      if ($module.targets.PSObject.Properties.Name -contains 'threshold') {
        $module.targets.threshold = [Math]::Min(65, [int]$module.targets.threshold + 6)
      }
    }
  }

  $copy
}

function Invoke-GP200Takeover {
  param(
    [Parameter(Mandatory)][string] $Patch,
    [string] $Style = 'edge-of-breakup',
    [string] $Routing = 'headphones',
    [string] $OutputDir = 'output\gp200',
    [switch] $AllowMutation
  )

  $trace = New-Object System.Collections.Generic.List[object]
  $trace.Add((New-GP200LogEntry -Step 'start' -Status 'ok' -Data @{ patch = $Patch; allowMutation = [bool]$AllowMutation })) | Out-Null

  $session = Start-GP200Editor
  Set-GP200Foreground -Process $session.process
  $snapshot = Get-GP200WindowSnapshot -Process $session.process
  $surface = Get-GP200AutomationSurface

  $uiText = @()
  try {
    $uiText = @(Get-GP200UiText -Process $session.process -MaxDepth 4)
  } catch {
    $trace.Add((New-GP200LogEntry -Step 'uia-text' -Status 'warning' -Data @{ error = $_.Exception.Message })) | Out-Null
  }

  $knownView = Test-GP200KnownView -Snapshot $snapshot -UiText $uiText
  $brief = New-GP200ToneBrief -Patch $Patch -Style $Style -Routing $Routing -SavePolicy 'manual-confirm'
  $recipe = New-GP200PatchRecipe -Brief $brief

  $patchSeen = $false
  if ($uiText.Count -gt 0) {
    $patchSeen = [bool](@($uiText | Where-Object { $_.name -eq $Patch -or $_.name -like "*$Patch*" }).Count)
  }

  $status = if ($knownView.known -and ($patchSeen -or $uiText.Count -eq 0)) { 'ready' } else { 'needs-manual-confirmation' }

  $trace.Add((New-GP200LogEntry -Step 'session' -Status 'ok' -Data @{
    launched = $session.launched
    exePath = $session.exePath
    window = $snapshot
    automationSurface = $surface
  })) | Out-Null
  $trace.Add((New-GP200LogEntry -Step 'target-patch' -Status $status -Data @{
    patch = $Patch
    patchSeenInUiText = $patchSeen
    knownView = $knownView
  })) | Out-Null
  $executionPlan = Invoke-GP200RecipeExecution -Recipe $recipe -KnownView $knownView -AllowMutation:$AllowMutation
  $trace.Add((New-GP200LogEntry -Step 'recipe' -Status 'planned' -Data @{ recipe = $recipe; execution = $executionPlan })) | Out-Null

  if ($executionPlan.status -eq 'dry-run') {
    $trace.Add((New-GP200LogEntry -Step 'mutation' -Status 'skipped' -Data @{ reason = 'AllowMutation was not supplied; patch takeover is foreground/plan only.' })) | Out-Null
  } else {
    $trace.Add((New-GP200LogEntry -Step 'mutation' -Status 'blocked' -Data @{ reason = $executionPlan.reason })) | Out-Null
  }

  $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
  $safePatch = $Patch -replace '[^A-Za-z0-9-]', '_'
  $dir = Join-Path $OutputDir $safePatch
  if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
  }

  $recipePath = Join-Path $dir "$stamp-recipe.json"
  $summaryPath = Join-Path $dir "$stamp-summary.md"
  $tracePath = Join-Path $dir "$stamp-trace.json"

  $recipe | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $recipePath -Encoding UTF8
  Write-GP200Trace -Entries $trace.ToArray() -Path $tracePath

  $summary = @(
    "# GP-200 Patch Takeover Summary"
    ''
    ("- Patch: ``{0}``" -f $Patch)
    ("- Status: ``{0}``" -f $status)
    ("- Style: ``{0}``" -f $recipe.style)
    ("- Routing: ``{0}``" -f $recipe.routing)
    "- Mutation: ``skipped unless -AllowMutation is supplied``"
    ("- Editor: ``{0}`` PID ``{1}`` title ``{2}``" -f $snapshot.processName, $snapshot.id, $snapshot.mainWindowTitle)
    ("- Recipe: ``{0}``" -f $recipePath)
    ("- Trace: ``{0}``" -f $tracePath)
    ''
    "## Modules"
    ''
  )

  foreach ($module in $recipe.modules) {
    $summary += ("- ``{0}``: {1}, enabled={2}" -f $module.module, $module.model, $module.enabled)
  }

  $summary | Set-Content -LiteralPath $summaryPath -Encoding UTF8

  [ordered]@{
    status = $status
    patch = $Patch
    recipePath = (Resolve-Path -LiteralPath $recipePath).Path
    summaryPath = (Resolve-Path -LiteralPath $summaryPath).Path
    tracePath = (Resolve-Path -LiteralPath $tracePath).Path
    snapshot = $snapshot
    knownView = $knownView
  }
}

Export-ModuleMember -Function @(
  'Get-GP200ExePath',
  'Get-GP200Process',
  'Start-GP200Editor',
  'Set-GP200Foreground',
  'Get-GP200WindowSnapshot',
  'Get-GP200AutomationSurface',
  'Get-GP200UiText',
  'Test-GP200KnownView',
  'Test-GP200PatchId',
  'Test-GP200ModuleName',
  'New-GP200ModuleSelectionOperation',
  'New-GP200ModelSelectionOperation',
  'Test-GP200ParameterTargets',
  'New-GP200ParameterWriteOperation',
  'Convert-GP200RecipeToOperations',
  'Invoke-GP200RecipeExecution',
  'New-GP200ToneBrief',
  'ConvertTo-GP200Routing',
  'Normalize-GP200ToneStyle',
  'New-GP200PatchRecipe',
  'New-GP200RefinedRecipe',
  'Invoke-GP200Takeover',
  'Write-GP200Trace'
)
