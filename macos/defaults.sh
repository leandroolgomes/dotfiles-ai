#!/usr/bin/env bash
# Optional macOS preferences. NOT run by install.sh: review, then run `./macos/defaults.sh`.
# These are opinionated suggestions (the source machine had none of them set) - edit freely.
set -euo pipefail
[[ "$(uname)" == "Darwin" ]] || { echo "macOS only"; exit 1; }

# Keyboard: fast key repeat, no press-and-hold accent popup (better for vim motions)
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
# Typing: no autocorrect/auto-capitalize/smart quotes in code
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Finder: extensions, path bar, status bar, list view
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# Dock: auto-hide, no recents
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock show-recents -bool false

# Screenshots: save to ~/Pictures/Screenshots
mkdir -p "$HOME/Pictures/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Pictures/Screenshots"

killall Finder Dock SystemUIServer 2>/dev/null || true
echo "Done. Some changes need a logout/restart."
