#!/usr/bin/env bash
# ==============================================================================
# Ubuntify-shell
# Transform any Debian-based terminal + shell combo to look identical to Ubuntu
# https://github.com/Fleptor/Ubuntify-shell
# ==============================================================================

# Formatting and color helpers
BOLD='\033[1m'
NC='\033[0m' # No Color
UBUNTU_PURPLE='\033[38;2;119;41;83m'
UBUNTU_ORANGE='\033[38;2;233;84;32m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'

# Fallback for terminals that don't support truecolor
if [ "$(tput colors 2>/dev/null || echo 0)" -lt 256 ]; then
    UBUNTU_PURPLE='\033[0;35m'
    UBUNTU_ORANGE='\033[1;31m'
fi

print_banner() {
    cat << "EOF"
  _   _ _                 _   _  __             _          _ _ 
 | | | | |               | | (_)/ _|           | |        | | |
 | | | | |__  _   _ _ __ | |_ _| |_ _   _ _____| |__   ___| | |
 | | | | '_ \| | | | '_ \| __| |  _| | | |______| '_ \ / _ \ | |
 | |_| | |_) | |_| | | | | |_| | | | |_| |      | | | |  __/ | |
  \___/|_.__/ \__,_|_| |_|\__|_|_|  \__, |      |_| |_|\___|_|_|
                                     __/ |                      
                                    |___/                       
EOF
    echo -e "${UBUNTU_ORANGE}  Debian-to-Ubuntu Shell & Terminal Styling Suite${NC}\n"
}

# Determine target user and user home
CURRENT_USER="${SUDO_USER:-$USER}"
if [ -z "$CURRENT_USER" ]; then
    CURRENT_USER="$(id -un)"
fi

USER_HOME="$(getent passwd "$CURRENT_USER" 2>/dev/null | cut -d: -f6)"
if [ -z "$USER_HOME" ] || [ ! -d "$USER_HOME" ]; then
    USER_HOME="$HOME"
fi

print_banner

echo -e "${BOLD}${CYAN}Target User:${NC} $CURRENT_USER (Home: $USER_HOME)"
echo -e "${BOLD}${CYAN}Current OS:${NC}   $(grep -E '^PRETTY_NAME=' /etc/os-release 2>/dev/null | cut -d= -f2- | tr -d '"' || uname -s)"
echo ""

# ------------------------------------------------------------------------------
# 1. Shell Check & Revert to Bash
# ------------------------------------------------------------------------------
echo -e "${BOLD}--- [1/3] Shell Verification & Reversion ---${NC}"
USER_SHELL="$(getent passwd "$CURRENT_USER" 2>/dev/null | cut -d: -f7)"
if [ -z "$USER_SHELL" ]; then
    USER_SHELL="${SHELL:-/bin/sh}"
fi

SHELL_BASE="$(basename "$USER_SHELL")"
BASH_PATH="$(command -v bash 2>/dev/null || echo "/bin/bash")"

if [ "$SHELL_BASE" = "bash" ]; then
    echo -e "${GREEN}[✓]${NC} Default shell is already Bash ($USER_SHELL)."
else
    echo -e "${YELLOW}[!]${NC} Default shell is currently '${SHELL_BASE}' ($USER_SHELL)."
    echo -e "${CYAN}[*]${NC} Reverting default shell back to Bash ($BASH_PATH)..."
    
    REVERTED=0
    if [ "$(id -u)" -eq 0 ]; then
        if chsh -s "$BASH_PATH" "$CURRENT_USER" 2>/dev/null; then
            REVERTED=1
        fi
    elif command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
        if sudo chsh -s "$BASH_PATH" "$CURRENT_USER" 2>/dev/null; then
            REVERTED=1
        fi
    fi

    if [ $REVERTED -eq 1 ]; then
        echo -e "${GREEN}[✓]${NC} Default shell successfully changed to $BASH_PATH."
        echo -e "    ${YELLOW}(Note: Log out and back in for shell change to take full effect)${NC}"
    else
        # In non-interactive curl pipes, chsh might need explicit user password
        echo -e "${YELLOW}[i]${NC} Could not automatically switch shell non-interactively."
        echo -e "    Please run: ${WHITE}chsh -s $BASH_PATH${NC}"
    fi
fi
echo ""

# ------------------------------------------------------------------------------
# 2. APT Package Installation (Ubuntu Fonts)
# ------------------------------------------------------------------------------
echo -e "${BOLD}--- [2/3] Package Installation via APT ---${NC}"
if command -v apt-get >/dev/null 2>&1; then
    echo -e "${GREEN}[+]${NC} APT package manager detected."
    
    SUDO_PREFIX=""
    if [ "$(id -u)" -ne 0 ]; then
        if command -v sudo >/dev/null 2>&1; then
            SUDO_PREFIX="sudo"
        fi
    fi

    echo -e "${CYAN}[*]${NC} Refreshing package lists..."
    $SUDO_PREFIX apt-get update -qq || true

    echo -e "${CYAN}[*]${NC} Installing Ubuntu font packages (fonts-ubuntu, fonts-ubuntu-console)..."
    if ! $SUDO_PREFIX apt-get install -y -qq fonts-ubuntu fonts-ubuntu-console 2>/dev/null; then
        echo -e "${YELLOW}[!]${NC} Multi-package install failed, trying individually..."
        $SUDO_PREFIX apt-get install -y -qq fonts-ubuntu 2>/dev/null || \
            echo -e "${YELLOW}[!]${NC} fonts-ubuntu not in current repositories (enable contrib/non-free if on Debian)."
        $SUDO_PREFIX apt-get install -y -qq fonts-ubuntu-console 2>/dev/null || true
    fi

    if command -v fc-cache >/dev/null 2>&1; then
        echo -e "${CYAN}[*]${NC} Updating font cache..."
        fc-cache -f >/dev/null 2>&1 || true
    fi
    echo -e "${GREEN}[✓]${NC} Font installation process completed."
else
    echo -e "${YELLOW}[!]${NC} APT package manager not detected on this system."
    echo -e "    If you are on an independent distro, install 'fonts-ubuntu' via your package manager."
fi
echo ""

# ------------------------------------------------------------------------------
# 3. Ubuntu Prompt & .bashrc Configuration
# ------------------------------------------------------------------------------
echo -e "${BOLD}--- [3/3] Ubuntu .bashrc Prompt & Aliases ---${NC}"
TARGET_BASHRC="$USER_HOME/.bashrc"
MARKER_START="# === UBUNTIFY SHELL CONFIGURATION START ==="
MARKER_END="# === UBUNTIFY SHELL CONFIGURATION END ==="

# Backup existing .bashrc if it exists
if [ -f "$TARGET_BASHRC" ]; then
    BACKUP_FILE="${TARGET_BASHRC}.ubuntify.bak.$(date +%Y%m%d_%H%M%S)"
    cp "$TARGET_BASHRC" "$BACKUP_FILE"
    echo -e "${GREEN}[✓]${NC} Existing .bashrc backed up to: ${WHITE}$BACKUP_FILE${NC}"
else
    touch "$TARGET_BASHRC"
fi

# Clean out any previous Ubuntify block
if grep -q "$MARKER_START" "$TARGET_BASHRC" 2>/dev/null; then
    echo -e "${CYAN}[*]${NC} Updating previous Ubuntify configuration block..."
    TMP_CLEAN="$(mktemp)"
    sed "/$MARKER_START/,/$MARKER_END/d" "$TARGET_BASHRC" > "$TMP_CLEAN"
    cat "$TMP_CLEAN" > "$TARGET_BASHRC"
    rm -f "$TMP_CLEAN"
fi

# Append authentic Ubuntu prompt, colors and aliases
cat >> "$TARGET_BASHRC" << 'UBUNTU_BASHRC'

# === UBUNTIFY SHELL CONFIGURATION START ===
# Authentic Ubuntu bash configuration: prompt, colors, and standard aliases

# Enable color support
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# Force colored prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        color_prompt=yes
    else
        color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    # Classic Ubuntu green user@host in bold, blue path
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# Set terminal window title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# Enable color support for ls, grep and dircolors
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Ubuntu standard bash aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# History configuration matching Ubuntu defaults
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s histappend
shopt -s checkwinsize
# === UBUNTIFY SHELL CONFIGURATION END ===
UBUNTU_BASHRC

# Restore ownership if run with sudo
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    chown "$CURRENT_USER:" "$TARGET_BASHRC" 2>/dev/null || true
fi

echo -e "${GREEN}[✓]${NC} Ubuntu PS1 prompt, colors & aliases injected into ${WHITE}$TARGET_BASHRC${NC}."
echo ""

# ------------------------------------------------------------------------------
# 4. System Detection & Step-by-Step Terminal Tutorial
# ------------------------------------------------------------------------------
detect_environment() {
    # Check desktop environments and running terminals
    if [ -n "$WSL_DISTRO_NAME" ] || grep -qi "microsoft" /proc/version 2>/dev/null; then
        echo "WSL (Windows Terminal)"
        return
    fi
    if [ "$TERM_PROGRAM" = "iTerm.app" ] || [ "$TERM_PROGRAM" = "Apple_Terminal" ]; then
        echo "macOS Terminal"
        return
    fi
    if [ "$TERM_PROGRAM" = "Alacritty" ] || pgrep -x alacritty >/dev/null 2>&1; then
        echo "Alacritty"
        return
    fi
    if [ "$TERM_PROGRAM" = "kitty" ] || pgrep -x kitty >/dev/null 2>&1; then
        echo "Kitty"
        return
    fi
    if pgrep -x tilix >/dev/null 2>&1; then
        echo "Tilix"
        return
    fi
    if pgrep -x xfce4-terminal >/dev/null 2>&1 || [ "$XDG_CURRENT_DESKTOP" = "XFCE" ]; then
        echo "XFCE Terminal"
        return
    fi
    if pgrep -x mate-terminal >/dev/null 2>&1 || [ "$XDG_CURRENT_DESKTOP" = "MATE" ]; then
        echo "MATE Terminal"
        return
    fi
    if pgrep -x konsole >/dev/null 2>&1 || [ "$XDG_CURRENT_DESKTOP" = "KDE" ]; then
        echo "KDE Konsole"
        return
    fi
    if pgrep -x gnome-terminal-server >/dev/null 2>&1 || [ "$XDG_CURRENT_DESKTOP" = "GNOME" ] || [ -n "$GNOME_DESKTOP_SESSION_ID" ]; then
        echo "GNOME Terminal"
        return
    fi
    echo "General / Other"
}

DETECTED_ENV="$(detect_environment)"

echo -e "${BOLD}========================================================================${NC}"
echo -e "${BOLD}${UBUNTU_ORANGE}           UBUNTU TERMINAL COLOR & FONT SETUP GUIDE                     ${NC}"
echo -e "${BOLD}========================================================================${NC}"
echo -e "${CYAN}Detected Environment:${NC} ${BOLD}${WHITE}$DETECTED_ENV${NC}\n"

echo -e "${BOLD}Official Ubuntu Terminal Specifications:${NC}"
echo -e "  • ${BOLD}Font:${NC}              Ubuntu Mono Regular, Size 13 (or 12)"
echo -e "  • ${BOLD}Background Color:${NC}  #300A24  (Aubergine / Deep Purple - rgb(48, 10, 36))"
echo -e "  • ${BOLD}Text / Foreground:${NC} #FFFFFF  (Crisp White - rgb(255, 255, 255))"
echo -e "  • ${BOLD}Cursor Color:${NC}       #FFFFFF"
echo ""

case "$DETECTED_ENV" in
    "GNOME Terminal")
        cat << "EOF"
  [Step-by-step for GNOME Terminal]
  1. Open Terminal -> Hamburger Menu (or right-click) -> Preferences.
  2. Under 'Profiles', select your active profile.
  3. [Text Tab]:
     - Check 'Custom font' and select 'Ubuntu Mono Regular', Size 13.
  4. [Colors Tab]:
     - Uncheck 'Use colors from system theme'.
     - Set 'Built-in schemes' to 'Ubuntu' (or choose Custom).
     - Text color:       #FFFFFF
     - Background color: #300A24
  
  [Quick One-Liner Option (via dconf/gsettings)]:
  If you have dconf enabled, run:
    profile=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d \')
    gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles/:$profile/ use-theme-colors false
    gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles/:$profile/ background-color '#300A24'
    gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles/:$profile/ foreground-color '#FFFFFF'
    gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles/:$profile/ font 'Ubuntu Mono 13'
    gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles/:$profile/ use-system-font false
EOF
        ;;

    "XFCE Terminal")
        cat << "EOF"
  [Step-by-step for XFCE Terminal]
  1. Open Terminal -> Edit -> Preferences.
  2. [Appearance Tab]:
     - Font: Click font picker and select 'Ubuntu Mono', Size 13.
  3. [Colors Tab]:
     - Text Color:       #FFFFFF
     - Background Color: #300A24
     - Color Palette: Choose 'Ubuntu' if listed, or keep Tango.
EOF
        ;;

    "MATE Terminal")
        cat << "EOF"
  [Step-by-step for MATE Terminal]
  1. Open Terminal -> Edit -> Profile Preferences.
  2. [General Tab]:
     - Uncheck 'Use the system fixed width font'.
     - Font: Select 'Ubuntu Mono', Size 13.
  3. [Colors Tab]:
     - Uncheck 'Use colors from system theme'.
     - Built-in schemes: Choose 'Ubuntu' or Custom.
     - Foreground Color: #FFFFFF
     - Background Color: #300A24
EOF
        ;;

    "KDE Konsole")
        cat << "EOF"
  [Step-by-step for KDE Konsole]
  1. Settings -> Configure Konsole -> Profiles -> Edit Current Profile.
  2. [Appearance Tab]:
     - Font: Choose 'Ubuntu Mono', Size 13.
     - Color Scheme & Font: Click 'New' or 'Edit'.
     - Set Background color to #300A24 and Foreground color to #FFFFFF.
EOF
        ;;

    "Alacritty")
        cat << "EOF"
  [Step-by-step for Alacritty (~/.config/alacritty/alacritty.toml)]
  Add or update the following sections:

  [font]
  normal = { family = "Ubuntu Mono", style = "Regular" }
  size = 13.0

  [colors.primary]
  background = "#300A24"
  foreground = "#FFFFFF"
EOF
        ;;

    "Kitty")
        cat << "EOF"
  [Step-by-step for Kitty (~/.config/kitty/kitty.conf)]
  Add or update the following lines:

  font_family      Ubuntu Mono
  font_size        13.0
  background       #300A24
  foreground       #FFFFFF
EOF
        ;;

    "WSL (Windows Terminal)")
        cat << "EOF"
  [Step-by-step for Windows Terminal]
  1. Open Windows Terminal -> Settings (Ctrl + ,).
  2. Under 'Profiles', select your Debian/WSL profile:
     - Appearance -> Font face: Select 'Ubuntu Mono' (Size 13).
  3. Under 'Color schemes', add a new scheme 'Ubuntu':
     - Background: #300A24
     - Foreground: #FFFFFF
  4. Assign the 'Ubuntu' color scheme to your profile and click Save.
EOF
        ;;

    *)
        cat << "EOF"
  [Generic Step-by-Step for Any Terminal]
  1. Open your terminal emulator's Preferences / Settings dialog.
  2. Set Font to:
     - Family: Ubuntu Mono (Regular)
     - Size:   13 pt (or 12 pt)
  3. Set Colors to:
     - Background: #300A24  (Aubergine - rgb(48, 10, 36))
     - Text:       #FFFFFF  (White - rgb(255, 255, 255))
     - Cursor:     #FFFFFF
EOF
        ;;
esac

echo ""
echo -e "${BOLD}16-Color Ubuntu ANSI Palette Reference:${NC}"
echo -e "  Black:   #2E3436   Red:     #CC0000   Green:   #4E9A06   Yellow:  #C4A000"
echo -e "  Blue:    #3465A4   Magenta: #75507B   Cyan:    #06989A   White:   #D3D7CF"
echo -e "  BrBlack: #555753   BrRed:   #EF2929   BrGreen: #8AE234   BrYellow:#FCE94F"
echo -e "  BrBlue:  #729FCF   BrMagenta:#AD7FA8  BrCyan:  #34E2E2   BrWhite: #EEEEEC"
echo ""

echo -e "${BOLD}${GREEN}========================================================================${NC}"
echo -e "${BOLD}${GREEN}   Ubuntify complete! Reload your shell: ${WHITE}source ~/.bashrc${GREEN} or open a new terminal.${NC}"
echo -e "${BOLD}${GREEN}========================================================================${NC}"
