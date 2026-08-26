# Exits 0 if something is already listening on 127.0.0.1:$Port, else 1.
# Companion to start-workshop.bat.
param(
    [int]$Port
)

try {
    $c = New-Object Net.Sockets.TcpClient
    $c.Connect('127.0.0.1', $Port)
    $c.Close()
    exit 0
} catch {
    exit 1
}
