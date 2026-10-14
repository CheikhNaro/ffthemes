#!/bin/bash

CONFIG_DIR="$HOME/.config/fastfetch"
FIXED_FLAG="$CONFIG_DIR/.fixed_logo"
STATE_FILE="$CONFIG_DIR/current_state"
THEME_FILE="$CONFIG_DIR/current_theme"
CONFIG_FILE="$CONFIG_DIR/config.jsonc"
LAUNCH="$CONFIG_DIR/launch.sh"

# Si un chemin de logo est passé en paramètre
if [ -n "$1" ]; then
    CUSTOM_LOGO="$1"
    RESOLVED="${CUSTOM_LOGO/#\~/$HOME}"
    if [ ! -f "$RESOLVED" ]; then
        echo "❌ Fichier introuvable : $CUSTOM_LOGO"
        exit 1
    fi

    # Mettre à jour config.jsonc avec le logo choisi
    sed -i -E "s|\"source\": [^,]+,?|\"source\": \"$CUSTOM_LOGO\",|" "$CONFIG_FILE"
    touch "$FIXED_FLAG"
    echo "📌 Logo fixe défini et activé : $CUSTOM_LOGO"
    exec "$LAUNCH"
fi

if [ -f "$FIXED_FLAG" ]; then
    rm -f "$FIXED_FLAG"
    echo "🔄 Logo UnPinned"
else
    touch "$FIXED_FLAG"
    echo "📌 Logo Pinned"
fi

exec "$LAUNCH"