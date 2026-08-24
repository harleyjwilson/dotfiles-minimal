# Minimal Mac Dotfiles

Minimal macOS dotfiles and setup for a new laptop.

## Install

Run the setup script from a checkout:

```sh
./setup.sh
```

Or run it directly with curl:

```sh
curl -fsSL https://raw.githubusercontent.com/harleyjwilson/dotfiles-minimal/main/setup.sh | sh
```

The script copies `Brewfile` into the home directory, installs Homebrew when needed, runs `brew bundle`, and configures the default Terminal profile to always close when its shell exits. Restart Terminal after setup for the setting to take effect.
