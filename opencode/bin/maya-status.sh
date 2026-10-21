#!/bin/sh
# Is Maya actually ready for an agent to work in?
#
# Why this exists: three separate things have to be true before a modelling
# session can start, and each one fails in a way that looks like something else.
# Maya can be running with no commandPort, the port can be open on a MEL-only
# port that answers nothing useful, and the MCP health check can claim Maya is
# offline while it is fine. This asks the operating system instead of the MCP.
#
# Usage: maya-status.sh        (exit 0 = ready, 1 = not ready)
#
# Deliberately plain sh with lsof/pgrep/tail, so it works in any shell and has
# nothing to install.

PORT="${MAYA_MCP_PORT:-7001}"
LOG="$HOME/Library/Logs/Maya/maya-mcp-startup.log"
SCENES="$HOME/Documents/maya/projects/default/scenes"

ready=0
printf 'Maya preflight (port %s)\n' "$PORT"

# 1. Is the app running?
pid=$(pgrep -f "Maya.app/Contents/MacOS/Maya" | head -1)
if [ -n "$pid" ]; then
	printf '  process     running (pid %s)\n' "$pid"
else
	printf '  process     NOT running\n'
	printf '              start it with: open -a /Applications/Autodesk/maya2027/Maya.app\n'
fi

# 2. Is the port listening, and to whom?
listener=$(lsof -nP -iTCP:"$PORT" -sTCP:LISTEN 2>/dev/null | tail -1)
if [ -n "$listener" ]; then
	printf '  port        listening: %s\n' "$(echo "$listener" | awk '{print $1, $2}')"
else
	printf '  port        NOT listening\n'
	if [ -n "$pid" ]; then
		printf '              Maya is up, so this is the bind race. It retries for 120s on its own.\n'
		printf '              wait, then re-run this. Still nothing? Quit Maya fully (Cmd+Q, not a kill)\n'
		printf '              and relaunch; do not launch a second Maya over the first.\n'
	fi
fi

[ -n "$pid" ] && [ -n "$listener" ] && ready=1

# 3. A Python-capable port echoes real output only when nothing else holds it:
#    Maya's commandPort serves one client at a time, so while maya-mcp is
#    connected a second probe gets silence rather than an error. Silence proves
#    nothing by itself, and treating it as failure produced a NOT READY on a
#    perfectly working session. A live connection is the conclusive evidence.
if [ "$ready" = "1" ]; then
	established=$(lsof -nP -iTCP:"$PORT" 2>/dev/null | grep -c ESTABLISHED || true)
	if [ "${established:-0}" -gt 0 ]; then
		printf '  python port in use by %s live connection(s)\n' "$established"
	else
		probe=$(printf 'print("__preflight_ok__")\n' | nc -w 3 127.0.0.1 "$PORT" 2>/dev/null | tr -d '\000')
		case "$probe" in
		*__preflight_ok__*)
			printf '  python port answering (no client connected right now)\n'
			;;
		*)
			printf '  port open but nothing answered, and no client is connected\n'
			printf '              that is what a MEL-only port looks like; recreate it with\n'
			printf '              cmds.commandPort(name=":%s", sourceType="python", echoOutput=True)\n' "$PORT"
			;;
		esac
	fi
fi

# 4. What did the last launch actually do?
if [ -f "$LOG" ]; then
	printf '  last startup log lines:\n'
	tail -3 "$LOG" | sed 's/^/              /' | cut -c1-150
else
	printf '  last startup log lines: (no log yet)\n'
fi

# 5. Which scene will the agent see? Reopening is the agent's job, this is just
#    the file that exists on disk.
newest=$(ls -t "$SCENES"/*.ma 2>/dev/null | head -1)
if [ -n "$newest" ]; then
	printf '  newest scene %s\n' "$(basename "$newest")"
fi

if [ "$ready" = "1" ]; then
	printf 'READY\n'
	exit 0
fi
printf 'NOT READY\n'
exit 1
