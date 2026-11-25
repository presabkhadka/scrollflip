#!/bin/zsh
# Build ScrollFlip.app. Pass --install to copy it into ~/Applications.
set -euo pipefail
cd "$(dirname "$0")"

APP=build/ScrollFlip.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"

swiftc -O -target "$(uname -m)-apple-macos13" \
  Sources/*.swift \
  -framework AppKit -framework ServiceManagement \
  -o "$APP/Contents/MacOS/ScrollFlip"

cp Resources/Info.plist "$APP/Contents/Info.plist"
codesign -s - --force "$APP"
echo "Built $APP"

if [[ "${1:-}" == "--install" ]]; then
  mkdir -p ~/Applications
  pkill -x ScrollFlip 2>/dev/null || true
  rm -rf ~/Applications/ScrollFlip.app
  cp -R "$APP" ~/Applications/
  open ~/Applications/ScrollFlip.app
  echo "Installed to ~/Applications/ScrollFlip.app"
fi
