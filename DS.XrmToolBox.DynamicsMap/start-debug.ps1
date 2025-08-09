[CmdletBinding()]
param(
    [string]$Configuration = "Debug",
    # Optional: if provided, copy to this storage path instead of install path
    [string]$OverridePath,
    # Path to XrmToolBox.exe. If not provided, the script tries common paths.
    [string]$XtbExe = "C:\\Program Files (x86)\\XrmToolbox\\XrmToolBox.exe",
    # Kill a running XrmToolBox before copying files
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

function Write-Step($msg) { Write-Host "[>] $msg" -ForegroundColor Cyan }
function Write-Ok($msg) { Write-Host "[OK] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Warning $msg }
function Fail($msg) { Write-Error $msg; exit 1 }

function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
}

# Resolve paths
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectPath = Join-Path $ScriptRoot "DS.XrmToolBox.DynamicsMap.csproj"
$OutDir = Join-Path $ScriptRoot "bin\$Configuration\net48"
$PluginName = "DS.XrmToolBox.DynamicsMap"
$PluginDll = Join-Path $OutDir "$PluginName.dll"
$PluginPdb = Join-Path $OutDir "$PluginName.pdb"
$PluginDest = $null

# Try to find XrmToolBox.exe if not provided
function Resolve-XtbExe {
    param([string]$Hint)
    if ($Hint -and (Test-Path $Hint)) { return (Resolve-Path $Hint).Path }
    $pf86 = ${env:ProgramFiles(x86)}
    $pf64 = $env:ProgramFiles
    $local = $env:LOCALAPPDATA
    $candidates = @(
        # Typical per-user install
        (Join-Path $local 'Programs\XrmToolBox\XrmToolBox.exe'),
        # Machine-wide (both possible folder casings for dir and exe)
        (Join-Path $pf86 'XrmToolbox\XrmToolBox.exe'),
        (Join-Path $pf86 'XrmToolBox\XrmToolBox.exe'),
        (Join-Path $pf86 'XrmToolbox\XrmToolbox.exe'),
        (Join-Path $pf86 'XrmToolBox\XrmToolbox.exe'),
        (Join-Path $pf64 'XrmToolbox\XrmToolBox.exe'),
        (Join-Path $pf64 'XrmToolBox\XrmToolBox.exe'),
        (Join-Path $pf64 'XrmToolbox\XrmToolbox.exe'),
        (Join-Path $pf64 'XrmToolBox\XrmToolbox.exe')
    ) | Where-Object { $_ -and $_.Trim() -ne '' }

    Write-Verbose "Probing for XrmToolBox.exe in:"
    foreach ($c in $candidates) {
        Write-Verbose "  - $c"
        if (Test-Path $c) { return $c }
    }
    return $null
}

if (-not (Test-Path $ProjectPath)) {
    Fail "csproj not found at $ProjectPath"
}

# Optional: stop running XrmToolBox
$xtbProc = Get-Process -Name "XrmToolBox" -ErrorAction SilentlyContinue
if ($xtbProc) {
    if ($Force) {
        Write-Warn "XrmToolBox is running; stopping it (Force)."
        $xtbProc | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 500
    }
    else {
        Fail "XrmToolBox is running. Close it or re-run with -Force."
    }
}

Write-Step "Building $PluginName ($Configuration)"
& dotnet build $ProjectPath -c $Configuration | Write-Host
if ($LASTEXITCODE -ne 0) { Fail "Build failed" }
if (-not (Test-Path $PluginDll)) { Fail "Plugin DLL not found: $PluginDll" }

# Resolve XrmToolBox.exe
if (-not $XtbExe) { $XtbExe = Resolve-XtbExe -Hint $XtbExe }
if (-not $XtbExe) {
    Fail "Could not locate XrmToolBox.exe. Provide -XtbExe with the full path."
}
if (-not (Test-Path $XtbExe)) { Fail "XrmToolBox.exe not found: $XtbExe" }
$XtbDir = Split-Path -Parent $XtbExe

# Decide destination: override path if provided; otherwise use storage path
if ($OverridePath) {
    $PluginDest = Join-Path $OverridePath "Plugins\$PluginName"
}
else {
    $storageRoot = Join-Path $env:APPDATA "MscrmTools\XrmToolBox"
    $PluginDest = Join-Path $storageRoot "Plugins\$PluginName"
}

# Elevate if writing to Program Files without admin (based on destination)
$needsAdmin = $false
if ($PluginDest -match "^(?i)c:\\program files") {
    $needsAdmin = $true
}

if ($needsAdmin -and -not (Test-IsAdmin)) {
    Write-Warn "Elevation required to write into: $PluginDest"
    $argList = @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", (Resolve-Path $MyInvocation.MyCommand.Path).Path,
        "-Configuration", $Configuration
    )
    if ($Force) { $argList += "-Force" }
    if ($XtbExe) { $argList += @("-XtbExe", $XtbExe) }
    # No OverridePath on purpose -> writes to install Plugins
    Start-Process powershell.exe -Verb RunAs -ArgumentList $argList
    return
}

Write-Step "Preparing plugin folder: $PluginDest"
New-Item -ItemType Directory -Force -Path $PluginDest | Out-Null

Write-Step "Copying plugin outputs"
Copy-Item $PluginDll -Destination $PluginDest -Force
if (Test-Path $PluginPdb) {
    Copy-Item $PluginPdb -Destination $PluginDest -Force
}

# Don’t copy Microsoft.* or XrmToolBox.* assemblies; the host provides them
# If you add private dependencies later, copy them here explicitly.

if ($OverridePath) {
    Write-Step "Starting XrmToolBox with override path: $OverridePath"
    New-Item -ItemType Directory -Force -Path $OverridePath | Out-Null
    $arguments = "/overridepath:$OverridePath"
    Start-Process -FilePath $XtbExe -ArgumentList $arguments -WorkingDirectory $XtbDir
}
else {
    Write-Step "Starting XrmToolBox (installed path)"
    Start-Process -FilePath $XtbExe -WorkingDirectory $XtbDir
}

Write-Ok "Launched XrmToolBox. Search 'Dynamics Map' in Tool Library."
