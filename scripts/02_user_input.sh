#!/bin/bash
# 02_user_input.sh - Collect all user configuration before installations

source "$(dirname "$0")/config.env"

# Setting the hostname
get_hostname() {

  while true; do

    info "Enter hostname for this machine:"
    read -r HOSTNAME

    if [[ -z "$HOSTNAME" ]]; then
      warn "Hostname cannot be empty. Please try again."
      continue
    fi

    if [[ ! "$HOSTNAME" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$ ]]; then
      warn "Hostname can only contain letters, numbers, hyphens. Cannot start or end with a hyphen. Max 63 characters. Please try again."
      continue
    fi
    break

  done

  echo "HOSTNAME=${HOSTNAME}" >>"$(dirname "$0")/config.env"
  info "Hostname set to: ${HOSTNAME}"

}

# Setting the username
get_username() {

  while true; do

    info "Enter username:"
    read -r USERNAME

    if [[ -z "$USERNAME" ]]; then
      warn "Username cannot be empty. Please try again."
      continue
    fi

    if [[ ! "$USERNAME" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]]; then
      warn "Username can only contain lowercase letters, numbers, hyphens, underscores. Must start with a letter or underscore. Max 32 characters. Please try again."
      continue
    fi

    break

  done

  echo "USERNAME=${USERNAME}" >>"$(dirname "$0")/config.env"
  info "Username set to: ${USERNAME}"

}

# Setting the root password
get_root_password() {

  while true; do

    info "Enter root password:"
    read -rs ROOT_PASSWORD
    echo

    if [[ -z "$ROOT_PASSWORD" ]]; then
      warn "Root password cannot be empty. Please try again."
      continue
    fi

    info "Confirm root password:"
    read -rs ROOT_PASSWORD_CONFIRM
    echo

    if [[ "$ROOT_PASSWORD" != "$ROOT_PASSWORD_CONFIRM" ]]; then
      warn "Root passwords do not match. Please try again."
      continue
    fi

    break

  done

  echo "ROOT_PASSWORD=${ROOT_PASSWORD}" >>"$(dirname "$0")/config.env"
  info "Root password set."

}

# Setting the user password
get_user_password() {

  while true; do

    info "Enter password for ${USERNAME}:"
    read -rs USER_PASSWORD
    echo

    if [[ -z "$USER_PASSWORD" ]]; then
      warn "User password cannot be empty. Please try again."
    fi

    info "Confirm password for ${USERNAME}:"
    read -rs USER_PASSWORD_CONFIRM
    echo

    if [[ "$USER_PASSWORD" != "$USER_PASSWORD_CONFIRM" ]]; then
      warn "User passwords do not match. Please try again."
    fi

    break

  done

  echo "USER_PASSWORD=${USER_PASSWORD}" >>"$(dirname "$0")/config.env"
  info "User password set."

}

# Setting the timezone
get_timezone() {

  while true; do

    info "Enter timezone (e.g. Asia/Kolkata, Europe/London), (default: Asia/Kolkata):"
    info "Full list: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones"
    read -r TIMEZONE
    TIMEZONE="${TIMEZONE:-Asia/Kolkata}"

    if ! timedatectl list-timezones | grep -qx "$TIMEZONE"; then
      warn "Invalid timezone: ${TIMEZONE}. Please try again."
      continue
    fi

    break

  done

  echo "TIMEZONE=${TIMEZONE}" >>"$(dirname "$0")/config.env"
  info "Timezone set to: ${TIMEZONE}"

}

# Setting the locale
get_locale() {

  while true; do

    info "Enter locale (e.g. en_US.UTF-8, en_IN.UTF-8), (default: en_US.UTF-8):"
    read -r LOCALE
    LOCALE="${LOCALE:-en_US.UTF-8}"

    if ! grep -q "^#\?$(echo $LOCALE | sed 's/\./\\./g')" /etc/locale.gen; then
      warn "Invlaid locale: ${LOCALE}. Please try again."
      continue
    fi

    break

  done

  echo "LOCALE=${LOCALE}" >>"$(dirname "$0")"/config.env
  info "Locale set to: ${LOCALE}"

}

# Run the script for taking inputs
get_hostname
get_username
get_root_password
get_user_password
get_timezone
get_locale

info "All user configuration collected."
