#!/bin/bash
# chroot-install.sh - Runs inside arch-chroot, configures the new system with packages

source /auto-arch-install/scripts/config.env

bash /auto-arch-install/scripts/05_chroot.sh
bash /auto-arch-install/scripts/06_aur.sh
bash /auto-arch-install/scripts/08_services.sh
