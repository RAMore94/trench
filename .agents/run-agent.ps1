[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]
  [ValidateSet('planner','executor','reviewer')]
  [string]$Role
)

# Local Trench daily-agent runner.
# Invoked by Windows Task Scheduler at 7am / 11am / 1pm America/Edmonton.
# Pulls latest, runs `claude -p` with the role's prompt, then pushes anything the agent committed.

$ErrorActionPreference = 'Continue'
$RepoDir   = 'C:\Users\Aaron\Desktop\Trench'
$ClaudeExe = 'C:\Users\Aaron\AppData\Roaming\npm\claude.cmd'
$LogDir    = Join-Path $RepoDir '.agents\logs'

if (-not (Test-Path $RepoDir))   { Write-Error "Repo dir missing: $RepoDir"; exit 1 }
if (-not (Test-Path $ClaudeExe)) { Write-Error "Claude CLI missing: $ClaudeExe"; exit 1 }
$null = New-Item -ItemType Directory -Path $LogDir -Force

$ts       = Get-Date -Format 'yyyy-MM-ddTHH-mm-ss'
$LogFile  = Join-Path $LogDir "$ts-$Role.log"

Set-Location $RepoDir

function Log([string]$line) { $line | Tee-Object -FilePath $LogFile -Append }

Log "=== $Role at $ts ==="
Log "=== git pull ==="
git pull origin master 2>&1 | ForEach-Object { Log $_ }

$PromptFile = Join-Path $RepoDir ".agents\$Role.md"
if (-not (Test-Path $PromptFile)) {
  Log "ERROR: prompt file not found at $PromptFile"
  exit 1
}
$Prompt = Get-Content $PromptFile -Raw

Log "=== claude run ==="
& $ClaudeExe -p $Prompt --permission-mode bypassPermissions --add-dir $RepoDir 2>&1 |
  ForEach-Object { Log $_ }
$ClaudeExit = $LASTEXITCODE
Log "claude exit code: $ClaudeExit"

Log "=== git status ==="
git status --short 2>&1 | ForEach-Object { Log $_ }

Log "=== git push (safety net) ==="
git push origin master 2>&1 | ForEach-Object { Log $_ }

Log "=== done ==="
exit $ClaudeExit
