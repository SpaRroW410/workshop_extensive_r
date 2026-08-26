# Stops any static-server.ps1 instance listening on the given port.
# Companion to static-server.ps1 / start-workshop.bat — kept as its own
# .ps1 file (rather than an inline one-liner in the .bat) because
# HttpListener/http.sys always reports the owning PID to netstat as 4
# ("System"), so the real PID has to be found via WMI command-line
# matching instead.
param(
    [int]$Port
)

Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
    Where-Object {
        $_.CommandLine -like '*static-server.ps1*' -and
        $_.CommandLine -like "*-Port $Port*"
    } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
