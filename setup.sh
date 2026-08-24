#!/bin/sh
set -eu

readonly DOTFILES_RAW_BASE_URL="https://raw.githubusercontent.com/harleyjwilson/dotfiles-minimal/main"
staging_directory=""

cleanup_staging_directory() {
    if [ -n "$staging_directory" ]; then
        rm -rf "$staging_directory"
    fi
}

fail_setup() {
    printf 'Setup failed: %s\n' "$*" >&2
    exit 1
}

case "$(uname -s)" in
    Darwin) ;;
    *) fail_setup "this setup script supports macOS only" ;;
esac

script_directory=""
case "$0" in
    setup.sh|*/setup.sh)
        if [ -f "$0" ]; then
            script_directory=$(CDPATH= cd "$(dirname "$0")" && pwd)
        fi
        ;;
esac

if [ -n "$script_directory" ] && [ -r "$script_directory/Brewfile" ]; then
    dotfiles_directory=$script_directory
else
    staging_directory=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-spouse.XXXXXX")
    trap cleanup_staging_directory EXIT HUP INT TERM

    printf 'Downloading dotfiles from %s\n' "$DOTFILES_RAW_BASE_URL"
    curl -fsSL "$DOTFILES_RAW_BASE_URL/Brewfile" -o "$staging_directory/Brewfile"
    dotfiles_directory=$staging_directory
fi

printf 'Copying %s/Brewfile to %s/Brewfile\n' "$dotfiles_directory" "$HOME"
cp "$dotfiles_directory/Brewfile" "$HOME/Brewfile"

if ! command -v brew >/dev/null 2>&1; then
    printf 'Homebrew not found. Installing Homebrew...\n'
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if ! command -v brew >/dev/null 2>&1; then
    if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    else
        fail_setup "Homebrew was installed but brew is not available in this shell"
    fi
fi

printf 'Installing dependencies from %s/Brewfile\n' "$HOME"
brew bundle --file="$HOME/Brewfile"

apply_terminal_always_close_setting() {
    terminal_profile_name=$(defaults read com.apple.Terminal "Default Window Settings" 2>/dev/null || printf '%s' "Basic")
    escaped_terminal_profile_name=$(printf '%s' "$terminal_profile_name" | sed 's/\\/\\\\/g; s/"/\\"/g')
    terminal_preferences=$(mktemp "${TMPDIR:-/tmp}/com.apple.Terminal.XXXXXX")

    if ! defaults export com.apple.Terminal "$terminal_preferences" >/dev/null 2>&1; then
        rm -f "$terminal_preferences"
        fail_setup "could not export Terminal preferences; open Terminal once, then rerun setup"
    fi

    terminal_profile_path=":\"Window Settings\":\"$escaped_terminal_profile_name\":shellExitAction"
    if ! /usr/libexec/PlistBuddy -c "Set $terminal_profile_path 1" "$terminal_preferences" >/dev/null 2>&1; then
        if ! /usr/libexec/PlistBuddy -c "Add $terminal_profile_path integer 1" "$terminal_preferences" >/dev/null 2>&1; then
            rm -f "$terminal_preferences"
            fail_setup "could not update the Terminal shell exit setting"
        fi
    fi

    if ! defaults import com.apple.Terminal "$terminal_preferences" >/dev/null 2>&1; then
        rm -f "$terminal_preferences"
        fail_setup "could not import Terminal preferences"
    fi

    rm -f "$terminal_preferences"
    printf 'Set Terminal profile "%s" to always close when its shell exits. Restart Terminal to use the new setting.\n' \
        "$terminal_profile_name"
}

apply_terminal_always_close_setting

printf 'Setup complete.\n'
