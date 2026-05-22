#!/bin/bash

CONFIG_DIR="$HOME/.config/fastfetch"
THEMES_DIR="$CONFIG_DIR/themes"
CONFIG_FILE="$CONFIG_DIR/config.jsonc"
THEME_FILE="$CONFIG_DIR/current_theme"
STATE_FILE="$CONFIG_DIR/current_state"

# ─── Thème par défaut ───
[ ! -f "$THEME_FILE" ] && echo "JujutsuKaisen" > "$THEME_FILE"

THEME=$(cat "$THEME_FILE")
THEME_DIR="$THEMES_DIR/$THEME"

if [ ! -d "$THEME_DIR" ]; then
    fastfetch
    exit 0
fi

# ─── Sélection séquentielle (PNG + GIF) ───
mapfile -t images < <(
    find "$THEME_DIR" -maxdepth 1 \( -name "*.png" -o -name "*.gif" \) -exec basename {} \; | sort -V
)

if [ ${#images[@]} -eq 0 ]; then
    fastfetch
    exit 0
fi

LAST=""
[ -f "$STATE_FILE" ] && LAST=$(cat "$STATE_FILE")

NEXT="${images[0]}"

if [ -n "$LAST" ]; then
    for i in "${!images[@]}"; do
        if [ "${images[$i]}" = "$LAST" ]; then
            NEXT="${images[$(( (i + 1) % ${#images[@]} ))]}"
            break
        fi
    done
fi

echo "$NEXT" > "$STATE_FILE"

IMAGE_SOURCE="~/.config/fastfetch/themes/$THEME/$NEXT"
IMAGE_PATH="$THEME_DIR/$NEXT"

# ─── Padding vertical ───
PAD_TOP=0

# Si l'image (PNG ou GIF) fait moins de 400px de haut → ajouter du padding pour centrer
# Pour les GIF animés, identify renvoie une ligne par frame → on prend la première
if command -v identify &>/dev/null; then
    IMG_H=$(identify -format "%h" "$IMAGE_PATH" 2>/dev/null | head -1)
    if [ -n "$IMG_H" ] && [ "$IMG_H" -lt 400 ]; then
        PAD_TOP=1
    fi
fi

# ─── Mise à jour config.jsonc ───
sed -i "s|\"source\": \".*\"|\"source\": \"$IMAGE_SOURCE\"|" "$CONFIG_FILE"
sed -i "s|\"top\": [0-9]*|\"top\": $PAD_TOP|" "$CONFIG_FILE"

fastfetch

