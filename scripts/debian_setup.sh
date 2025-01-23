#!/bin/sh

error() {
	# Log to stderr and exit with failure.
	printf "%s\n" "$1" >&2
	exit 1
}

setup_gateway() {
  $OLDIP=$(ip route list | grep -oE -m 1 "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | head -1)
  $IFACE=$(ip route list | sed -n '/^.*dev\s\+\/\(\w\+\).*$/s//\1/p')
  echo "Setting default gateway from $OLDIP to 172.20.242.150"
  ip route delete default
  ip route add default via 172.20.242.150 dev $IFACE 
}

welcome_msg() {
  whiptail --title "Welcome!" \
    --msgbox "Welcome the the Debian CCDC auto-setup script.\\n\\nPlease let Xander Lewis (lewisxb@rose-hulman.edu) know if anything goes wrong!" 10 60
      whiptail --title "Note!" --yes-button "All ready!" --no-button "Not yet..." --yesno "Be sure you are on one of the debian machines or everything will be utterly broken and completely unsalvageable ): "
}

get_user_and_pass() {
	# Prompts user for new username and password.
	name=$(whiptail --inputbox "First, please enter a name for the user account." 10 60 3>&1 1>&2 2>&3 3>&1) || exit 1
	while ! echo "$name" | grep -q "^[a-z_][a-z0-9_-]*$"; do
		name=$(whiptail --nocancel --inputbox "Username not valid. Give a username beginning with a letter, with only lowercase letters, - or _." 10 60 3>&1 1>&2 2>&3 3>&1)
	done
	pass1=$(whiptail --nocancel --passwordbox "Enter a password for that user." 10 60 3>&1 1>&2 2>&3 3>&1)
	pass2=$(whiptail --nocancel --passwordbox "Retype password." 10 60 3>&1 1>&2 2>&3 3>&1)
	while ! [ "$pass1" = "$pass2" ]; do
		unset pass2
		pass1=$(whiptail --nocancel --passwordbox "Passwords do not match.\\n\\nEnter password again." 10 60 3>&1 1>&2 2>&3 3>&1)
		pass2=$(whiptail --nocancel --passwordbox "Retype password." 10 60 3>&1 1>&2 2>&3 3>&1)
	done
}

user_check() {
	! { id -u "$name" >/dev/null 2>&1; } ||
		whiptail --title "WARNING" --yes-button "CONTINUE" \
			--no-button "No wait..." \
			--yesno "The user \`$name\` already exists on this system. This script can install for a user already existing, but it will OVERWRITE any conflicting settings on the user account.\\n\\nNote also that this script will change $name's password to the one you just gave." 14 70
}

add_user_and_pass() {
	# Adds user `$name` with password $pass1.
	whiptail --infobox "Adding user \"$name\"..." 7 50
	useradd -m -g wheel -s /bin/sh "$name" >/dev/null 2>&1 ||
		usermod -a -G wheel "$name" && mkdir -p /home/"$name" && chown "$name":wheel /home/"$name"
	export repodir="/home/$name/.local/src"
	mkdir -p "$repodir"
	chown -R "$name":wheel "$(dirname "$repodir")"
	echo "$name:$pass1" | chpasswd
	unset pass1 pass2
}

finalize() {
	whiptail --title "All done!" \
		--msgbox "Congrats! Provided there were no hidden errors, the script completed successfully! \o/" 13 80
}

echo "Setting up internet connection"

# Install whiptail, CRUCIAL
apt install -y libnewt-dev ||
	error "Are you sure you're running this as the root user? Couldn't install newt..."

# Welcome user and pick dotfiles.
welcome_msg || error "User exited."

# Get and verify username and password.
get_user_and_pass || error "User exited."

# Give warning if user already exists.
user_check || error "User exited."

# Add user.
add_user_and_pass || error "Error adding username and/or password."

# All done.
finalize
