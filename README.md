# 🐧 Ubuntify-shell

Transform any Debian-based terminal and shell combo to look and feel identical to Ubuntu.

[![CI](https://github.com/Fleptor/Ubuntify-shell/actions/workflows/ci.yml/badge.svg)](https://github.com/Fleptor/Ubuntify-shell/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](LICENSE)
[![Shell: Bash](https://img.shields.io/badge/Shell-Bash-orange.svg)](https://www.gnu.org/software/bash/)

---

## ⚡ Quick Start

Run this one-liner in your terminal to instantly transform your shell:

```bash
curl -fsSL https://raw.githubusercontent.com/Fleptor/Ubuntify-shell/main/install.sh | bash
```

*Or using `wget`:*

```bash
wget -qO- https://raw.githubusercontent.com/Fleptor/Ubuntify-shell/main/install.sh | bash
```

---

## 🌟 What Ubuntify-shell Does

1. **Reverts Shell to Bash**:
   - Detects if your active or default shell is `zsh`, `fish`, or another shell.
   - Restores the default shell back to `bash` via `chsh`.
2. **Installs Ubuntu Font Family via APT**:
   - Updates APT and installs `fonts-ubuntu` and `fonts-ubuntu-console`.
   - Refreshes fontconfig cache (`fc-cache`).
3. **Injects Authentic Ubuntu `.bashrc` Configuration**:
   - Creates an automated timestamped backup of your existing `~/.bashrc`.
   - Configures Ubuntu's signature colorful prompt:
     ```text
     user@hostname:~/directory$
     ```
     *(Bold green user@host, white colon, bold blue working directory, white prompt)*
   - Enables terminal window title reporting (`user@host: dir`).
   - Configures `dircolors` for colorful `ls` and `grep`.
   - Adds Ubuntu's default aliases: `ll`, `la`, `l`, and `alert`.
4. **Environment-Aware Terminal Styling**:
   - Detects your active desktop environment and terminal emulator (GNOME, XFCE, MATE, KDE Konsole, Alacritty, Kitty, WSL/Windows Terminal).
   - Provides clear, step-by-step instructions (and copy-paste commands where supported) to set the Ubuntu Aubergine color palette and font.

---

## 🎨 Ubuntu Terminal Color & Font Reference

| Element | Hex Code | RGB | Description |
| :--- | :--- | :--- | :--- |
| **Background** | `#300A24` | `rgb(48, 10, 36)` | Iconic Ubuntu Aubergine / Deep Purple |
| **Foreground / Text** | `#FFFFFF` | `rgb(255, 255, 255)` | Crisp White (or `#EEEEEC` Light Grey) |
| **Cursor** | `#FFFFFF` | `rgb(255, 255, 255)` | White cursor |
| **Font Family** | `Ubuntu Mono` | Regular, Size 13 (or 12) | Official monospaced Ubuntu font |

### 16-Color ANSI Palette
```text
Normal Colors:
  Black:   #2E3436    Red:     #CC0000    Green:   #4E9A06    Yellow:  #C4A000
  Blue:    #3465A4    Magenta: #75507B    Cyan:    #06989A    White:   #D3D7CF

Bright Colors:
  BrBlack: #555753    BrRed:   #EF2929    BrGreen: #8AE234    BrYellow:#FCE94F
  BrBlue:  #729FCF    BrMag:   #AD7FA8    BrCyan:  #34E2E2    BrWhite: #EEEEEC
```

---

## 🖥️ Terminal Emulator Setup Guides

### 1. GNOME Terminal (Debian Default / Pop!_OS / Ubuntu)

#### Option A: One-Liner (dconf / gsettings)
```bash
profile=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d \')
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles/:$profile/ use-theme-colors false
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles/:$profile/ background-color '#300A24'
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles/:$profile/ foreground-color '#FFFFFF'
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles/:$profile/ font 'Ubuntu Mono 13'
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles/:$profile/ use-system-font false
```

#### Option B: Graphical Settings
1. Open GNOME Terminal and press the menu button (or right-click) ➔ **Preferences**.
2. Select your active profile under **Profiles**.
3. **Text** tab: Check **Custom font**, choose **Ubuntu Mono Regular**, size **13**.
4. **Colors** tab:
   - Uncheck **Use colors from system theme**.
   - Built-in schemes: **Ubuntu** (or set Background to `#300A24` and Text to `#FFFFFF`).

---

### 2. XFCE Terminal (Xubuntu / Debian XFCE)
1. Open XFCE Terminal ➔ **Edit** ➔ **Preferences**.
2. **Appearance** tab: Set font to **Ubuntu Mono 13**.
3. **Colors** tab:
   - Text color: `#FFFFFF`
   - Background color: `#300A24`
   - Palette: Choose **Ubuntu** or keep **Tango**.

---

### 3. MATE Terminal (Ubuntu MATE / Debian MATE)
1. Open MATE Terminal ➔ **Edit** ➔ **Profile Preferences**.
2. **General** tab: Uncheck *Use the system fixed width font*, select **Ubuntu Mono 13**.
3. **Colors** tab:
   - Uncheck *Use colors from system theme*.
   - Built-in schemes: **Ubuntu** (or Custom: Background `#300A24`, Foreground `#FFFFFF`).

---

### 4. KDE Konsole (Debian KDE / Kubuntu)
1. Open Konsole ➔ **Settings** ➔ **Configure Konsole** ➔ **Profiles**.
2. Click **Edit Current Profile**.
3. **Appearance** tab: Select font **Ubuntu Mono 13**.
4. Under **Color Scheme & Font**, select or create an Ubuntu profile:
   - Background: `#300A24`
   - Foreground: `#FFFFFF`

---

### 5. Windows Terminal (WSL)
1. Open Windows Terminal ➔ **Settings** (`Ctrl + ,`).
2. Under **Profiles**, select your Debian/WSL profile:
   - **Appearance** ➔ Font face: **Ubuntu Mono**, size **13**.
3. Under **Color schemes**, click **Add new**:
   - Name: `Ubuntu`
   - Background: `#300A24`
   - Foreground: `#FFFFFF`
4. Set the color scheme of your WSL profile to `Ubuntu` and click **Save**.

---

### 6. Alacritty (`~/.config/alacritty/alacritty.toml`)
```toml
[font]
normal = { family = "Ubuntu Mono", style = "Regular" }
size = 13.0

[colors.primary]
background = "#300A24"
foreground = "#FFFFFF"
```

---

### 7. Kitty (`~/.config/kitty/kitty.conf`)
```conf
font_family      Ubuntu Mono
font_size        13.0
background       #300A24
foreground       #FFFFFF
```

---

## 🔄 Reverting / Uninstalling

`install.sh` automatically creates a timestamped backup before touching your configuration (e.g. `~/.bashrc.ubuntify.bak.<timestamp>`).

To restore your previous `.bashrc`:

```bash
# Find your backup:
ls -la ~/.bashrc.ubuntify.bak.*

# Restore:
cp ~/.bashrc.ubuntify.bak.<timestamp> ~/.bashrc
source ~/.bashrc
```

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
