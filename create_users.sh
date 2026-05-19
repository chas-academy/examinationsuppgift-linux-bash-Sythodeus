#!/bin/bash
 
# create_users.sh
# Script that creates users, sets up home directories, assigns folders,
# and generates a personal welcome file for each user.
# Usage: ./create_users.sh Anna Bjorn Charlie
# Must be run as root.
 
# -----------------------------------------------
# 1. Check that the script is run as root (UID 0)
# -----------------------------------------------
if [ "$EUID" -ne 0 ]; then
  echo "Error: This script must be run as root. Use sudo." >&2
  exit 1
fi
 
# -----------------------------------------------
# 2. Check that at least one username was provided
# -----------------------------------------------
if [ "$#" -eq 0 ]; then
  echo "Error: No usernames provided." >&2
  echo "Usage: $0 <user1> <user2> ..." >&2
  exit 1
fi
 
# -----------------------------------------------
# 3. First pass: create all users and folders
# -----------------------------------------------
for USERNAME in "$@"; do
 
  echo "--- Processing user: $USERNAME ---"
 
  # Create the user with a home directory (-m flag)
  if id "$USERNAME" &>/dev/null; then
    echo "  User '$USERNAME' already exists. Skipping creation."
  else
    useradd -m "$USERNAME"
    echo "  User '$USERNAME' created."
  fi
 
  # Define the home directory path
  HOME_DIR="/home/$USERNAME"
 
  # -----------------------------------------------
  # 4. Create required subdirectories
  # -----------------------------------------------
  for DIR in Documents Downloads Work; do
    mkdir -p "$HOME_DIR/$DIR"
    echo "  Created folder: $HOME_DIR/$DIR"
  done
 
  # -----------------------------------------------
  # 5. Set permissions — only the owner can read/write/execute
  # -----------------------------------------------
  chmod 700 "$HOME_DIR/Documents"
  chmod 700 "$HOME_DIR/Downloads"
  chmod 700 "$HOME_DIR/Work"
 
  # Also ensure the home directory itself is owned by the user
  chown -R "$USERNAME":"$USERNAME" "$HOME_DIR"
  echo "  Permissions set (700) for Documents, Downloads, Work."
 
done
 
# -----------------------------------------------
# 6. Second pass: create welcome.txt after ALL users exist
# -----------------------------------------------
for USERNAME in "$@"; do
 
  HOME_DIR="/home/$USERNAME"
  WELCOME_FILE="$HOME_DIR/welcome.txt"
 
  # First line: personal greeting
  echo "Välkommen $USERNAME" > "$WELCOME_FILE"
 
  # Blank line for readability
  echo "" >> "$WELCOME_FILE"
 
  # List all other existing users from /etc/passwd (excluding current user)
  echo "Andra användare på systemet:" >> "$WELCOME_FILE"
  awk -F: -v me="$USERNAME" '$1 != me { print "  - " $1 }' /etc/passwd >> "$WELCOME_FILE"
 
  # Set ownership of welcome.txt to the new user
  chown "$USERNAME":"$USERNAME" "$WELCOME_FILE"
  echo "  welcome.txt created at $WELCOME_FILE"
 
  echo "  Done with $USERNAME."
  echo ""
 
done
 
echo "All users processed successfully."
