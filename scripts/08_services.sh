#!/bin/bash
# 08_services.sh - Enable system services after all packages are installaed

source /auto-arch-install/scripts/config.env

enable_services() {

  info "Enabling services..."

  # Core services
  systemctl enable NetworkManager
  systemctl enable bluetooth
  systemctl enable sddm

  # Power management
  systemctl enable tlp
  systemctl enable tlp-sleep

  # Virtualization
  systemctl enable libvirtd
  systemctl enable docker

  # Server
  systemctl enable nginx
  systemctl enable monit

  # SSH
  systemctl enable sshd

  # Firewall
  systemctl enable firewalld

  # Printing
  systemctl enable cups

  # Disable hibernate
  systemctl mask sleep.target suspend-then-hibernate.target hibernate.target hybrid-sleep.target

  info "Services enabled."

}

enable_services
