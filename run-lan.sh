#!/usr/bin/env bash
# Everything for a test with phones in the same Wi-Fi network, on macOS:
# HTTPS certificates for the Mac's address, the web build of the game, the admin panel, then
# Nakama + PostgreSQL + Caddy in Docker.
#
#   ./run-lan.sh                 address of en0 (Wi-Fi)
#   ./run-lan.sh 192.168.1.102   another address
#   ./run-lan.sh --skip-build    reuse build/web and admin/dist
set -euo pipefail

root="$(cd "$(dirname "$0")" && pwd)"
ip=""
build=true
for arg in "$@"; do
	case "$arg" in
		--skip-build) build=false ;;
		-h | --help) sed -n 2,9p "$0"; exit 0 ;;
		*) ip="$arg" ;;
	esac
done
if [[ -z "$ip" ]]; then
	ip="$(ipconfig getifaddr en0 || ipconfig getifaddr en1 || true)"
fi
if [[ -z "$ip" ]]; then
	echo "No Wi-Fi address found. Pass it: $0 192.168.x.x" >&2
	exit 1
fi
if [[ ! -f "$root/server/.env" ]]; then
	echo "server/.env is missing: cp server/.env.example server/.env and set the secrets." >&2
	exit 1
fi
if grep -q '^DEV_MODE=true' "$root/server/.env"; then
	echo "WARNING: DEV_MODE=true in server/.env. Dev RPCs hand out the office entry code to any player" >&2
	echo "         and let players move their clock and add coins. Set DEV_MODE=false for a real test." >&2
fi

"$root/tools/lan/make-certs.sh" "$ip"

if $build; then
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
	echo "Exporting the web build..."
	mkdir -p "$root/build/web"
	"$godot" --headless --path "$root/client" --export-release "Web" ../build/web/index.html >/dev/null
	echo "Building the admin panel..."
	if [[ ! -d "$root/admin/node_modules" ]]; then
		npm --prefix "$root/admin" ci
	fi
	npm --prefix "$root/admin" run build >/dev/null
fi

echo "Starting Nakama, PostgreSQL and Caddy..."
docker compose --project-directory "$root/server" -f "$root/server/docker-compose.yml" --profile lan up --build -d

cat <<EOF

Ready. On each phone in the same Wi-Fi network:
  1. Open http://$ip:8080 in Safari and install the certificate (steps are on the page).
  2. Game:  https://$ip:8443
     Admin: https://$ip:5443
Office screen on this Mac: ./run.sh --office-screen
If the phone cannot connect, allow incoming connections for Docker in the macOS firewall.
EOF
