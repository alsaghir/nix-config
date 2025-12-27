# NixOS with Flake

This repository provides a NixOS configuration using flakes. It’s structured to support multiple hosts and composable modules without requiring you to edit many files per change.

This README is intentionally minimal and generic so it stays valid as the code evolves.

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
- Keep reusable logic in modules/ (system-wide) or overlays/ (package tweaks).
- If you add secrets, use your preferred secrets tool (e.g., sops-nix) and follow its docs.

## Notes

- DO NOT APPLY IMMEDIETLY. Configure and review before applying changes, especially hardware configurations.
- This repo is organized so you can add hosts and swap modules without rewriting the whole system.
- Exact module names and files may change; the steps above remain the same: create a host, import modules, rebuild.
