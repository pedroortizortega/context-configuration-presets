# Install coding presets without replacing user files. Windows PowerShell 5.1+.
[CmdletBinding()]
param(
    [string]$Harness,
    [string]$Target,
    [switch]$DryRun,
    [switch]$Help
)
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$temporary = $null
$writing = $false
function Get-Attributes([string]$Path) {
    try { return [IO.File]::GetAttributes($Path) }
    catch [IO.FileNotFoundException] { return $null }
    catch [IO.DirectoryNotFoundException] { return $null }
}
function Assert-NoLink([string]$Path) {
    $attributes = Get-Attributes $Path
    if ($null -ne $attributes -and ($attributes -band [IO.FileAttributes]::ReparsePoint)) {
        throw "Reparse point (symlink/junction) is not supported: $Path"
    }
}
function Assert-DirectoryChain([string]$Path) {
    while ($Path) {
        Assert-NoLink $Path
        $attributes = Get-Attributes $Path
        if ($null -ne $attributes -and -not ($attributes -band [IO.FileAttributes]::Directory)) {
            throw "Directory conflict: $Path"
        }
        $Path = [IO.Path]::GetDirectoryName($Path)
    }
}
function Normalize-Path([string]$Path) {
    $Path = $Path.Replace('/', '\')
    if ($Path -notmatch '^[A-Za-z]:\\') { throw "Use a local drive path: $Path" }
    foreach ($part in $Path.Substring(3).Split('\')) {
        if ($part -eq '' -or $part -eq '.') { continue }
        if ($part -eq '..' -or $part -match '[<>:"|?*\x00-\x1f]' -or $part -match '[. ]$' -or
            $part -match '^(?i:CON|PRN|AUX|NUL|COM[0-9\u00b9\u00b2\u00b3]|LPT[0-9\u00b9\u00b2\u00b3])(?:\.|$)') {
            throw "Unsupported Windows path component: $part"
        }
    }
    $full = [IO.Path]::GetFullPath($Path)
    if ($full.Length -ge 240) { throw 'Paths must be shorter than 240 characters for Windows PowerShell compatibility.' }
    if ($full.Length -gt 3) { $full = $full.TrimEnd('\') }
    return $full
}
function Is-Within([string]$Path, [string]$Parent) {
    return $Path.Equals($Parent, [StringComparison]::OrdinalIgnoreCase) -or
        $Path.StartsWith($Parent.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)
}
function Collect([string]$Relative) {
    $source = Normalize-Path ([IO.Path]::Combine($script:sourceRoot, $Relative))
    Assert-NoLink $source
    $attributes = Get-Attributes $source
    if ($null -eq $attributes) { throw "Missing source: $source" }
    if ($attributes -band [IO.FileAttributes]::Directory) {
        $script:directories.Add($Relative)
        foreach ($child in [IO.Directory]::GetFileSystemEntries($source)) {
            Collect ([IO.Path]::Combine($Relative, [IO.Path]::GetFileName($child)))
        }
    } else {
        # Hashing checks readability before any destination writes.
        $hash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
        $script:files.Add([pscustomobject]@{ Relative = $Relative; Hash = $hash })
    }
}
try {
    if ($Help) {
        Write-Output @'
Usage: .\install.ps1 -Harness codex|claude -Target PROJECT_DIR [-DryRun]
Without arguments, prompts for the harness and project root.
Existing identical files are skipped; conflicting files abort before writes.
Local drive paths only; symlinks, junctions and parent traversal are rejected.
-DryRun validates without creating files or directories. -Help shows this help.
Requires Windows PowerShell 5.1 or PowerShell 7 on Windows.
'@
        exit 0
    }
    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { throw 'Use install.sh on non-Windows systems.' }
    if ($PSBoundParameters.Count -eq 0) {
        if ([Console]::IsInputRedirected -or [Environment]::GetCommandLineArgs() -contains '-NonInteractive') {
            throw 'No interactive input. Provide -Harness and -Target.'
        }
        $choice = Read-Host 'Harness: 1) Codex  2) Claude Code. Choose 1 or 2'
        switch ($choice) { '1' { $Harness = 'codex' }; '2' { $Harness = 'claude' }; default { throw 'Invalid harness.' } }
        $Target = Read-Host 'Project directory'
    }
    if ($Harness -notin @('codex', 'claude')) { throw 'Use -Harness codex or -Harness claude.' }
    $Harness = $Harness.ToLowerInvariant()
    if ([string]::IsNullOrWhiteSpace($Target)) { throw 'A nonempty -Target project directory is required.' }
    $Target = $Target.Replace('/', '\')
    if ($Target -notmatch '^[A-Za-z]:\\') {
        if ($Target -match '^[\\~]' -or $Target.Contains(':')) { throw 'UNC, device, drive-relative and tilde paths are not supported.' }
        if ((Get-Location).Provider.Name -ne 'FileSystem') { throw 'Run from a filesystem directory or use an absolute target.' }
        $Target = [IO.Path]::Combine((Get-Location).ProviderPath, $Target)
    }
    $Target = Normalize-Path $Target
    $repo = Normalize-Path $PSScriptRoot
    Assert-DirectoryChain $repo
    Assert-DirectoryChain $Target
    if ($Target -eq [IO.Path]::GetPathRoot($Target)) { throw 'Refusing drive root as target.' }
    if ($HOME -and $Target -eq (Normalize-Path $HOME)) { throw 'Choose a project directory, not your home directory.' }
    if ((Is-Within $Target $repo) -or (Is-Within $repo $Target)) { throw 'Target must not overlap the preset repository.' }
    if ([IO.Path]::GetFileName($Target) -in @('.codex', '.claude')) { throw 'Pass the project root, not the harness directory.' }
    foreach ($protected in @($env:SystemRoot, $env:ProgramFiles, ${env:ProgramFiles(x86)}, $env:ProgramData)) {
        if ($protected -and (Is-Within $Target (Normalize-Path $protected))) { throw "Refusing system directory: $Target" }
    }
    $sourceRoot = Normalize-Path ([IO.Path]::Combine($repo, 'coding'))
    Assert-DirectoryChain $sourceRoot
    $directories = New-Object 'System.Collections.Generic.List[string]'
    $files = New-Object 'System.Collections.Generic.List[object]'
    $pending = New-Object 'System.Collections.Generic.List[object]'
    $paths = @(".$Harness", 'deploy', 'openspec', 'ops', 'scripts\verify.sh', '.env.test.example', '.gitignore.extras', 'AGENTS.md', 'ORCHESTRATION.md', 'QUALITY_GATES.md')
    if ($Harness -eq 'claude') { $paths += 'CLAUDE.md' }
    foreach ($path in $paths) { Collect $path }
    $directories.Add('scripts')
    # Validate the entire manifest before creating even the target directory.
    foreach ($path in $directories) {
        Assert-DirectoryChain (Normalize-Path ([IO.Path]::Combine($Target, $path)))
    }
    foreach ($file in $files) {
        $destination = Normalize-Path ([IO.Path]::Combine($Target, $file.Relative))
        Assert-DirectoryChain ([IO.Path]::GetDirectoryName($destination))
        Assert-NoLink $destination
        $attributes = Get-Attributes $destination
        if ($null -ne $attributes) {
            if (($attributes -band [IO.FileAttributes]::Directory) -or
                (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash -ne $file.Hash) {
                throw "File conflict: $destination (back up or move it first)."
            }
        } else {
            if (([IO.Path]::GetDirectoryName($destination)).Length + 42 -ge 260) {
                throw "Insufficient path length for temporary file: $destination"
            }
            $pending.Add($file)
        }
    }
    Write-Output "Validated $Harness presets for $Target ($($pending.Count) new files)."
    if ($DryRun) { Write-Output 'Dry run: no changes made.'; exit 0 }
    $writing = $true
    Assert-DirectoryChain $Target
    [void][IO.Directory]::CreateDirectory($Target)
    foreach ($path in $directories) {
        $directory = [IO.Path]::Combine($Target, $path)
        Assert-DirectoryChain $directory
        [void][IO.Directory]::CreateDirectory($directory)
    }
    foreach ($file in $pending) {
        $source = [IO.Path]::Combine($sourceRoot, $file.Relative)
        $destination = [IO.Path]::Combine($Target, $file.Relative)
        $parent = [IO.Path]::GetDirectoryName($destination)
        Assert-DirectoryChain ([IO.Path]::GetDirectoryName($source))
        Assert-NoLink $source
        Assert-DirectoryChain $parent
        Assert-NoLink $destination
        $temporary = [IO.Path]::Combine($parent, ('.preset-' + [guid]::NewGuid().ToString('N')))
        [IO.File]::Copy($source, $temporary, $false)
        if ((Get-FileHash -LiteralPath $temporary -Algorithm SHA256).Hash -ne $file.Hash) { throw "Source changed during installation: $source" }
        # Same-directory rename publishes a complete file and refuses overwrite.
        [IO.File]::Move($temporary, $destination)
        $temporary = $null
    }
    Write-Output 'Installation complete. Existing files were preserved.'
    exit 0
} catch {
    [Console]::Error.WriteLine('Error: ' + $_.Exception.Message)
    if ($writing) { [Console]::Error.WriteLine('Some new files may remain. Resolve the error and retry.') }
    exit 1
} finally {
    if ($temporary -and [IO.File]::Exists($temporary)) { [IO.File]::Delete($temporary) }
}
