## GNOME

https://github.com/user-attachments/assets/43485a87-a9a7-4221-a5d7-df082bb19041

## Hyprland

https://github.com/user-attachments/assets/acdf7d2c-8954-4740-a73c-a4460cd5ffea



# Fastfetch Anime Themes

A collection of Fastfetch themes with an interactive selector and sequential image display.

## 📋 Prerequisites

- **Fastfetch**: The main system information tool.
- **Gum**: (Optional) For the interactive theme selection menu.
- **ImageMagick**: (Optional) For automatic image padding adjustment.
- **Compatible terminal**: For image display.

## 🚀 Installation

1. **Clone the repository and move the content:**
   ```bash
   git clone https://github.com/CheikhNaro/ffthemes.git
   cd ffthemes
   mkdir -p ~/.config/fastfetch
   cp -rv * ~/.config/fastfetch/
   ```

2. **Make the scripts executable:**
   ```bash
   chmod +x ~/.config/fastfetch/fftheme.sh ~/.config/fastfetch/launch.sh
   ```

3. **Add aliases to your shell configuration:**
   Add the following lines to your `~/.bashrc` or `~/.zshrc`:
   ```bash
   alias fastfetchTheme="$HOME/.config/fastfetch/fftheme.sh"
   alias fft=fastfetchTheme
   alias ff="$HOME/.config/fastfetch/launch.sh"
   alias fastfetch='ff'
   ```

4. **Change theme:**
   ```bash
   fft
   ```

## 🛠️ Usage

- **`fft`** or **`fastfetchTheme`**: Open the theme selector.
- **`ff`** or **`fastfetch`**: Launch Fastfetch with a rotating image.

## ✨ Create your own theme

To create your own theme:
1. Go to `~/.config/fastfetch/themes`.
2. Create a new folder named after your theme (e.g., `dbz`).
3. Add your images inside this folder.

**Rules:**
- **Naming the theme's images:** Use the theme name followed by a number (e.g., `dbz1.png`, `dbz2.png`, `dbz3.png`, ...).
- **No Spaces:** Avoid spaces in folder or file names.
- **Formats:** Supported formats are PNG, GIF, JPG, JPEG, and WEBP.
- **Size:** Image height must not exceed **400px** (recommended: **350px** max).

To switch to your new theme, run `fastfetchTheme` or `fft` in your terminal.

