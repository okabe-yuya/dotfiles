#!/bin/bash

DOTFILES_DIR="$HOME/dotfiles"
CLAUDE_DIR="$HOME/.claude"

# settings.json
if [ -e "$CLAUDE_DIR/settings.json" ]; then
    unlink "$CLAUDE_DIR/settings.json"
fi
ln -sv "$DOTFILES_DIR/claude/settings.json" "$CLAUDE_DIR/settings.json"

# skills
rm -rf "$CLAUDE_DIR/skills"
ln -sv "$DOTFILES_DIR/claude/skills" "$CLAUDE_DIR/skills"

# rules
rm -rf "$CLAUDE_DIR/rules"
ln -sv "$DOTFILES_DIR/claude/rules" "$CLAUDE_DIR/rules"

# agents
rm -rf "$CLAUDE_DIR/agents"
ln -sv "$DOTFILES_DIR/claude/agents" "$CLAUDE_DIR/agents"
