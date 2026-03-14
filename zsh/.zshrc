eval "$(/opt/homebrew/bin/brew shellenv)"

# zsh-syntax-highlighting 
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# git prompt
source ~/dotfiles/zsh/git-prompt.sh

fpath=(~/dotfiles/zsh $fpath)
zstyle ':completion:*:*:git:*' script ~/dotfiles/zsh/git-completion.bash
autoload -Uz compinit && compinit

GIT_PS1_SHOWDIRTYSTATE=true
GIT_PS1_SHOWUNTRACKEDFILES=true
GIT_PS1_SHOWSTASHSTATE=true
GIT_PS1_SHOWUPSTREAM=auto

# prompt setting
daice_roll() {
    local choices=("⚀" "⚁" "⚂" "⚃" "⚄" "⚅")
    local random_index=$((RANDOM % ${#choices[@]}))
    
    echo "${choices[$random_index]}"
}
alias daice='daice_roll'

setopt PROMPT_SUBST ; PS1='🍵:%F{cyan}%~%f %F{white}$(__git_ps1 "(✥%s)")%f$ '

# ヒープ音を鳴らさない
setopt no_beep

# vim alias
alias vi="nvim"
alias vim="nvim"
alias view="nvim -R"

# git alias
alias g="git"
alias gpd="git pull origin develop"
alias gsd="git switch develop"
alias gmd="git merge develop"
alias gsp='git switch `git branch | peco | sed -e "s/*//g"`'
alias gpc='git pull origin $(git rev-parse --abbrev-ref HEAD)'

# nvim * diffview を使って差分を表示する
alias ndiff="nvim -c 'DiffviewOpen'"

# history settings
# ------------------------------------------
# 直前と同じコマンドは履歴に追加しない
setopt hist_ignore_dups

# 他のzshと履歴を共有する
setopt share_history

# 即座に履歴を保存する
setopt inc_append_history
# 余分な空白は詰めて記録
setopt hist_reduce_blanks

export HISTFILE=~/.zsh_history
export HISTSIZE=100000
export SAVEHIST=100000

# 検索履歴の検索にpecoを使う
function peco-history-selection() {
    BUFFER=`history -n 1 | tail -r | awk '!a[$0]++' | peco`
    CURSOR=$#BUFFER
    zle reset-prompt
}

zle -N peco-history-selection
bindkey '^R' peco-history-selection

# cdr(履歴からcdを実行するコマンドを有効化)
autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
add-zsh-hook chpwd chpwd_recent_dirs

zstyle ':completion:*' recent-dirs-insert both
zstyle ':chpwd:*' recent-dirs-max 500
zstyle ':chpwd:*' recent-dirs-default true
zstyle ':chpwd:*' recent-dirs-file "$HOME/.cache/shell/chpwd-recent-dirs"
zstyle ':chpwd:*' recent-dirs-pushd true

function peco-cdr() {
    local selected_dir=$(cdr -l | awk '{ print $2 }' | peco)
    if [ -n "$selected_dir" ]; then
        BUFFER="cd ${selected_dir}"
        zle accept-line
    fi
    zle clear-screen
}

zle -N peco-cdr
bindkey '^T' peco-cdr

# git commit時のエディターにneovimを使う
export GIT_EDITOR=nvim

# 画面上にゴミが残ってしまうことがあるため、設定
export NVIM_TUI_ENABLE_TRUE_COLOR=1
set termguicolors

# .zshrc.localファイルが存在していれば読み込ませる
# 端末によって追加している環境変数などが異なる場合があるため、追加分は.zshrc.localで運用する
if [ -f "$HOME/.zshrc.local" ]; then
  source "$HOME/.zshrc.local"
fi

# for tmuxinator editor
export EDITOR='nvim'

# なぜかApple Siliconの場合、コマンドの実行履歴の前後を表示できないため、明示的に指定
bindkey '^P' up-line-or-history    # Ctrl + P → 前の履歴
bindkey '^N' down-line-or-history  # Ctrl + N → 次の履歴

# peco と git-wt を組み合わせて worktree を切り替える
# Add the following to your shell config to enable worktree switching and completion
eval "$(git wt --init zsh)"

wt() {
  git wt "$(git wt | tail -n +2 | peco | awk '{print $(NF-1)}')"
}

# z, zi
eval "$(zoxide init zsh)"

# mise
eval "$(mise activate zsh)"

