#!/bin/bash
# 01_checks.sh - Pre flight checks before installation

# Loads the config.env for the variables and color functions
source "$(dirname "$0")/config.env"

# Checks internet connectivity
check_internet() {

  info "Checking Internet connectivity..."

  if ! curl -s --max-time 10 https://archlinux.org >/dev/null 2>&1; then
    error "No internet connection detected. Please connect and retry."
  fi

  info "Internet connection OK."

}

# Checks type of boot (UEFI or BIOS)
check_boot_mode() {

  info "Detecting boot mode..."

  if [ -d /sys/firmware/efi ]; then
    BOOT_MODE="UEFI"
    info "Boot mode: UEFI"
  else
    BOOT_MODE="BIOS"
    warn "Boot mode: BIOS (Legacy). GRUB will be configured accordingly."
  fi

  echo "BOOT_MODE=${BOOT_MODE}" >>"$(dirname "$0")/config.env"

}

# Syncs system clocks
sync_clock() {

  info "Syncing system clock"
  timedatectl set-ntp true
  sleep 2
  info "System clock synced."

}

# Run the checks
check_internet
check_boot_mode
sync_clock

info "All pre-flight checks passed."
