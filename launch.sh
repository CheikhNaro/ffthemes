#!/bin/bash

CONFIG_DIR="$HOME/.config/fastfetch"
THEMES_DIR="$CONFIG_DIR/themes"
CONFIG_FILE="$CONFIG_DIR/config.jsonc"
THEME_FILE="$CONFIG_DIR/current_theme"
STATE_FILE="$CONFIG_DIR/current_state"
FIXED_FLAG="$CONFIG_DIR/.fixed_logo"

# ─── Thème par défaut si inexistant ───
[ ! -f "$THEME_FILE" ] && echo "JujutsuKaisen" > "$THEME_FILE"
THEME=$(cat "$THEME_FILE" 2>/dev/null || echo "JujutsuKaisen")

# ─── Fonction de détection du type de logo et lancement ───
run_fastfetch() {
    local source_path="$1"
    shift
    local resolved="${source_path/#\~/$HOME}"
    local logo_type="file"

    if [ -z "$resolved" ] || [ ! -f "$resolved" ]; then
        fastfetch "$@"
        return
    fi

    # 1. Vérifier si c'est du texte / ASCII (.txt, .ascii ou mime text/*)
    if [[ "$resolved" == *.txt || "$resolved" == *.ascii ]]; then
        logo_type="file"
    elif [[ $(file --mime-type -b "$resolved" 2>/dev/null) == text/* ]]; then
        logo_type="file"
    else
        # 2. C'est une image (PNG, JPG, WEBP, GIF...)
        if [[ -n "$KITTY_WINDOW_ID" || "$TERM" == "xterm-kitty" ]]; then
            logo_type="kitty"
        elif [[ "$TERM_PROGRAM" == "WezTerm" || -n "$WEZTERM_PANE" || "$TERM" == "wezterm" ]]; then
            logo_type="kitty"
        elif [[ "$TERM_PROGRAM" == "ghostty" || "$TERM" == "xterm-ghostty" ]]; then
            logo_type="kitty"
        elif [[ "$TERM" == "foot" || "$TERM" == foot-* ]]; then
            logo_type="sixel"
        else
            if command -v chafa &>/dev/null; then
                logo_type="chafa"
            else
                logo_type="sixel"
            fi
        fi
    fi

    fastfetch --logo "$resolved" --logo-type "$logo_type" "$@"
}

# ─── Mode logo fixe : pas de rotation ───
if [ -f "$FIXED_FLAG" ]; then
    # Si le thème vient d'être changé (par exemple via fftheme.sh) alors qu'on est en mode fixe,
    # on initialise la source avec le 1er élément du nouveau thème
    if [ ! -f "$STATE_FILE" ]; then
        if [ "$THEME" = "asciiart" ]; then
            ASCII_DIR="$THEMES_DIR/ascii"
            mapfile -t ascii_files < <(find "$ASCII_DIR" -maxdepth 1 -name "*.txt" -exec basename {} \; 2>/dev/null | sort -V)
            if [ ${#ascii_files[@]} -gt 0 ]; then
                FIRST_ASCII="${ascii_files[0]}"
                echo "$FIRST_ASCII" > "$STATE_FILE"
                sed -i -E "s|\"source\": [^,]+,?|\"source\": \"~/.config/fastfetch/themes/ascii/$FIRST_ASCII\",|" "$CONFIG_FILE"
                sed -i -E "s|\"top\": [0-9]+|\"top\": 1|" "$CONFIG_FILE"
            fi
        else
            THEME_DIR="$THEMES_DIR/$THEME"
            if [ -d "$THEME_DIR" ]; then
                mapfile -t images < <(find "$THEME_DIR" -maxdepth 1 \( -name "*.png" -o -name "*.gif" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.webp" \) -exec basename {} \; 2>/dev/null | sort -V)
                if [ ${#images[@]} -gt 0 ]; then
                    FIRST_IMG="${images[0]}"
                    echo "$FIRST_IMG" > "$STATE_FILE"
                    sed -i -E "s|\"source\": [^,]+,?|\"source\": \"~/.config/fastfetch/themes/$THEME/$FIRST_IMG\",|" "$CONFIG_FILE"
                fi
            fi
        fi
    fi

    CURRENT_SOURCE=$(grep '"source":' "$CONFIG_FILE" | head -1 | sed -E 's/.*"source": "([^"]+)".*/\1/')
    run_fastfetch "$CURRENT_SOURCE" "$@"
    exit 0
fi

# ─── Mode rotation : Thème asciiart (sélection séquentielle parmi les .txt) ───
if [ "$THEME" = "asciiart" ]; then
    ASCII_DIR="$THEMES_DIR/ascii"
    mapfile -t ascii_files < <(find "$ASCII_DIR" -maxdepth 1 -name "*.txt" -exec basename {} \; 2>/dev/null | sort -V)
    if [ ${#ascii_files[@]} -gt 0 ]; then
        LAST_ASCII=""
        [ -f "$STATE_FILE" ] && LAST_ASCII=$(cat "$STATE_FILE")
        NEXT_ASCII="${ascii_files[0]}"
        if [ -n "$LAST_ASCII" ]; then
            for i in "${!ascii_files[@]}"; do
                if [ "${ascii_files[$i]}" = "$LAST_ASCII" ]; then
                    NEXT_ASCII="${ascii_files[$(( (i + 1) % ${#ascii_files[@]} ))]}"
                    break
                fi
            done
        fi
        echo "$NEXT_ASCII" > "$STATE_FILE"
        ASCII_SOURCE="~/.config/fastfetch/themes/ascii/$NEXT_ASCII"
        sed -i -E "s|\"source\": [^,]+,?|\"source\": \"$ASCII_SOURCE\",|" "$CONFIG_FILE"
    fi
    sed -i -E "s|\"top\": [0-9]+|\"top\": 1|" "$CONFIG_FILE"
    run_fastfetch "$ASCII_SOURCE" "$@"
    exit 0
fi

# ─── Mode rotation : Thème images (sélection séquentielle PNG + GIF + JPG + WEBP) ───
THEME_DIR="$THEMES_DIR/$THEME"

if [ ! -d "$THEME_DIR" ]; then
    fastfetch "$@"
    exit 0
fi

mapfile -t images < <(
    find "$THEME_DIR" -maxdepth 1 \( -name "*.png" -o -name "*.gif" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.webp" \) -exec basename {} \; 2>/dev/null | sort -V
)

if [ ${#images[@]} -eq 0 ]; then
    fastfetch "$@"
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

if command -v identify &>/dev/null; then
    IMG_H=$(identify -format "%h" "$IMAGE_PATH" 2>/dev/null | head -1)
    if [ -n "$IMG_H" ] && [[ "$IMG_H" =~ ^[0-9]{1,5}$ ]] && [ "$IMG_H" -lt 400 ]; then
        PAD_TOP=1
    fi
fi

# ─── Mise à jour config.jsonc ───
sed -i -E "s|\"source\": [^,]+,?|\"source\": \"$IMAGE_SOURCE\",|" "$CONFIG_FILE"
sed -i -E "s|\"top\": [0-9]+|\"top\": $PAD_TOP|" "$CONFIG_FILE"
sed -i -E "s|\"right\": [0-9]+|\"right\": 1|" "$CONFIG_FILE"

# ─── Lancement ───
run_fastfetch "$IMAGE_SOURCE" "$@"
