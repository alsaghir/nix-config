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

`flake.nix` explicitly selects the system modules and the Home Manager `userModules`
and optional `hostModules` profiles. These maps only compose modules: they do not
assign users to hosts. Registry `hosts.<host>.userModules.<user>` lists additional
modules for that assignment. There is no automatic directory scanning or mandatory
per-host home directory; a missing user profile fails evaluation.

External modules are opt-in per profile. For example, Ahmed's profile receives SOPS,
LazyVim, and AI rules, while his laptop profile receives Flatpak. A new user does not
inherit those integrations. Entry points with dependencies are curried and bound at
the composition boundary using `nixpkgs.lib.modules.importApply`:

```nix
userModules.ahmed = nixpkgs.lib.modules.importApply ./users/ahmed {
  sopsModule = inputs.sops-nix.homeManagerModules.sops;
  lazyvimModule = inputs.lazyvim.homeManagerModules.default;
  aiRulesModule = inputs.ai-rules.homeManagerModules.default;
};
```

Ordinary modules use `config`, `lib`, and `pkgs`, not global `inputs`, `userConfig`,
or `hostConfig` arguments. Use `config.home.homeDirectory` for home paths. The typed
`nixConfig.theme` option accepts `"dark"` or `"light"`; the builder supplies the
registry preference with `lib.mkDefault`, so a user or host module can override it
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
2. Create `users/<user>/default.nix` with a `home.stateVersion` and explicit feature
   imports, and select it as `userModules.<user>` in `flake.nix`. Use a plain path
   when it needs no lexical dependencies.
3. Add the host platform, primary user, and `userModules` assignments to the registry.
   For NixOS, create the host configuration/hardware modules and add a
   `mkNixosSystem` call to `nixosConfigurations`.
4. If a user needs host-specific configuration, select it under
   `hostModules.<host>.<user>` in `flake.nix`. Otherwise no host home profile is
   required. Keep small assignment-specific additions in registry module lists.

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

The composition check covers registry defaults, theme validation and overrides,
standalone GNOME dark/light behavior on Linux, multiple users/hosts without Ahmed's
external integrations, distinct lexical bindings of the same module, and opt-in
Nix registry binding on Linux. Checks are exposed for every supported system;
choose the native system when running them.

These commands do not activate either configuration. Review before switching;
system and standalone Home Manager switches remain separate manual operations.

## Notes

- DO NOT APPLY IMMEDIATELY. Configure and review before applying changes, especially hardware configurations.
- This repo is organized so you can add hosts and swap modules without rewriting the whole system.
- Exact module names and files may change; the steps above remain the same: create a host, import modules, rebuild.
