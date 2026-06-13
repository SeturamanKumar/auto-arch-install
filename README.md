# Auto Arch Install

An automated Arch Linux installation script that handles partitioning, base system setup, package installation and system configuration.

## Prerequisites

- Booted into Arch Linux live ISO
- Active internet connection
- Target disk available

## Disk Preparation

### Fresh Install
- Back up any important data — the entire disk will be wiped

### Dual Boot
- Shrink your existing partition to create free space for Arch
- Leave the free space as one **contiguous unallocated block**
- The script will automatically carve EFI (512MiB) + root from that space
- Do **not** pre-create partitions — let the script handle it

## Usage

```bash
git clone https://github.com/SeturamanKumar/auto-arch-install.git
cd auto-arch-install
chmod +x install.sh
bash install.sh
```

## Customization

Edit before running:
- `packages.txt` — add or remove pacman packages
- `aur_packages.txt` — add or remove AUR packages

## Post Install Notes

- Dotfiles and ricing must be set up manually after first boot
- Hibernate is disabled by default (incompatible with btrfs swapfile without extra configuration)
- Cloudflare WARP requires manual setup after install: `warp-cli register`# auto-arch-install
