#!/bin/bash
# 05_chroot.sh - Configuration in the new system

source /auto-arch-install/scripts/config.env

# Setting tiemzone
set_timezone() {

  info "Setting timezone to ${TIMEZONE}..."

  ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
  hwclock --systohc

  info "Timezone set."

}

# Setting locale
set_locale() {

  info "Setting locale to ${LOCALE}..."

  sed -i "s/^#${LOCALE}/${LOCALE}/" /etc/locale.gen
  locale-gen
  echo "LANG=${LOCALE}" >/etc/locale.conf

  info "Locale set."

}

# Setting Hostname
set_hostname() {

  info "Setting hostname to ${HOSTNAME}..."

  echo "${HOSTNAME}" >/etc/hostname
  cat >/etc/hosts <<EOF
127.0.0.1     localhost
::1           localhost
127.0.1.1     ${HOSTNAME}.localdomain       ${HOSTNAME}
EOF

  info "Hostname set."

}

# Setting username and it's groups
create_user() {

  info "Creating User ${USERNAME}"
  useradd -m -G wheel,docker,libvirt,input,video,audio,storage,network -s /bin/bash "$USERNAME"

  if [[ $? -ne 0 ]]; then
    warn "useradd failed. Check /auto-arch-install/install.log"
  fi

  info "Setting passwords..."
  echo "root:${ROOT_PASSWORD}" | chpasswd
  echo "${USERNAME}:${USER_PASSWORD}" | chpasswd

  info "Enabling sudo for wheel group..."
  sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
  info "User ${USERNAME} created."
  info "ROOT_PASSWORD length: ${#ROOT_PASSWORD}"
  info "USER_PASSWORD length: ${#USER_PASSWORD}"

}

# Installing packages
install_packages() {

  info "Installing packages from packages.txt..."
  local PACKAGES
  PACKAGES=$(grep -v '^\s*#' /auto-arch-install/packages.txt | grep -v '^\s*$' | tr '\n' ' ')
  pacman -S --needed --noconfirm $PACKAGES 2>&1 | tee -a /auto-arch-install/install.log

  if [[ $? -ne 0 ]]; then
    warn "Package installation failed. Check /auto-arch-install/install.log"
  fi

  info "Packages installed."

}

# Install and configure GRUB
install_grub() {

  info "Installing GRUB bootloader..."

  # Ensure EFI partitions is mounted
  mkdir -p /boot/efi
  mount "$EFI_PART" /boot/efi

  if [[ "$BOOT_MODE" == "UEFI" ]]; then
    grub-install \
      --target=x86_64-efi \
      --efi-directory=/boot/efi \
      --bootloader-id=GRUB \
      --recheck \
      --removable

  else
    grub-install \
      --target=i386-pc \
      --recheck \
      "$DISK"

  fi

  # Enable os-prober for dual boot detection
  sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub

  # Generate GRUB config
  grub-mkconfig -o /boot/grub/grub.cfg

  info "GRUB installed."

}

# Final execution
set_timezone
set_locale
set_hostname
install_packages
create_user
install_grub

info "System configuration complete."
