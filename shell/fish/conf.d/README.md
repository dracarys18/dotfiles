# fish/conf.d/

Files here are auto-sourced by fish on startup (in alphabetical order).
Keeping tool-init output cached as files — rather than running
`starship init fish | source` every shell — keeps startup under 300ms.

## Files

- **`kubectl_aliases.fish`** — 766 kubectl abbreviations from
  [ahmetb/kubectl-aliases](https://github.com/ahmetb/kubectl-aliases).
  These are fish `abbr` expansions: type `k` + space to get `kubectl`.
- **`starship_init.fish`** — cached output of `starship init fish --print-full-init`.
- **`zoxide_init.fish`** — cached output of `zoxide init fish`.

## Regenerating

```fish
# Refresh kubectl aliases (if upstream updates)
curl -fsSL https://raw.githubusercontent.com/ahmetb/kubectl-aliases/master/.kubectl_aliases.fish \
    -o ~/.dotfiles/shell/fish/conf.d/kubectl_aliases.fish

# Refresh starship init (after starship upgrade)
starship init fish --print-full-init > ~/.dotfiles/shell/fish/conf.d/starship_init.fish

# Refresh zoxide init (after zoxide upgrade)
zoxide init fish > ~/.dotfiles/shell/fish/conf.d/zoxide_init.fish
```
