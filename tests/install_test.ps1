# Standalone Windows regression checks; no Pester dependency.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { throw 'Run these tests on Windows.' }
$repo = Split-Path $PSScriptRoot -Parent
$engine = (Get-Process -Id $PID).Path
$root = Join-Path ([IO.Path]::GetTempPath()) ('preset-tests-' + [guid]::NewGuid().ToString('N'))
$fixture = Join-Path $root 'fixture'
[void][IO.Directory]::CreateDirectory($fixture)
function Assert($condition, $message) { if (-not $condition) { throw $message } }
function Run($code, [string[]]$arguments) {
    $ErrorActionPreference = 'Continue'
    $output = & $engine -NoProfile -NonInteractive -File (Join-Path $fixture 'install.ps1') @arguments 2>&1
    $ErrorActionPreference = 'Stop'
    Assert ($LASTEXITCODE -eq $code) ("Expected exit $code, got ${LASTEXITCODE}: $output")
}
try {
    Copy-Item -LiteralPath (Join-Path $repo 'install.ps1') -Destination $fixture
    Copy-Item -LiteralPath (Join-Path $repo 'coding') -Destination $fixture -Recurse -Force
    $target = Join-Path $root 'project [literal] with spaces'
    Run 0 @('-Help')
    Run 1 @('-Harness', 'invalid', '-Target', $target)
    Run 1 @('-Harness', 'codex')
    Run 1 @('-UnknownOption')
    Run 1 @()
    Run 0 @('-Harness', 'codex', '-Target', $target, '-DryRun')
    Assert (-not [IO.Directory]::Exists($target)) 'Dry run wrote destination.'
    Push-Location $root
    try { Run 0 @('-Harness', 'codex', '-Target', '.\project [literal] with spaces') } finally { Pop-Location }
    Assert ([IO.File]::Exists((Join-Path $target '.codex\config.toml'))) 'Missing Codex config.'
    Assert (-not [IO.Directory]::Exists((Join-Path $target '.claude'))) 'Copied other harness.'
    $before = (Get-Item -LiteralPath (Join-Path $target 'AGENTS.md')).LastWriteTimeUtc
    Run 0 @('-Harness', 'codex', '-Target', $target)
    Assert ((Get-Item -LiteralPath (Join-Path $target 'AGENTS.md')).LastWriteTimeUtc -eq $before) 'Reinstall rewrote file.'
    $claude = Join-Path $root 'claude'
    Run 0 @('-Harness', 'claude', '-Target', $claude)
    Assert ([IO.File]::Exists((Join-Path $claude 'CLAUDE.md'))) 'Missing Claude constitution.'
    Assert (-not [IO.Directory]::Exists((Join-Path $claude '.codex'))) 'Copied Codex with Claude.'
    $conflict = Join-Path $root 'conflict'
    [void][IO.Directory]::CreateDirectory($conflict)
    [IO.File]::WriteAllText((Join-Path $conflict 'QUALITY_GATES.md'), 'custom')
    Run 1 @('-Harness', 'codex', '-Target', $conflict)
    Assert (-not [IO.Directory]::Exists((Join-Path $conflict '.codex'))) 'Conflict caused partial copy.'
    Assert ([IO.File]::ReadAllText((Join-Path $conflict 'QUALITY_GATES.md')) -eq 'custom') 'Overwrote conflict.'
    foreach ($unsafe in @($fixture, $root, $HOME, [IO.Path]::GetPathRoot($root), (Join-Path $root '..\escape'), (Join-Path $root '.codex'), (Join-Path $root 'trailing.'), (Join-Path $root 'NUL'), '\\server\share\project')) {
        Run 1 @('-Harness', 'codex', '-Target', $unsafe, '-DryRun')
    }
    $collision = Join-Path $root 'directory-collision'
    [void][IO.Directory]::CreateDirectory((Join-Path $collision 'AGENTS.md'))
    Run 1 @('-Harness', 'codex', '-Target', $collision)
    Assert (-not [IO.Directory]::Exists((Join-Path $collision '.codex'))) 'Directory collision caused writes.'
    $linkedProject = Join-Path $root 'linked-project'
    [void][IO.Directory]::CreateDirectory($linkedProject)
    $linkedConfig = Join-Path $linkedProject '.codex'
    New-Item -ItemType Junction -Path $linkedConfig -Target $target | Out-Null
    try { Run 1 @('-Harness', 'codex', '-Target', $linkedProject) }
    finally { [IO.Directory]::Delete($linkedConfig) }
    $junction = Join-Path $root 'junction'
    New-Item -ItemType Junction -Path $junction -Target $target | Out-Null
    try { Run 1 @('-Harness', 'codex', '-Target', (Join-Path $junction 'child'), '-DryRun') }
    finally { [IO.Directory]::Delete($junction) }
    $sourceLink = Join-Path $fixture 'coding\.codex\linked'
    New-Item -ItemType Junction -Path $sourceLink -Target $target | Out-Null
    try { Run 1 @('-Harness', 'codex', '-Target', (Join-Path $root 'source-link'), '-DryRun') }
    finally { [IO.Directory]::Delete($sourceLink) }
    Remove-Item -LiteralPath (Join-Path $fixture 'coding\QUALITY_GATES.md')
    $missing = Join-Path $root 'missing-source'
    Run 1 @('-Harness', 'codex', '-Target', $missing)
    Assert (-not [IO.Directory]::Exists($missing)) 'Missing source caused writes.'
    Write-Host 'All PowerShell installer regression checks passed.'
}
finally { Remove-Item -LiteralPath $root -Recurse -Force }
