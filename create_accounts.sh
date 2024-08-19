#!/bin/bash

USER_ACCOUNTS_FILE="user_accounts.txt"
ADMIN_ACCOUNTS_FILE="admin_accounts.txt"

# Function to create a user account
create_user() {
  username=$(zenity --entry --title "Create User Account" --text "Enter username:")
  if [ -z "$username" ]; then
    zenity --error --text "Username cannot be empty."
    return
  fi

  # Check if the user already exists
  if grep -q "^$username:" "$USER_ACCOUNTS_FILE"; then
    zenity --error --text "User '$username' already exists."
    return
  fi

  password=""
  while true; do
    password=$(zenity --entry --title "Create User Account" --text "Enter password:" --hide-text)
    [ -z "$password" ] && return  # User cancelled
    if ! check_password_conditions "$password"; then
      zenity --error --text "Password does not meet requirements:\n$password_conditions"
    else
      break
    fi
  done

  # Create the user
  echo "$username:$password" >> "$USER_ACCOUNTS_FILE"
  zenity --info --text "User '$username' has been created."
}

# Function to create an administrator account
create_administrator() {
  adminname=$(zenity --entry --title "Create Administrator Account" --text "Enter administrator username:")
  if [ -z "$adminname" ]; then
    zenity --error --text "Username cannot be empty."
    return
  fi

  # Check if the administrator already exists
  if grep -q "^$adminname:" "$ADMIN_ACCOUNTS_FILE"; then
    zenity --error --text "User '$adminname' already exists."
    return
  fi

  adminpass=""
  while true; do
    adminpass=$(zenity --entry --title "Create Administrator Account" --text "Enter password:" --hide-text)
    [ -z "$adminpass" ] && return  # User canceled
    if ! check_password_conditions "$adminpass"; then
      zenity --error --text "Password does not meet requirements:\n$password_conditions"
    else
      break
    fi
  done

  # Create the administrator
  echo "$adminname:$adminpass" >> "$ADMIN_ACCOUNTS_FILE"
  zenity --info --text "Administrator '$adminname' has been created."
}

# Function to check password conditions
check_password_conditions() {
  local password="$1"
  password_conditions=""
  [ ${#password} -ge 8 ] || password_conditions+="\n- At least 8 characters"
  [ -n "$(echo "$password" | tr -d '[:alnum:]')" ] || password_conditions+="\n- Contain at least one special character"
  [ -n "$(echo "$password" | sed -e 's/[^A-Z]//g')" ] && [ -n "$(echo "$password" | sed -e 's/[^a-z]//g')" ] && [ -n "$(echo "$password" | sed -e 's/[^0-9]//g')" ] || password_conditions+="\n- Include at least one uppercase letter, one lowercase letter, and one digit"
  [ -z "$password_conditions" ] && return 0  # i.e. Password meets all conditions
  return 1  # when Password does not meet all conditions
}

# Main menu
choice=$(zenity --list --title "Account Management" --column "Options" "Create User Account" "Create Administrator Account" "Exit")

case $choice in
  "Create User Account") create_user ;;
  "Create Administrator Account") create_administrator ;;
  "Exit") exit ;;
esac

