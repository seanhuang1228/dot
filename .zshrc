# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000

setopt auto_pushd pushd_ignore_dups pushd_silent pushdminus
DIRSTACKSIZE=10

setopt autocd
unsetopt beep
bindkey -v
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/sean/.zshrc'

# zstyle ':completion:*' menu select
zstyle ':completion:*' list-suffixeszstyle ':completion:*' expand prefix suffix

autoload -Uz compinit
autoload -Uz promptinit
compinit
promptinit
# End of lines added by compinstall

# Options
setopt NO_CASE_GLOB
unsetopt CORRECT
unsetopt CORRECT_ALL

# Alias
alias ll='ls -al'
alias ls='ls --color=auto'
alias open='xdg-open'
alias -g ...=../..
alias -g ....=../../..
alias -g .....=../../../..
alias vim='nvim'
alias clip='xclip -sel clip'

# ENV
PATH=$PATH:/home/sean/.local/bin:/home/sean/.local/share/gem/ruby/3.0.0/bin

# Functions
# function cl () {
# 	cd $1;
# 	ls .;
# }

### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

### End of Zinit's installer chunk

# Powerlevel10k
zinit ice depth=1; zinit light romkatv/powerlevel10k

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# zinit plugins

zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-history-substring-search
zinit light zdharma-continuum/fast-syntax-highlighting
zinit light none9632/zsh-sudo
zinit light djui/alias-tips
# zinit ice depth=1
# zinit light jeffreytse/zsh-vi-mode

zinit snippet OMZ::plugins/git/git.plugin.zsh

zinit snippet PZT::modules/docker/init.zsh
zinit snippet PZT::modules/docker/alias.zsh

# key binding
bindkey ',' autosuggest-accept
