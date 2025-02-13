# :: Alcat.tel™ ::
Some fun with classic "Télécommunication" infrastructure.

### Some inspirations, documentation and reference.

- https://search.nixos.org/
- https://chengeric.com/homelab/
- https://bef.github.io/yate-cookbook/

### Installation on the machine

_On this guide, this applies to the machine named `zero` but will work on other machines, replacing this term where required._

#### Partitionning the disk

On a freshly booted installer, clone the repository to the local directory

```
$ git clone https://github.com/lowlevl/alcat.tel.git
```

then enter a shell with `disko` installed and partition the disk from the configuration

```
$ nix-shell -p disko
$ sudo disko --mode disko alcat.tel/machine/zero/disk-config.nix
```

#### Installing NixOS on the disk



