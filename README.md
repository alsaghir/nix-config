# NixOS with Flake

This repository provides a NixOS configuration using flakes. It’s structured to support multiple hosts and composable modules without requiring you to edit many files per change.

## Requirements

- NixOS with flakes enabled
- Git
- Hardware configuration for each host

## Update inputs

```bash
nix flake update
sudo nixos-rebuild switch --flake .#<your-host>
```

## Customize

Every module in `nixos/` and `home/` is imported for every host and user, and does
nothing until it is enabled. Hosts and user profiles only switch features on:

```nix
# hosts/<host>/default.nix                # users/<user>[/<host>]/default.nix
nixConfig.desktop.niri.enable = true;     nixConfig.desktop.niri.enable = true;
nixConfig.services.jellyfin = {           nixConfig.cli.enable = true;
  enable = true;
  mediaDirs.movies = "/mnt/media/Movies";
};
```

Option path = file path: `nixos/hardware/bluetooth.nix` → `nixConfig.hardware.bluetooth`,
`home/desktop/niri.nix` → `nixConfig.desktop.niri`. A desktop enables its parts with
`lib.mkDefault` (so `nixConfig.desktop.dms.enable = false` still works). `nixos/core/`
and `home/justfile.nix` are always on; core takes host parameters such as
`nixConfig.core.boot.loader` (`systemd-boot` default, or `grub-bios` for firmware that
cannot boot Linux via UEFI). A setting that is one upstream option
(`programs.steam.enable`) is set directly in the host, without a wrapper module.

## Layout

```text
flake.nix            inputs + outputs; the only place flake inputs are bound (sharedModules, overlays)
registry.nix         single source of truth: users, hosts, user↔host assignment, per-host data
lib/default.nix      builders: registry → nixosConfigurations / homeConfigurations
lib/{displays,users}.nix   `nixConfig.*` data options the builders fill from the registry
lib/wrappers.nix     package wrappers (pure functions of pkgs)
hosts/<host>/        NixOS entry point: feature flags, hardware, disko, displays, host facts
nixos/               NixOS modules, all imported by nixos/default.nix
  core/              baseline for every host (always on; boot loader, users, nix, network)
  desktop/           niri.nix (niri + DMS greeter, on top of common.nix) or gnome.nix (GDM, optional RDP); both add fonts.nix
  hardware/          asus, bluetooth, nvidia-hybrid
  services/          jellyfin, nix-ld, openssh (key-only), virtualisation
home/                Home Manager modules, all imported by home/default.nix
  desktop/           niri.nix session, dms.nix shell, common.nix GUI base (browser, terminal, editor, theming)
  cli.nix dev.nix ai.nix   shell + LazyVim; Kubernetes + Copilot CLI; other AI CLIs
users/<user>/        Home Manager profile; users/<user>/<host>/ adds host-specific bits and personal app picks
overlays/            package fixes: default.nix is global, others are host-scoped via the registry
```

## Module composition

`registry.nix` is the single source of truth for user identity, host platforms,
primary users, and user-to-host assignments. Only the builders in `lib/default.nix`
read it; they translate it into standard NixOS/Home Manager options and
`nixConfig.*` options, so modules never import the registry or `lib/` builders.

Every registry host with `hosts/<host>/default.nix` becomes a NixOS system made of:

1. `sharedModules` from `flake.nix`: disko, `nixos/` (all modules), flake-input pinning.
2. Registry data: `networking.hostName`, `nixConfig.displays`, `nixConfig.users`,
   `nixConfig.primaryUser` (accounts are created by `nixos/core/users.nix`).
3. `hosts/<host>/default.nix`, which enables features and holds machine facts.

Each `user@host` Home Manager configuration is assembled from:

1. `sharedModules` from `flake.nix`: `home/` (all modules, plus the third-party
   modules they configure: niri, DMS, LazyVim, nix-flatpak).
2. Registry defaults (`home.username`, `home.homeDirectory`, `nixConfig.displays`).
3. The user's profile `users/<user>/default.nix` (required).
4. The user's host profile `users/<user>/<host>/default.nix` (optional).
5. Extra modules listed in registry `hosts.<host>.userModules.<user>`.

Flake inputs reach only `flake.nix`, the two aggregators it binds (`home/default.nix`,
`nixos/core/flake-pinning.nix`) and profiles. The builder binds profiles lexically with
`lib.modules.importApply`, so a profile is a function returning a module:

```nix
{ inputs }:              # users/<user>/default.nix
{ config, ... }:
{
  imports = [ inputs.sops-nix.homeManagerModules.sops ];   # user-specific modules only
  nixConfig.cli.enable = true;
}
```

Host profiles receive `{ inputs, hostname }`; take `{ inputs, ... }` or `{ ... }`.
Ahmed's profile adds SOPS and AI rules and enables `cli`/`dev`/`ssh` everywhere. Shared
`home/` modules hold features and setup; personal app picks live in host profiles: the laptop
profile enables niri, Flatpak and `ai` and lists its apps, the home-server profile adds only
VS Code (GNOME over RDP).

Feature modules (`home/`, `nixos/`) use `config`, `lib`, and `pkgs`, not
`inputs` or the registry. Use `config.home.homeDirectory` for home paths in Home
Manager and `config.nixConfig.users.${config.nixConfig.primaryUser}` in NixOS. Shared
modules hold only host-agnostic settings; machine values (media directories, GPU
device paths, PRIME bus IDs) are set by the host, through the module's options or
upstream options (e.g. `hosts/asus-laptop/jellyfin.nix`). The builder supplies
registry values with `lib.mkDefault`, so a profile can override them normally; use
`lib.mkForce` for an intentional override of another explicit value.
`nixConfig.displays` (schema in `lib/displays.nix`) holds the host's monitor layout;
niri outputs, kanshi profiles, DMS wallpaper cycling and the greeter layout are
generated from it.

Keep imports independent of `config` (enable flags gate `config`, never `imports`).
Do not move dependencies needed by imports into `_module.args`/`specialArgs`, which
leaks them into every module and can recurse. `importApply` preserves source locations
without assigning a path-only module key: differently bound instances must not
silently deduplicate.

## Adding a module, user or host

- Module: create `nixos/<dir>/<name>.nix` or `home/<dir>/<name>.nix` with
  `options.nixConfig.<dir>.<name>.enable = lib.mkEnableOption "…";` and
  `config = lib.mkIf config.nixConfig.<dir>.<name>.enable { … };`, then list it in the
  aggregator (`nixos/<dir>/default.nix` or `home/default.nix`).
- User: add it under `users` in `registry.nix` and create `users/<user>/default.nix`
  (`{ inputs }: { ... }: { ... }`) with a `home.stateVersion` and its feature flags.
- Host:
  1. Add it under `hosts` in `registry.nix` (platform, primary user,
     `userModules.<user>` assignment).
  2. For NixOS, create `hosts/<host>/default.nix` (hardware, disko, feature flags,
     `system.stateVersion`). Nothing to add in `flake.nix`: the host appears in
     `nixosConfigurations` automatically. For a desktop, put its monitors in
     `hosts/<host>/displays.nix` (connector names from `niri msg outputs`; mark the
     built-in panel `internal = true`) and reference it as the registry's
     `hosts.<host>.displays`.
  3. Optionally create `users/<user>/<host>/default.nix` for host-specific home
     configuration. Keep small assignment-specific additions in the registry list.

## Installing a new host (nixos-anywhere)

Remote install over SSH from this machine; it formats the disks in `hosts/<host>/disko.nix`.
Example: `home-server`.

1. Boot the target from the NixOS minimal ISO (`dd` it to a USB stick; verify with
   `sha256sum -c` and `cmp`). Set a root password (`sudo passwd root`), note its IP (`ip -4 a`).
2. Hardware config and disk ids, from the installer:
   ```bash
   ssh root@<ip> nixos-generate-config --no-filesystems --show-hardware-config > hosts/<host>/hardware-configuration.nix
   ssh root@<ip> ls -l /dev/disk/by-id/      # device for disko.nix
   ```
3. Registry entry, `hosts/<host>/{default,disko}.nix`, then `git add -A` (flakes only see tracked files)
   and `nix eval --raw .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath`.
4. Install (wipes the disk; reboots into the new system):
   ```bash
   nix run github:nix-community/nixos-anywhere -- --flake .#<host> root@<ip>
   ```
5. First login: `ssh root@<host>.local passwd <user>` (root accepts the primary user's keys
   via `nixConfig.services.openssh`).
6. Per-machine keys, generated on the host (private halves never leave it):
   - `age-keygen -o ~/.config/sops/age/keys.txt` (user secrets): add its public key to
     `.sops.yaml`, then `sops updatekeys <file>` here. The host's own recipient (system
     secrets) is `ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub`; nothing to generate.
   - `ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519`: add the `.pub` as a read-only deploy key
     on the private `ai-rules` repo.
7. Commit and push here, then on the host the repo is a read-only clone (edits happen here):
   ```bash
   git clone https://github.com/alsaghir/nix-config.git ~/Projects/nix-config
   nix shell nixpkgs#nh -c nh os switch ~/Projects/nix-config     # first time; nh is installed by home-manager
   nix shell nixpkgs#nh -c nh home switch ~/Projects/nix-config
   ```
   Afterwards: `git pull && nh os switch && nh home switch` (or `just` recipes).

## Verification without activation

New module files must be tracked by Git for `.#` flake targets to include them.
For an untracked local draft, use `path:.#` instead of `.#` in the commands below.
The formatter command checks formatting by applying it and fails if it changes files.

```bash
nix fmt -- --fail-on-change
nix build .#checks.x86_64-linux.composition --no-link
nix eval --raw .#nixosConfigurations.asus-laptop.config.system.build.toplevel.drvPath
nix eval --raw '.#homeConfigurations."ahmed@asus-laptop".activationPackage.drvPath'
nix build --dry-run .#nixosConfigurations.asus-laptop.config.system.build.toplevel
nix build --dry-run '.#homeConfigurations."ahmed@asus-laptop".activationPackage'
```

The composition check covers registry defaults, profile and host-profile loading,
missing-profile failure, override priorities, display injection and validation,
NixOS systems only for hosts with a host directory, account creation from the registry,
every `nixos/` module importing cleanly and staying off unless enabled, module parameters,
multiple users/hosts without Ahmed's external
integrations, distinct lexical bindings of the same module, and flake-input pinning (Nix registry
binding) on Linux. Fixtures live in `tests/fixtures/{users,hosts}`. Checks are exposed
for every supported system; choose the native system when running them.

These commands do not activate either configuration. Review before switching;
system and standalone Home Manager switches remain separate manual operations.

## Notes

- DO NOT APPLY IMMEDIATELY. Configure and review before applying changes, especially hardware configurations.
- This repo is organized so you can add hosts and swap modules without rewriting the whole system.
- Exact module names and files may change; the steps above remain the same: create a host, import modules, rebuild.
