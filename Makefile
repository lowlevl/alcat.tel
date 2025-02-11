NIXBLD=nix-build

NIXPKGS=channel:nixos-24.11
MACHINEDIR=./machine

_BUILD=$(NIXBLD) '<nixpkgs/nixos>' -I nixpkgs=$(NIXPKGS)

all:
	#-- Nothing to be done by default.

fmt:
	nix fmt	

build-vm@%: $(MACHINEDIR)/%
	$(_BUILD) -I nixos-config=$(MACHINEDIR)/$* -A vm

.PHONY: fmt build-vm@%
