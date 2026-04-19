[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [ValidateSet('status', 'takeover', 'plan', 'refine', 'self-test')]
  [string] $Command,

  [string] $Patch = '42-A',
  [string] $Style = 'edge-of-breakup',
  [string] $Routing = 'headphones',
  [string] $Feedback = '',
  [string] $OutputDir = 'output\gp200',
  [switch] $AllowMutation
)

Set-StrictMode -Version Latest

$modulePath = Join-Path $PSScriptRoot 'GP200.Automation.psm1'
Import-Module $modulePath -Force -DisableNameChecking

try {
  switch ($Command) {
    'status' {
      $process = Get-GP200Process
      if (-not $process) {
        [ordered]@{
          status = 'not-running'
          exePath = Get-GP200ExePath
        } | ConvertTo-Json -Depth 8
        exit 0
      }

      $surface = Get-GP200AutomationSurface
      $snapshot = Get-GP200WindowSnapshot -Process $process
      $uiText = @()
      $uiError = $null
      try {
        $uiText = @(Get-GP200UiText -Process $process -MaxDepth 4)
      } catch {
        $uiError = $_.Exception.Message
      }

      [ordered]@{
        status = 'running'
        exePath = Get-GP200ExePath
        snapshot = $snapshot
        automationSurface = $surface
        knownView = Test-GP200KnownView -Snapshot $snapshot -UiText $uiText
        uiTextCount = $uiText.Count
        uiTextError = $uiError
      } | ConvertTo-Json -Depth 12
    }

    'takeover' {
      Invoke-GP200Takeover -Patch $Patch -Style $Style -Routing $Routing -OutputDir $OutputDir -AllowMutation:$AllowMutation |
        ConvertTo-Json -Depth 12
    }

    'plan' {
      $brief = New-GP200ToneBrief -Patch $Patch -Style $Style -Routing $Routing
      New-GP200PatchRecipe -Brief $brief | ConvertTo-Json -Depth 12
    }

    'refine' {
      if (-not $Feedback) {
        throw 'Feedback is required for refine. Example: -Feedback "too bright"'
      }
      $brief = New-GP200ToneBrief -Patch $Patch -Style $Style -Routing $Routing
      $recipe = New-GP200PatchRecipe -Brief $brief
      New-GP200RefinedRecipe -Recipe $recipe -Feedback $Feedback | ConvertTo-Json -Depth 12
    }

    'self-test' {
      $tests = New-Object System.Collections.Generic.List[object]

      foreach ($patchId in @('42-A', '1-D', '099-C')) {
        $parsed = Test-GP200PatchId -Patch $patchId
        $tests.Add([ordered]@{ name = "parse-$patchId"; passed = ($parsed.patch -eq $patchId) }) | Out-Null
      }

      foreach ($routing in @('FRFR', 'headphones', 'interface', 'amp front', 'amp return', '4CM')) {
        $brief = New-GP200ToneBrief -Patch '42-A' -Style 'clean' -Routing $routing
        $recipe = New-GP200PatchRecipe -Brief $brief
        $tests.Add([ordered]@{
          name = "recipe-routing-$routing"
          passed = ($recipe.routing -eq (ConvertTo-GP200Routing -Routing $routing)) -and ($recipe.modules.Count -gt 0)
        }) | Out-Null
      }

      foreach ($style in @('clean', 'edge-of-breakup', 'modern high gain', 'ambient')) {
        $brief = New-GP200ToneBrief -Patch '42-A' -Style $style -Routing 'headphones'
        $recipe = New-GP200PatchRecipe -Brief $brief
        $operations = Convert-GP200RecipeToOperations -Recipe $recipe
        $tests.Add([ordered]@{
          name = "recipe-style-$style"
          passed = ($recipe.modules.Count -gt 0) -and ($recipe.patch -eq '42-A') -and ($operations.Count -ge $recipe.modules.Count)
        }) | Out-Null
      }

      $baseRecipe = New-GP200PatchRecipe -Brief (New-GP200ToneBrief -Patch '42-A' -Style 'edge-of-breakup' -Routing 'headphones')
      $refinedRecipe = New-GP200RefinedRecipe -Recipe $baseRecipe -Feedback 'too bright'
      $tests.Add([ordered]@{
        name = 'refine-too-bright'
        passed = ($refinedRecipe.refinementFeedback -eq 'too bright') -and ($refinedRecipe.modules.Count -gt 0)
      }) | Out-Null

      $failed = @($tests | Where-Object { -not $_.passed })
      [ordered]@{
        status = if ($failed.Count -eq 0) { 'passed' } else { 'failed' }
        total = $tests.Count
        failed = $failed.Count
        tests = $tests.ToArray()
      } | ConvertTo-Json -Depth 10

      if ($failed.Count -gt 0) {
        exit 1
      }
    }
  }
} catch {
  [ordered]@{
    status = 'error'
    message = $_.Exception.Message
    command = $Command
  } | ConvertTo-Json -Depth 8
  exit 1
}
