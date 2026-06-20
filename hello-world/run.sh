#!/bin/zsh
# Compile and run the Playdate game in the Simulator, capturing the console log.
#
# Why `script`: the Simulator copies print()/errors to stdout (per the SDK docs),
# but when stdout is a plain pipe it's fully-buffered and nothing appears until the
# buffer fills. Running under `script` gives it a pseudo-TTY (line-buffered), so the
# log streams to LOG in near-real-time. Read LOG to see game print() output and any
# runtime errors without copy-pasting from the Simulator's Console pane.

set -e
HERE="${0:A:h}"
SIM="/Users/aeagle/Developer/PlaydateSDK/bin/Playdate Simulator.app/Contents/MacOS/Playdate Simulator"
LOG="/tmp/playdate_sim.log"

cd "$HERE"
pkill -9 -f "MacOS/Playdate Simulator" 2>/dev/null || true
pdc source HelloWorld.pdx
echo "compiled -> HelloWorld.pdx ; log -> $LOG"
: > "$LOG"
exec script -q "$LOG" "$SIM" HelloWorld.pdx
