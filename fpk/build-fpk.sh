#!/usr/bin/env bash
set -euo pipefail
VERSION="${1:?usage: build-fpk.sh VERSION [UPTAG]}"
UPTAG="${2:-}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="dsh-desktop"
WORK="$(mktemp -d)"
PKG="$WORK/pkg"
mkdir -p "$PKG"/{cmd,config,app/ui/images,app/www,wizard} "$ROOT/dist"

# manifest
sed "s/@VERSION@/$VERSION/; s/@UPTAG@/$UPTAG/" "$ROOT/fpk/manifest-template" > "$PKG/manifest"

# icon from upstream repo
ICON="/tmp/dsh-app-icon.png"
curl -sfL "https://raw.githubusercontent.com/anywhere-labs/dsh-desktop/master/dsh-plugin-desktop/build/app-icon.png" -o "$ICON" \
  || curl -sfL "https://raw.githubusercontent.com/anywhere-labs/dsh-desktop/master/assets/desktop-hero-zh.png" -o "$ICON" \
  || echo "icon download failed"
if command -v convert >/dev/null 2>&1 && [ -s "$ICON" ]; then
  convert "$ICON" -resize 64x64 "$PKG/ICON.PNG"
  convert "$ICON" -resize 256x256 "$PKG/ICON_256.PNG"
  convert "$ICON" -resize 256x256 "$PKG/app/ui/images/icon_256.png"
  convert "$ICON" -resize 64x64 "$PKG/app/ui/images/icon_64.png"
else
  [ -s "$ICON" ] && cp "$ICON" "$PKG/ICON.PNG" && cp "$ICON" "$PKG/ICON_256.PNG" \
    && cp "$ICON" "$PKG/app/ui/images/icon_256.png" && cp "$ICON" "$PKG/app/ui/images/icon_64.png"
fi

# compose with baked image tag
sed "s/@IMAGETAG@/v$VERSION/" "$ROOT/fpk/compose-template.yml" > "$PKG/app/docker-compose.yml"

# cmd scripts
for f in main install_callback uninstall_callback config_callback upgrade_callback; do
  cp "$ROOT/fpk/cmd-$f" "$PKG/cmd/$f"
done
for f in install_init uninstall_init upgrade_init config_init; do
  printf '#!/bin/bash\nexit 0\n' > "$PKG/cmd/$f"
done

# ui
cp "$ROOT/fpk/ui-index-cgi" "$PKG/app/ui/index.cgi"
cat > "$PKG/app/ui/config" <<EOF
{
  ".url": {
    "dsh-desktop.Application": {
      "title": "DSH 桌面",
      "icon": "images/icon_{0}.png",
      "type": "iframe",
      "url": "/cgi/ThirdParty/dsh-desktop/index.cgi/",
      "allUsers": true
    }
  }
}
EOF

# config
cat > "$PKG/config/privilege" <<'EOF'
{
  "defaults": {
    "run-as": "root"
  }
}
EOF
echo '{"shared_folders": []}' > "$PKG/config/resource"

# wizard
cp "$ROOT/fpk/wizard-install.json" "$PKG/wizard/install"
echo '[]' > "$PKG/wizard/config"

chmod +x "$PKG"/cmd/* "$PKG/app/ui/index.cgi"

OUT="$ROOT/dist/DSH桌面_v${VERSION}.fpk"
tar -czf "$OUT" -C "$PKG" .
echo "built: $OUT"
