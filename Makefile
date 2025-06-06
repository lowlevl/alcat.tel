NIXARGS='<nixpkgs/nixos>' -I nixpkgs=$(NIXPKGS)

NIXPKGS=channel:nixos-25.05
MACHINEDIR=./machine

all:
	#-- Nothing to be done by default.

fmt:
	nix-shell $(NIXARGS) -p alejandra --run 'alejandra .'

link@%: $(MACHINEDIR)/%
	ln -s $(MACHINEDIR)/$* configuration.nix

build-vm@%: $(MACHINEDIR)/%
	nix-build $(NIXARGS) -I nixos-config=$(MACHINEDIR)/$* -A vm


.PHONY: fmt build-vm@%
