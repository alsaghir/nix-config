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

- Enable or disable features by editing hosts/<your-host>/default.nix and the modules it imports.
- Keep host‑specific choices (kernel, services, hardware toggles) in your host directory.
- Keep reusable system features in `nixos/` and `roles/`, home features in `home/`, and package tweaks in `overlays/`.
- If you add secrets, use your preferred secrets tool (e.g., sops-nix) and follow its docs.

## Module composition

`users/registry.nix` is the single source of truth for user identity, theme preferences,
host platforms, primary users, and user-to-host assignments. The builders in `lib/`
translate these into standard NixOS/Home Manager options. Host overlays are bound to
flake inputs once and applied to both package sets.

Each `user@host` Home Manager configuration is assembled from:

1. Registry defaults (`home.username`, `home.homeDirectory`, `nixConfig.theme`).
2. The user's profile `users/<user>/default.nix` (required).
3. The user's host profile `users/<user>/<host>/default.nix` (optional).
4. Extra modules listed in registry `hosts.<host>.userModules.<user>`.

Profiles are the only modules that receive flake inputs. The builder binds them
lexically with `lib.modules.importApply`, so a profile is a function returning a module:

```nix
{ inputs }:              # users/<user>/default.nix
{ config, ... }:
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
    ../../home/cli.nix
  ];
}
```

Host profiles receive `{ inputs, hostname }`; take `{ ... }` when nothing is needed.
External modules are opt-in per profile: Ahmed's profile selects SOPS, LazyVim, and
AI rules, and his laptop profile selects Flatpak. A new user inherits none of them.

Feature modules (`home/`, `nixos/`, `roles/`) use `config`, `lib`, and `pkgs`, not
`inputs`, `userConfig`, or `hostConfig`. Use `config.home.homeDirectory` for home
paths. The typed `nixConfig.theme` option accepts `"dark"` or `"light"`; the builder
supplies the registry preference with `lib.mkDefault`, so a profile can override it
normally. Use `lib.mkForce` for an intentional override of another explicit value.
When composing desktop features independently, also import `home/options.nix`.

Keep imports explicit and independent of `config`. Do not move dependencies needed
by imports into `_module.args`, which can recurse. `importApply` preserves source
locations without assigning a path-only module key: differently bound instances
must not silently deduplicate. Select each dependency once in its profile.

Dormant modules remain opt-in. `nixos/services/nix-config.nix` is not currently
enabled; to select it, add
`(nixpkgs.lib.modules.importApply ./nixos/services/nix-config.nix { inherit inputs; })`
to the system module list. DMS requires an explicit `pluginRegistry` binding plus
its upstream modules; KDE likewise requires plasma-manager. Their inputs are
currently commented out, and this composition does not enable them.

## Adding a user or host

1. Add identity and preferences under `users` in `users/registry.nix`.
2. Create `users/<user>/default.nix` (`{ inputs }: { ... }: { ... }`) with a
   `home.stateVersion` and explicit imports.
3. Add the host platform, primary user, and `userModules.<user>` assignment to the
   registry. For NixOS, create the host configuration/hardware modules and add a
   `mkNixosSystem` call to `nixosConfigurations` in `flake.nix`.
4. Optionally create `users/<user>/<host>/default.nix` for host-specific home
   configuration. Keep small assignment-specific additions in the registry list.

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
missing-profile failure, theme validation and override priorities, standalone GNOME
dark/light behavior on Linux, multiple users/hosts without Ahmed's external
integrations, distinct lexical bindings of the same module, and opt-in Nix registry
binding on Linux. Fixture profiles live in `tests/fixtures/users`. Checks are exposed
for every supported system; choose the native system when running them.

These commands do not activate either configuration. Review before switching;
system and standalone Home Manager switches remain separate manual operations.

## Notes

- DO NOT APPLY IMMEDIATELY. Configure and review before applying changes, especially hardware configurations.
- This repo is organized so you can add hosts and swap modules without rewriting the whole system.
- Exact module names and files may change; the steps above remain the same: create a host, import modules, rebuild.
