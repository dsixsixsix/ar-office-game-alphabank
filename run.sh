#!/usr/bin/env bash
# Runs the Godot client on macOS, emulating a phone screen (counterpart of run.ps1).
#
#   ./run.sh                          Pixel 8
#   ./run.sh --device iphone_15
#   ./run.sh --device iphone_17_pro --screen-dpi 127
#   ./run.sh --office-screen          reception screen with the rotating presence QR code
set -euo pipefail

root="$(cd "$(dirname "$0")" && pwd)"
project="$root/client"
devices="pixel_8 iphone_15 iphone_17_pro iphone_17_pro_max galaxy_s24 android_hd iphone_se desktop"

device="pixel_8"
screen_dpi=""
office_screen=false

usage() {
	echo "Usage: $0 [--device <id>] [--screen-dpi <value>] [--office-screen]"
	echo "Devices: $devices"
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--device) device="${2:?}"; shift 2 ;;
		--screen-dpi) screen_dpi="${2:?}"; shift 2 ;;
		--office-screen) office_screen=true; shift ;;
		-h | --help) usage; exit 0 ;;
		*) usage >&2; exit 1 ;;
	esac
done

if [[ " $devices " != *" $device "* ]]; then
	echo "Unknown device '$device'." >&2
	usage >&2
	exit 1
fi

# Godot: tools/godot/Godot.app, then PATH, then /Applications.
godot=""
for candidate in "$root/tools/godot/Godot.app/Contents/MacOS/Godot" "$(command -v godot || true)" \
	"/Applications/Godot.app/Contents/MacOS/Godot"; do
	if [[ -n "$candidate" && -x "$candidate" ]]; then
		godot="$candidate"
		break
	fi
done
if [[ -z "$godot" ]]; then
	echo "Godot not found. Install Godot 4.7: brew install --cask godot" >&2
	exit 1
fi

if [[ ! -d "$project/.godot" ]]; then
	echo "First run: importing assets..."
	"$godot" --headless --path "$project" --import
fi

args=(--path "$project")
if $office_screen; then
	args+=(res://scenes/kiosk/office_screen.tscn --resolution 720x960)
elif [[ "$device" != "desktop" ]]; then
	args+=(-- "--device=$device")
	if [[ -n "$screen_dpi" ]]; then
		args+=("--screen-dpi=$screen_dpi")
	fi
fi

exec "$godot" "${args[@]}"
