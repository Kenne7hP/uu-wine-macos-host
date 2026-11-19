#!/bin/bash
set -eu
umask 077
: "${WINEPREFIX:?Set WINEPREFIX to the dedicated UU prefix}"
: "${UU_WINE_BIN:?Set UU_WINE_BIN to the patched Wine bin directory}"
if [[ "$WINEPREFIX" != /* || "$UU_WINE_BIN" != /* ]]; then
    echo "Use absolute paths for WINEPREFIX and UU_WINE_BIN." >&2
    exit 1
fi
export WINEPREFIX WINEDEBUG=-all MVK_CONFIG_LOG_LEVEL=0
export WINEDLLOVERRIDES='winemenubuilder.exe=d;msvcp140=n,b'
root="$(cd "$(dirname "$0")" && pwd -P)"
payload="$WINEPREFIX/drive_c/Program Files/Netease/GameViewer/bin"
capture="$root/build/uu-capture"
if [[ ! -x "$capture" || ! -x "$UU_WINE_BIN/wine" || ! -x "$UU_WINE_BIN/wineserver" ||
      ! -f "$payload/GameViewer.exe" || ! -f "$payload/GameViewerServer.exe" ]]; then
    echo "Build the capture helper and install UU into the dedicated prefix first." >&2
    exit 1
fi
lock="$WINEPREFIX/.uu-wine-host"
if ! mkdir "$lock"; then
    echo "The host is already running or a previous run left the lock directory." >&2
    exit 1
fi
publisher=
wine_started=
export UU_TEST_FRAME_FILE="$lock/desktop"
cleanup() {
    if [[ -n "$publisher" ]]; then kill "$publisher" 2>/dev/null || true; wait "$publisher" 2>/dev/null || true; fi
    if [[ -n "$wine_started" ]]; then "$UU_WINE_BIN/wineserver" -k || true; fi
    rm -f "$UU_TEST_FRAME_FILE"
    rmdir "$lock"
}
trap cleanup EXIT
trap 'exit 0' INT TERM
"$capture" "$UU_TEST_FRAME_FILE" &
publisher=$!
sleep 1
kill -0 "$publisher" 2>/dev/null || { echo "Desktop capture did not start." >&2; exit 1; }
cd "$payload"
wine_started=1
"$UU_WINE_BIN/wine" sc query GameViewerService >/dev/null
UU_MAC_INPUT=desktop "$UU_WINE_BIN/wine" GameViewerServer.exe &
server=$!
"$UU_WINE_BIN/wine" GameViewer.exe &
while kill -0 "$server" 2>/dev/null && kill -0 "$publisher" 2>/dev/null; do sleep 2; done
