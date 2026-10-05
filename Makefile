# `make` lists the targets. Works with the GNU make 3.81 in Apple's Command
# Line Tools, so a fresh Mac needs nothing else to run it.

SHELL := /bin/bash
ROOT := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
FLAKE := $(ROOT)/src/mac/nix
NIX_BIN := /nix/var/nix/profiles/default/bin/nix
NIX := $(NIX_BIN) --extra-experimental-features 'nix-command flakes'
REBUILD := /run/current-system/sw/bin/darwin-rebuild
PROJECTS ?= $(HOME)/Projects

.PHONY: help bootstrap-mac switch update rollback clean uji

help: ## List targets
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-14s %s\n", $$1, $$2}'

# Each step skips itself when already done, so this is safe to rerun
bootstrap-mac: ## Set up a fresh Mac: Nix, Homebrew, first switch
	@echo "Sign in to the App Store first if you haven't: the switch installs App Store apps."
	@sudo -v
	@[ -x $(NIX_BIN) ] || sh <(curl --proto '=https' --tlsv1.2 -sSfL https://nixos.org/nix/install) --daemon --yes
	@[ -x /opt/homebrew/bin/brew ] || NONINTERACTIVE=1 bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# The Nix installer edits these (and a hand-made yabai sudoers rule may exist);
# nix-darwin won't overwrite /etc files it doesn't recognise, so set them aside
	@[ -x $(REBUILD) ] || for f in bashrc zshrc shells sudoers.d/yabai; do if [ -e /etc/$$f ] && [ ! -L /etc/$$f ]; then sudo mv /etc/$$f /etc/$$f.before-nix-darwin; fi; done
	@if [ -x $(REBUILD) ]; then $(MAKE) --no-print-directory switch; else sudo $(NIX) run nix-darwin/nix-darwin-26.05#darwin-rebuild -- switch --flake '$(FLAKE)#mac-bootstrap'; fi
	@printf '%s\n' '' 'Done. Log out and back in so every app picks up the new shell. Then by hand:' \
	  '  - sign in to 1Password and turn on its SSH agent, then `make switch` to add uji' \
	  '  - yabai scripting addition: Recovery Mode -> Terminal ->' \
	  '    `csrutil enable --without debug --without fs`, then reboot (Nix loads it at boot)' \
	  '  - open Firefox once, then `make switch` to link its config' \
	  '  - optional: `make uji` once GitHub SSH keys are set up'

# Fetch inputs as you first: the private uji repo needs your SSH keys, which
# root (running the switch) can't use. Root then finds them already fetched.
switch: ## Apply the repo to this Mac
	@$(NIX) flake archive '$(FLAKE)' >/dev/null
	sudo darwin-rebuild switch --flake '$(FLAKE)#mac'

update: ## Update packages, nvim plugins and treesitter, then switch
	$(NIX) flake update --flake '$(FLAKE)'
	@$(MAKE) --no-print-directory switch
	nvim --headless "+lua vim.pack.update(nil, { force = true })" +qa
	nvim --headless "+lua require('nvim-treesitter').update():wait(300000)" +qa

rollback: ## Undo the last switch
	sudo darwin-rebuild --rollback

clean: ## Delete old generations and free disk space
	sudo nix-collect-garbage -d
	sudo nix store optimise


uji: ## Clone uji, its plugins and skills into ~/Projects (Nix installs the uji binary)
	@for r in uji uji-plugins uji-skills; do \
	  d=$(PROJECTS)/$$r; \
	  if [ -d $$d/.git ]; then echo "  skip   $$d (already cloned)"; \
	  elif [ -e $$d ]; then echo "  warn   $$d exists but isn't a git checkout, leaving it"; \
	  else mkdir -p $(PROJECTS) && git clone git@github.com:uji-labs/$$r.git $$d || echo "  failed $$r: clone it by hand, then rerun"; fi; \
	done
	@echo "Set LITELLM_BASE_URL and LITELLM_API_KEY (BRAVE_API_KEY optional) in your shell."
