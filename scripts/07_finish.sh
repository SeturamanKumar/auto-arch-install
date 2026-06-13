#!/bin/bash
# 07_finish.sh - Unmount partitions and finish installation

source "$(dirname "$0")/config.env"

# Unmount partitions
unmount_partitions() {

  info "Unmounting partitions..."

  if [[ "$SWAP_SIZE" -gt 0 ]]; then
    swapoff /mnt/swap/swapfile
  fi

  umount -R /mnt

  info "Paritions unmounted."

}

# Finish
finish() {

  echo
  echo "  ╔═══════════════════════════════════════╗"
  echo "  ║     Installation Complete!            ║"
  echo "  ╚═══════════════════════════════════════╝"
  echo

  info "Arch Linux has been successfully installed."
  info "You can now reboot into your new system."
  echo

  warn "Don't forget to remove the installation media before rebooting!"
  echo
  info "Reboot now? (y/n)"
  read -r REBOOT

  if [[ "$REBOOT" == "y" ]]; then
    info "Rebooting..."
    reboot

  else

    info "You can reboot manually when ready with: reboot"
  fi
}

unmount_partitions
finish
