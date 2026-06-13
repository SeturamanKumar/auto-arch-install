#!/bin/bash
# 06_aur.sh - Install yay and AUR packages

source /auto-arch-install/scripts/config.env

# Create a temporary build user for installing aur packages
create_build_user() {

  info "Creating temporary build user..."

  useradd -m -d /tmp/aur-build -s /bin/bash builduser
  echo "builduser ALL=(ALL) NOPASSWD: ALL" >/etc/sudoers.d/builduser

  info "Build user created."

}

# Install yay
install_yay() {

  info "Installing yay AUR helper..."

  sudo -u builduser bash -c "
    cd /tmp/aur-build &&
    git clone https://aur.archlinux.org/yay.git &&
    cd yay &&
    makepkg -si --noconfirm
  "

  info "yay installed."

}

# Install AUR packages
install_aur_packages() {

  info "Installing AUR packages..."

  local AUR_PACKAGES
  AUR_PACKAGES=$(grep -v '^\s*#' /auto-arch-install/aur_packages.txt | grep -v '^\s*$' | tr '\n' ' ')
  sudo -u builduser bash -c "yay -S --needed --noconfirm $AUR_PACKAGES"

  info "AUR package installed."

}

# Remove the temporary build user
remove_build_user() {

  info "Removing temporary build user..."

  userdel -r builduser
  rm -f /etc/sudoers.s/builduser

  info "Build user removed."

}

# Execute the functions
create_build_user
install_yay
install_aur_packages
remove_build_user

info "AUR setup complete."
