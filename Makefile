# `make` lists the targets. Works with the GNU make 3.81 in Apple's Command
# Line Tools, so a fresh Mac needs nothing else to run it.

SHELL := /bin/bash
ROOT := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

# Which machine the targets act on: `make switch` is this Mac, `make switch
# HOST=aether` is the server. Everything below branches on it.
HOST ?= athena
MACHINES := athena aether

ATHENA := $(ROOT)/devices/athena/nix
AETHER := $(ROOT)/devices/aether/nix

NIX_BIN := /nix/var/nix/profiles/default/bin/nix
NIX := $(NIX_BIN) --extra-experimental-features 'nix-command flakes'
REBUILD := /run/current-system/sw/bin/darwin-rebuild
PROJECTS ?= $(HOME)/Projects

# aether is deployed over ssh with deploy-rs: this Mac is aarch64-darwin and
# can't build x86_64-linux, so the box builds its own closure (--remote-build).
AETHER_SSH ?= aether

.PHONY: help check bootstrap switch deploy update rollback clean uji

help: ## List targets (add HOST=aether for the server)
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-14s %s\n", $$1, $$2}'

check: ## Evaluate both machine configs without building
	@$(NIX) eval --raw '$(ATHENA)#darwinConfigurations.mac.config.system.build.toplevel.drvPath' >/dev/null && echo "  athena ok"
	@$(NIX) eval --raw '$(AETHER)#nixosConfigurations.aether.config.system.build.toplevel.drvPath' >/dev/null && echo "  aether ok"

# Each step skips itself when already done, so this is safe to rerun.
# athena: Nix, Homebrew, first switch. aether: assumes NixOS is installed and
# reachable over ssh; writes hardware.nix, copies the sops key, switches.
bootstrap: ## First switch on HOST (athena from scratch, aether over ssh)
ifeq ($(HOST),athena)
	@echo "Sign in to the App Store first if you haven't: the switch installs App Store apps."
	@sudo -v
	@[ -x $(NIX_BIN) ] || sh <(curl --proto '=https' --tlsv1.2 -sSfL https://nixos.org/nix/install) --daemon --yes
	@[ -x /opt/homebrew/bin/brew ] || NONINTERACTIVE=1 bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# The Nix installer edits these (and a hand-made yabai sudoers rule may exist);
# nix-darwin won't overwrite /etc files it doesn't recognise, so set them aside
	@[ -x $(REBUILD) ] || for f in bashrc zshrc shells sudoers.d/yabai; do if [ -e /etc/$$f ] && [ ! -L /etc/$$f ]; then sudo mv /etc/$$f /etc/$$f.before-nix-darwin; fi; done
	@if [ -x $(REBUILD) ]; then $(MAKE) --no-print-directory switch HOST=athena; else sudo $(NIX) run nix-darwin/nix-darwin-26.05#darwin-rebuild -- switch --flake '$(ATHENA)#mac-bootstrap'; fi
	@printf '%s\n' '' 'Done. Log out and back in so every app picks up the new shell. Then by hand:' \
	  '  - sign in to 1Password and turn on its SSH agent, then `make switch` to add uji' \
	  '  - yabai scripting addition: Recovery Mode -> Terminal ->' \
	  '    `csrutil enable --without debug --without fs`, then reboot (Nix loads it at boot)' \
	  '  - open Firefox once, then `make switch` to link its config' \
	  '  - optional: `make uji` once GitHub SSH keys are set up'
else ifeq ($(HOST),aether)
	@echo "Assuming NixOS is installed on $(AETHER_SSH) and $(AETHER_SSH) is in ~/.ssh/config."
	@echo "Reading the disk layout from $(AETHER_SSH) into devices/aether/nix/hardware.nix"
	@ssh -t $(AETHER_SSH) 'sudo nixos-generate-config --show-hardware-config' > '$(AETHER)/hardware.nix'
	@echo "Copying the sops age key to $(AETHER_SSH):/var/lib/sops-nix/key.txt"
	@scp -q "$(HOME)/Library/Application Support/sops/age/keys.txt" $(AETHER_SSH):/tmp/sops-age-key
	@ssh -t $(AETHER_SSH) 'sudo install -Dm600 -o root -g root /tmp/sops-age-key /var/lib/sops-nix/key.txt && rm -f /tmp/sops-age-key'
	@$(MAKE) --no-print-directory switch HOST=aether
	@echo "Done. Point tailscale at the box and run 'sudo tailscale up' on it by hand."
else
	$(error HOST must be one of: $(MACHINES))
endif

# Fetch inputs as you first: the private uji repo needs your SSH keys, which
# root (running the switch) can't use. Root then finds them already fetched.
switch: ## Apply the repo to HOST
ifeq ($(HOST),athena)
	@$(NIX) flake archive '$(ATHENA)' >/dev/null
	sudo darwin-rebuild switch --flake '$(ATHENA)#mac'
else ifeq ($(HOST),aether)
	cd '$(AETHER)' && $(NIX) run .#deploy -- .#aether --interactive-sudo true
else
	$(error HOST must be one of: $(MACHINES))
endif

deploy: ## Deploy the aether server with deploy-rs (remote build)
	cd '$(AETHER)' && $(NIX) run .#deploy -- .#aether --interactive-sudo true

update: ## Update HOST's flake.lock, then switch it
ifeq ($(HOST),athena)
	$(NIX) flake update --flake '$(ATHENA)'
	@$(MAKE) --no-print-directory switch HOST=athena
else ifeq ($(HOST),aether)
	$(NIX) flake update --flake '$(AETHER)'
	@$(MAKE) --no-print-directory switch HOST=aether
else
	$(error HOST must be one of: $(MACHINES))
endif

rollback: ## Undo the last switch on HOST
ifeq ($(HOST),athena)
	sudo darwin-rebuild --rollback
else ifeq ($(HOST),aether)
	ssh $(AETHER_SSH) 'sudo nixos-rebuild --rollback switch'
else
	$(error HOST must be one of: $(MACHINES))
endif

clean: ## Delete old generations and free space in this machine's store
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
