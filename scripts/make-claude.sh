#!/bin/bash

DOTFILES_DIR="$HOME/dotfiles"
CLAUDE_DIR="$HOME/.claude"

GREEN=$'\033[32m'
RESET=$'\033[0m'

link() {
    local src="$1"
    local dst="$2"
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        rm -rf "$dst"
    fi
    mkdir -p "$(dirname "$dst")"
    ln -s "$src" "$dst"
    printf "  ${GREEN}✓${RESET} %s\n" "$dst"
}

link "$DOTFILES_DIR/claude/settings.json" "$CLAUDE_DIR/settings.json"
link "$DOTFILES_DIR/claude/skills"        "$CLAUDE_DIR/skills"
link "$DOTFILES_DIR/claude/rules"         "$CLAUDE_DIR/rules"
link "$DOTFILES_DIR/claude/agents"        "$CLAUDE_DIR/agents"
