#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# serve.sh — preview rendered Quarto output locally
#
#   bash serve.sh              # start default servers: _site on 8080, docs on 8081
#   bash serve.sh <dir> <port> # start one server for a specific dir/port
#   bash serve.sh stop         # stop every server started by this script
#   bash serve.sh stop <port>  # stop just the server on that port
#
# Uses a small standalone PowerShell static file server (scripts/static-server.ps1)
# rather than `quarto preview`, since quarto only allows one preview per
# project — a second call would silently kill the first instead of serving
# a second directory.
# ═══════════════════════════════════════════════════════════════

set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PS1_SCRIPT="$ROOT_DIR/scripts/static-server.ps1"
LOG_DIR="$ROOT_DIR/.serve-pids"
mkdir -p "$LOG_DIR"

# Find real Windows PID(s) of running static-server.ps1 processes for a port.
# (HttpListener uses http.sys in kernel mode, so netstat/Get-NetTCPConnection
# always report the owning process as PID 4 "System" — command-line matching
# via WMI/CIM is the only reliable way to find our actual process.)
find_pids() {
  local port="$1"
  local filter='static-server.ps1'
  if [ -n "$port" ]; then
    powershell -NoProfile -Command "
      (Get-CimInstance Win32_Process -Filter \"Name='powershell.exe'\" |
        Where-Object { \$_.CommandLine -like '*$filter*' -and \$_.CommandLine -like '*-Port $port*' } |
        Select-Object -ExpandProperty ProcessId) -join ' '
    " | tr -d '\r'
  else
    powershell -NoProfile -Command "
      (Get-CimInstance Win32_Process -Filter \"Name='powershell.exe'\" |
        Where-Object { \$_.CommandLine -like '*$filter*' } |
        Select-Object -ExpandProperty ProcessId) -join ' '
    " | tr -d '\r'
  fi
}

port_responds() {
  local port="$1"
  timeout 2 bash -c "(exec 3<>/dev/tcp/127.0.0.1/$port) 2>/dev/null && exec 3<&-"
}

stop_port() {
  local port="$1"
  local pids
  pids="$(find_pids "$port")"
  if [ -z "$pids" ]; then
    echo "  ⚠️  No tracked server running on port $port"
    return 0
  fi
  for pid in $pids; do
    if taskkill //F //PID "$pid" > /dev/null 2>&1; then
      echo "  🛑 Stopped server on port $port (PID $pid)"
    fi
  done
}

if [ "$1" == "stop" ]; then
  if [ -n "$2" ]; then
    stop_port "$2"
  else
    pids="$(find_pids "")"
    if [ -z "$pids" ]; then
      echo "  No servers currently running."
    else
      for pid in $pids; do
        if taskkill //F //PID "$pid" > /dev/null 2>&1; then
          echo "  🛑 Stopped server (PID $pid)"
        fi
      done
    fi
  fi
  exit 0
fi

start_server() {
  local dir="$1"
  local port="$2"

  if [ ! -d "$dir" ]; then
    echo "  ❌ ERROR: directory '$dir' does not exist. Render it first."
    return 1
  fi

  if port_responds "$port"; then
    echo "  ℹ️  Already running → http://localhost:$port/"
    return 0
  fi

  nohup powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden \
    -File "$PS1_SCRIPT" -Root "$dir" -Port "$port" \
    > "$LOG_DIR/$port.log" 2>&1 &
  disown

  sleep 2
  if port_responds "$port"; then
    echo "  ✅ Serving $dir → http://localhost:$port/"
  else
    echo "  ❌ ERROR: server on port $port failed to start. Log:"
    cat "$LOG_DIR/$port.log" 2>/dev/null
    return 1
  fi
}

if [ -n "$1" ] && [ -n "$2" ]; then
  start_server "$1" "$2"
else
  echo "Starting default preview servers..."
  start_server "$ROOT_DIR/_site" 8080
  start_server "$ROOT_DIR/docs" 8081
fi

echo ""
echo "Stop anytime with: bash serve.sh stop"
