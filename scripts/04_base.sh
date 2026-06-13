#!/bin/bash
# 04_base.sh - Installs the base system, generates fstab and copy scripts to mounted root volume

source "$(dirname "$0")/config.env"

# Install the base system
install_base() {

  info "Installing base systems..."

  pacstrap /mnt \
    base \
    base-devel \
    linux \
    linux-firmware \
    linux-headers \
    grub \
    efibootmgr \
    os-prober \
    btrfs-progs \
    networkmanager \
    git \
    sudo \
    nano \
    vim

  info "Base system installed."

}

# Generate fstab for the partitions
generate_fstab() {

  info "Geberating fstab..."

  genfstab -U /mnt >>/mnt/etc/fstab

  info "fstab generated."
  info "fstab contents:"
  cat /mnt/etc/fstab

}

# Copy scripts into the new system
copy_scripts() {

  info "copying install scripts into new system..."
  cp -r "$(dirname "$0")/.." /mnt/auto-arch-install
  info "Scripts copied to /mnt/auto-arch-install"

}

# Run for base installation
install_base
generate_fstab
copy_scripts

info "Base system setup complete."
