#!/bin/bash
# 03_disk.sh - Disk detecting, partitioning, formatting and mounting

source "$(dirname "$0")/config.env"

# Checks for available disks
detect_disk() {

  info "Detecting available disks..."
  local DISKS
  DISKS=$(lsblk -dpno NAME,SIZE,TYPE | grep "disk" | grep -v "loop")

  local DISK_COUNT
  DISK_COUNT=$(echo "$DISKS" | wc -l)

  if [[ -z "$DISKS" ]]; then
    error "No disks detected."
  fi

  if [[ "$DISK_COUNT" -eq 1 ]]; then
    DISK=$(echo "$DISKS" | awk '{print $1}')
    info "Only one disk detected, using: ${DISK}"

  else
    info "Multiple disks detected:"
    echo "$DISKS" | nl -w2 -s') '
    info "Enter the number of the disk to install Arch on:"
    read -r DISK_NUM
    DISK=$(echo "$DISKS" | sed -n "${DISK_NUM}p" | awk '{print $1}')

    if [[ -z "$DISK" ]]; then
      error "Invalid selection."
    fi

    info "Selected disk: ${DISK}"
  fi

  echo "DISK=${DISK}" >>"$(dirname "$0")/config.env"
}

# Selecting install type
get_install_type() {

  info "Select Install type:"
  echo " 1) Fresh Install (Wipe Entire Disk)"
  echo " 2) Dual boot (Keep Existing Partitions)"
  read -r INSTALL_TYPE

  case "$INSTALL_TYPE" in
    1)
      INSTALL_TYPE="fresh"
      info "Fresh install selected"
      ;;

    2)
      INSTALL_TYPE="dualboot"
      info "Dual boot selected."
      ;;

    *)
      error "Invalid selection. Please enter 1 or 2."
      ;;

  esac

  echo "INSTALL_TYPE=${INSTALL_TYPE}" >>"$(dirname "$0")/config.env"

}

# Prompting to type a swap size
get_swap_size() {

  local RAM_SIZE
  RAM_SIZE=$(free -h | awk '/^Mem:/ {print $2}')

  info "Your total RAM is: ${RAM_SIZE}"

  while true; do

    info "Enter swap size in GB (default: 0, recommended: match your RAM):"
    read -r SWAP_SIZE
    SWAP_SIZE="${SWAP_SIZE:-0}"

    if [[ ! "$SWAP_SIZE" =~ ^[0-9]+$ ]]; then
      error "Swap size must be a number."
      continue
    fi

    if [[ "$SWAP_SIZE" -eq 0 ]]; then
      warn "Swap disabled."
      echo "SWAP_SIZE=0" >>"$(dirname "$0")/config.env"
      return
    fi

    if [[ "$SWAP_SIZE" -gt 32 ]]; then
      warn "Swap size is larger than 32GB. Are you sure? (y/n)"
      read -r CONFIRM

      if [[ "$CONFIRM" != "y" ]]; then
        error "Aborted. Please re-run and enter a smaller swap size."
        continue
      fi
    fi

    break
  done

  echo "SWAP_SIZE=${SWAP_SIZE}" >>"$(dirname "$0")/config.env"
  info "Swap size set to: ${SWAP_SIZE}GB"

}

# Confirms and wipes disk
confirm_and_wipe() {

  info "The following disk will be wiped:"
  echo
  lsblk -o NAME,SIZE,TYPE,MOUNTPOINT "$DISK"
  echo
  warn "ALL DATA ON ${DISK} WILL BE PERMANENTLY DESTROYED."
  warn "This cannot be undone. Are you sure? (type YES in captials to confirm):"
  read -r CONFIRM

  if [[ "$CONFIRM" != "YES" ]]; then
    error "Aborted by user."
  fi

  info "Wiping disk ${DISK}..."
  wipefs -af "$DISK"
  sgdisk -Z "$DISK"
  info "Disk wiped."

}

# Partitioning fresh install
partition_fresh() {

  info "Partitioning ${DISK}"

  if [[ "$BOOT_MODE" == "UEFI" ]]; then
    parted -s "$DISK" mklabel gpt
    parted -s "$DISK" mkpart primary fat32 1MiB 513MiB
    parted -s "$DISK" set 1 esp on
    parted -s "$DISK" mkpart primary btrfs 513MiB 100%

  else
    parted -s "$DISK" mklabel msdos
    parted -s "$DISK" mkpart primary fat32 1MiB 513MiB
    parted -s "$DISK" mkpart primary btrfs 513MiB 100%
    parted -s "$DISK" set 1 boot on

  fi

  if [[ "$DISK" == *"nvme"* ]] || [[ "$DISK" == *"mmcblk"* ]]; then
    EFI_PART="${DISK}p1"
    ROOT_PART="${DISK}p2"

  else
    EFI_PART="${DISK}1"
    ROOT_PART="${DISK}2"

  fi

  echo "EFI_PART=${EFI_PART}" >>"$(dirname "$0")/config.env"
  echo "ROOT_PART=${ROOT_PART}" >>"$(dirname "$0")/config.env"

  info "Partitioning complete."
  info "EFI partition: ${EFI_PART}"
  info "ROOT partition: ${ROOT_PART}"

}

# Partitioning for dual boot
partition_dualboot() {

  info "Current partition layout on ${DISK}:"
  echo
  lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT "$DISK"
  echo

  # Detecting free space
  info "Detecting unallocated free space..."

  local FREE_SPACE
  FREE_SPACE=$(parted -s "$DISK" unit MiB print free | grep "Free Space" | tail -n 1)

  if [[ -z "$FREE_SPACE" ]]; then
    error "No unallocated free space found on ${DISK}. Please free up space and try again."
  fi

  local FREE_START FREE_END FREE_SIZE
  FREE_START=$(echo "$FREE_SPACE" | awk '{print $1}' | tr -d 'MiB')
  FREE_END=$(echo "$FREE_SPACE" | awk '{print $2}' | tr -d 'MiB')
  FREE_SIZE=$(echo "$FREE_SPACE" | awk '{print $3}' | tr -d 'MiB')

  info "Found ${FREE_SIZE}MiB of free space starting at ${FREE_START}MiB"

  # Check if free space is more the minimum
  local MIN_SIZE
  MIN_SIZE=$((512 + 20480 + (SWAP_SIZE * 1024)))

  if [[ "${FREE_SIZE%.*}" -lt "$MIN_SIZE" ]]; then
    error "Not enough free space. Need at least ${MIN_SIZE}MiB (512MiB EFI + 20GB root + ${SWAP_SIZE}GB swap). Found ${FREE_SIZE}MiB"
  fi

  # Get next available partition number
  local EFI_PART_NUM
  EFI_PART_NUM=$(parted -s "$DISK" print | grep -E "^\s+[0-9]+" | tail -n 1 | awk '{print $1}')
  EFI_PART_NUM=$((EFI_PART_NUM + 1))

  # Claculate partition boundaries
  local EFI_START EFI_END ROOT_START ROOT_END
  EFI_START="$FREE_START"
  EFI_END=$(echo "$FREE_START + 512" | bc)
  ROOT_START=$(echo "$EFI_END + 1" | bc)
  ROOT_END="$FREE_END"

  # Confirming partitions
  echo
  info "The following partition will be created on ${DISK}:"
  echo "EFI: ${EFI_START}MiB -> ${EFI_END}MiB (512MiB)"
  echo "Root: ${ROOT_START}MiB -> ${ROOT_END}MiB (Remaining space)"
  echo
  warn "Existing partitions will NOT be touched."
  warn "Are you sure you want to proceed? (type YES in capitals to confirm):"
  read -r CONFIRM

  if [[ "$CONFIRM" != "YES" ]]; then
    error "Aborted by user."
  fi

  # Partitions creations
  info "Creating Partitions..."

  if [[ "$BOOT_MODE" == "UEFI" ]]; then
    parted -s "$DISK" mkpart primary fat32 "${EFI_START}MiB" "${EFI_END}MiB"
    parted -s "$DISK" set "$EFI_PART_NUM" esp on
    parted -s "$DISK" mkpart primary btrfs "${ROOT_START}MiB" "${ROOT_END}MiB"

  else
    parted -s "$DISK" mkpart primary fat32 "${EFI_START}MiB" "${EFI_END}MiB"
    parted -s "$DISK" mkpart primary btrfs "${ROOT_START}MiB" "${ROOT_END}MiB"
    parted -s "$DISK" set "$EFI_PART_NUM" boot on

  fi

  # Detect partition names
  if [[ "$DISK" == *"nvme"* ]] || [[ "$DISK" == *"mmcblk"* ]]; then
    EFI_PART="${DISK}p${EFI_PART_NUM}"
    ROOT_PART="${DISK}p$((EFI_PART_NUM + 1))"

  else
    EFI_PART="${DISK}${EFI_PART_NUM}"
    ROOT_PART="${DISK}$((EFI_PART_NUM + 1))"

  fi

  echo "EFI_PART=${EFI_PART}" >>"$(dirname "$0")/config.env"
  echo "ROOT_PART=${ROOT_PART}" >>"$(dirname "$0")/config.env"

  info "Partitioning complete."
  info "EFI partition: ${EFI_PART}"
  info "Root partition: ${ROOT_PART}"

}

# Partitions formatting
format_partitions() {

  info "Formatting partitions..."

  info "Formatting EFI partition ${EFI_PART} as fat32..."
  mkfs.fat -F32 "$EFI_PART"

  info "Formatting root partitions ${ROOT_PART} as btrfs..."
  mkfs.btrfs -f "$ROOT_PART"

  info "Formatting complete."

}

# Creating Swap, root, home, snapshots subvloumes
create_subvolumes() {

  info "Creating btrfs subvolumes..."

  # Temporary mount for creating root subvolume
  mount "$ROOT_PART" /mnt

  btrfs subvolume create /mnt/@
  btrfs subvolume create /mnt/@home
  btrfs subvolume create /mnt/@snapshots
  btrfs subvolume create /mnt/@swap

  umount /mnt

  info "Subvolumes created."

}

# Mounting the formatted partitions
mount_partitions() {

  info "Mounting partitions..."

  # Mount root of subvolumes``
  mount -o subvol=@,compress=zstd,noatime "$ROOT_PART" /mnt

  # Create mount points
  mkdir -p /mnt/{home,.snapshots,swap,boot/efi}

  # Mount the subvolumes
  mount -o subvol=@home,compress=zstd,noatime "$ROOT_PART" /mnt/home
  mount -o subvol=@snapshots,compress=zstd,noatime "$ROOT_PART" /mnt/.snapshots
  mount -o subvol=@swap "$ROOT_PART" /mnt/swap

  # Mounting EFI Partition
  mount "$EFI_PART" /mnt/boot/efi

  if [[ "$SWAP_SIZE" -gt 0 ]]; then
    info "Creating swapfile of ${SWAP_SIZE}GB..."
    btrfs filesystem mkswapfile --size "${SWAP_SIZE}g" /mnt/swap/swapfile
    swapon /mnt/swap/swapfile
    info "Swapfile created and enabled."
  fi

  info "All partitions mounted."

}

# Final execution for the Disk setup

detect_disk
get_install_type
get_swap_size

if [[ "$INSTALL_TYPE" == "fresh" ]]; then
  confirm_and_wipe
  partition_fresh

else
  partition_dualboot

fi

format_partitions
create_subvolumes
mount_partitions

info "Disk setup complete."
