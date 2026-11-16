# no-sleep (Windows): block sleep while this Claude Code session is running.
# A hidden PowerShell holds SetThreadExecutionState and exits when the session
# (or its terminal tab) closes.
param([string]$Cmd = 'on')
$ErrorActionPreference = 'Stop'

$dir = Join-Path $HOME '.claude\no-sleep'
New-Item -ItemType Directory -Force -Path $dir | Out-Null

function Get-Proc($id) { Get-CimInstance Win32_Process -Filter "ProcessId=$id" -ErrorAction SilentlyContinue }

# Walk up to the Claude Code process; fall back to the shell that started this script.
function Get-SessionPid {
  $self = Get-Proc $PID
  $p = $self
  for ($i = 0; $p -and $i -lt 30; $i++) {
    if ($p.Name -eq 'claude.exe' -or ($p.Name -eq 'node.exe' -and $p.CommandLine -match 'claude')) { return [int]$p.ProcessId }
    $p = Get-Proc $p.ParentProcessId
  }
  return [int]$self.ParentProcessId
}

$sid = Get-SessionPid
$file = Join-Path $dir "$sid.pid"

function Stop-Lock {
  if (Test-Path $file) {
    Stop-Process -Id ([int](Get-Content $file)) -Force -ErrorAction SilentlyContinue
    Remove-Item $file -Force
  }
}

switch ($Cmd) {
  'on' {
    Stop-Lock
    $code = @"
`$t = Add-Type -Name K -Namespace NoSleep -PassThru -MemberDefinition '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint f);'
[void]`$t::SetThreadExecutionState([uint32]2147483649)
Wait-Process -Id $sid -ErrorAction SilentlyContinue
"@
    $enc = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($code))
    $w = Start-Process powershell.exe -WindowStyle Hidden -PassThru `
      -ArgumentList '-NoProfile', '-NonInteractive', '-EncodedCommand', $enc
    Set-Content -Path $file -Value $w.Id
    Write-Output "ON: no sleep until session $sid ends"
  }
  'off' {
    Stop-Lock
    Write-Output 'OFF: sleep allowed again'
  }
  'status' {
    $n = 0
    Get-ChildItem $dir -Filter *.pid | ForEach-Object {
      $s = $_.BaseName
      if ((Get-Process -Id $s -ErrorAction SilentlyContinue) -and
          (Get-Process -Id ([int](Get-Content $_.FullName)) -ErrorAction SilentlyContinue)) {
        Write-Output "- session $s$(if ($s -eq "$sid") { ' (this session)' })"; $n++
      } else { Remove-Item $_.FullName -Force }
    }
    if ($n -eq 0) { Write-Output 'No sessions are blocking sleep.' }
  }
  default { Write-Error 'usage: no-sleep.ps1 [on|off|status]'; exit 1 }
}
