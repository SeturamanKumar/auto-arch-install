#!/bin/bash
# install.sh - Starts the complete automated installation of arch
# Runs on the live Arch ISO and system configuration is handed off to chroot-install.sh

source "$(dirname "$0")/scripts/config.env"

echo "
  ╔═══════════════════════════════════════╗
  ║         Auto Arch Installer           ║
  ╚═══════════════════════════════════════╝
"

# Run pre chroot-install scripts
info "Starting installation..."
echo

bash "$(dirname "$0")/scripts/01_checks.sh"
bash "$(dirname "$0")/scripts/02_user_input.sh"
bash "$(dirname "$0")/scripts/03_disk.sh"
bash "$(dirname "$0")/scripts/04_base.sh"

# Call chroot-install.sh in the new system
info "Entering chroot environment..."
echo

arch-chroot /mnt bash /auto-arch-install/scripts/chroot-install.sh

# Post chroot-install.sh execution
info "Chroot complete. Finalizing installation..."
echo

bash "$(dirname "$0")/scripts/07_finish.sh"
