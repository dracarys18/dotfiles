# `make` lists the targets. Works with the GNU make 3.81 in Apple's Command
# Line Tools, so a fresh Mac needs nothing else to run it.

SHELL := /bin/bash
ROOT := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
FLAKE := $(ROOT)/src/mac/nix
NIX_BIN := /nix/var/nix/profiles/default/bin/nix
NIX := $(NIX_BIN) --extra-experimental-features 'nix-command flakes'
REBUILD := /run/current-system/sw/bin/darwin-rebuild
PROJECTS ?= $(HOME)/Projects

.PHONY: help bootstrap-mac switch update rollback clean obs-save uji

help: ## List targets
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-14s %s\n", $$1, $$2}'

# Each step skips itself when already done, so this is safe to rerun
bootstrap-mac: ## Set up a fresh Mac: Nix, Homebrew, first switch
	@echo "Sign in to the App Store first if you haven't: the switch installs App Store apps."
	@sudo -v
	@[ -x $(NIX_BIN) ] || sh <(curl --proto '=https' --tlsv1.2 -sSfL https://nixos.org/nix/install) --daemon --yes
	@[ -x /opt/homebrew/bin/brew ] || NONINTERACTIVE=1 bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# The Nix installer edits these, and nix-darwin won't overwrite /etc files it
# doesn't recognise, so set them aside before the first switch
	@[ -x $(REBUILD) ] || for f in bashrc zshrc shells; do if [ -e /etc/$$f ] && [ ! -L /etc/$$f ]; then sudo mv /etc/$$f /etc/$$f.before-nix-darwin; fi; done
	@if [ -x $(REBUILD) ]; then sudo $(REBUILD) switch --flake '$(FLAKE)#mac'; else sudo $(NIX) run nix-darwin/nix-darwin-26.05#darwin-rebuild -- switch --flake '$(FLAKE)#mac'; fi
	@printf '%s\n' '' 'Done. Log out and back in so every app picks up the new shell. Then by hand:' \
	  '  - yabai scripting addition: Recovery Mode -> Terminal ->' \
	  '    `csrutil enable --without debug --without fs`, reboot, `sudo yabai --load-sa`' \
	  '  - open Firefox once, then `make switch` to link its config' \
	  '  - optional: `make uji` once GitHub SSH keys are set up'

switch: ## Apply the repo to this Mac
	sudo darwin-rebuild switch --flake '$(FLAKE)#mac'

update: ## Update packages, nvim plugins and treesitter, then switch
	$(NIX) flake update --flake '$(FLAKE)'
	sudo darwin-rebuild switch --flake '$(FLAKE)#mac'
	nvim --headless "+lua vim.pack.update(nil, { force = true })" +qa
	nvim --headless "+lua require('nvim-treesitter').update():wait(300000)" +qa

rollback: ## Undo the last switch
	sudo darwin-rebuild --rollback

clean: ## Delete old generations and free disk space
	sudo nix-collect-garbage -d
	sudo nix store optimise

obs-save: ## Save OBS settings into the repo (stream keys and logins blanked)
	@bash $(ROOT)/src/mac/scripts/obs-save.sh

uji: ## Clone uji, its plugins and skills into ~/Projects, then build uji
	@for r in uji uji-plugins uji-skills; do \
	  d=$(PROJECTS)/$$r; \
	  if [ -d $$d/.git ]; then echo "  skip   $$d (already cloned)"; \
	  elif [ -e $$d ]; then echo "  warn   $$d exists but isn't a git checkout, leaving it"; \
	  else mkdir -p $(PROJECTS) && git clone git@github.com:uji-labs/$$r.git $$d || echo "  failed $$r: clone it by hand, then rerun"; fi; \
	done
	cargo install --path $(PROJECTS)/uji/crates/uji --locked
	@echo "Set LITELLM_BASE_URL and LITELLM_API_KEY (BRAVE_API_KEY optional) in your shell."
