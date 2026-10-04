# ===================================================================
# Fish shell configuration
# ===================================================================

# Only run the rest in interactive sessions
if not status is-interactive
    exit
end

# Theme catppuccin-mocha
fish_config theme choose catppuccin-mocha

# No greeting when a new shell opens
set -g fish_greeting

# -------------------------------------------------------------------
# Environment variables
# -------------------------------------------------------------------
set -gx GOPRIVATE "github.com/razorpay/*"
set -gx GONOSUMDB "github.com/razorpay/*"
set -gx ANTHROPIC_SMALL_FAST_MODEL "claude-sonnet-4-6"
set -gx WERF_HELM3_MODE 1

# Zscaler Certificate for Claude Code (uncomment if needed)
# set -gx NODE_EXTRA_CA_CERTS "$HOME/.claude/certs/ZscalerRootCertificate-2048-SHA256.crt"

# -------------------------------------------------------------------
# PATH setup — fish_add_path is idempotent and handles deduping
# -------------------------------------------------------------------
# Homebrew only holds GUI apps and a few macOS tools now; nix paths come first
fish_add_path -g --append /opt/homebrew/bin
fish_add_path -g --append /opt/homebrew/sbin
fish_add_path -g $HOME/.cargo/bin
fish_add_path -g $HOME/.local/bin
fish_add_path -g $HOME/.devstack/bin

# -------------------------------------------------------------------
# Aliases — guarded so they only apply if the tool is installed
# Note: zoxide's `z` is a fish function (defined in conf.d/zoxide_init.fish),
# not a binary — so we check for `zoxide` itself.
# -------------------------------------------------------------------
command -q zoxide;    and alias cd='z'
command -q eza;       and alias ls='eza'
command -q exa;       and not command -q eza; and alias ls='exa'  # fallback if eza missing
command -q bat;       and alias cat='bat'
command -q nvim;      and alias vim='nvim';     and alias vi='nvim'
command -q terraform; and alias tf='terraform'
command -q opencode;  and alias clanker='opencode'
command -q pdf; and alias pdf='mupdf-gl -I'

alias loc='tokei'
alias sshat='ssh arch -t "fish"'
alias helmfile='helmfile --enable-live-output -b werf'

# -------------------------------------------------------------------
# Third-party tool initializations
# -------------------------------------------------------------------
# zoxide, starship, and kubectl abbreviations live in conf.d/
# (auto-loaded by fish — see conf.d/README if you need to regenerate)

# ghcup (Haskell) — only if installed
if test -f $HOME/.ghcup/env
    fish_add_path -g $HOME/.ghcup/bin
    fish_add_path -g $HOME/.cabal/bin
end

# opam (OCaml) — only if installed
if test -r $HOME/.opam/opam-init/init.fish
    source $HOME/.opam/opam-init/init.fish >/dev/null 2>&1
end


# -------------------------------------------------------------------
# Key bindings — up/down arrow history search
# -------------------------------------------------------------------
bind up history-prefix-search-backward
bind down history-prefix-search-forward

# direnv — per-directory environments
direnv hook fish | source
