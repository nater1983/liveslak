#!/bin/bash

# Exit if not running as root
if [ "$EUID" -ne 0 ]; then
    dialog --title "Permission Denied" \
           --msgbox "You must run this script as root.\n\nPlease re-run with sudo or as root." 8 50
    clear
    exit 1
fi

tempfile=$(mktemp)
trap "rm -f $tempfile" EXIT

liveslak_dir="/opt/htdocs/linux/liveslak"
slackware_dir="$liveslak_dir/slackware64-current"

# Remove slackware64-current if older than 24 hours
if [ -d "$slackware_dir" ]; then
    dir_mtime=$(stat -c %Y "$slackware_dir")
    now=$(date +%s)
    age=$(( now - dir_mtime ))
    if [ "$age" -ge 86400 ]; then
        dialog --infobox "Removing old slackware64-current (older than 24 hours)..." 5 60
        rm -fr "$slackware_dir"
        sleep 1
    else
        dialog --infobox "Existing slackware64-current is less than 24 hours old, keeping it." 5 60
        sleep 1
    fi
fi

run_build_script() {
    local script_name=$1
    local log_file=$2

    cd /opt/htdocs/linux/liveslak || {
        dialog --msgbox "Failed to change directory to /opt/htdocs/linux/liveslak" 7 50
        return 1
    }

    if [ -x "./$script_name" ]; then
        sh "$script_name" | tee "$log_file"
        dialog --textbox "$log_file" 20 70
    else
        dialog --msgbox "$script_name not found or not executable!" 7 50
    fi
}

while true; do
    dialog --clear --title "Liveslak Build Menu" \
    --menu "Choose a desktop environment to prepare:" 15 70 6 \
    1 "GNOME - Prepare and build liveslak" \
    2 "Pantheon (Elementary OS) - Prepare and build liveslak" \
    3 "Cosmic - Prepare and build liveslak" \
    4 "Exit" 2>"$tempfile"

    choice=$(<"$tempfile")

    case $choice in
        1)
            dialog --infobox "Preparing GNOME liveslak build..." 5 50
            sleep 1

            src_base="/opt/htdocs/linux"
            gnome_base="/opt/htdocs/mirror/slackware"
            liveslak_dir="$src_base/liveslak"
            env_src="$gnome_base/gnome"
            env_dest="$liveslak_dir/slackware64-current/slackware64"
            env_dest2="$liveslak_dir/slackware64-current/slackware64/gnome"
            tag_src="$liveslak_dir/gfs-tagfile"
            tag_dest="$env_dest2/tagfile"

            cp -av "$src_base/slackware64-current" "$liveslak_dir" | tee /tmp/gnome_copy.log
            mkdir -p "$env_dest/{gnome,pkg}"
            cp -av "$gnome_base/pkg/*" "$env_dest/pkg" | tee /tmp/gnome_copy.log
            cp -av "$env_src"/* "$env_dest/gnome" | tee -a /tmp/gnome_copy.log
            cp -av "$tag_src" "$tag_dest" | tee -a /tmp/gnome_copy.log

            dialog --msgbox "GNOME files copied successfully.\n\nStarting make_slackware_gfs.sh..." 8 60
            run_build_script "make_slackware_gfs.sh" /tmp/make_gfs.log
            ;;
        2)
            dialog --infobox "Preparing Pantheon (Elementary OS) liveslak build..." 5 60
            sleep 1

            src_base="/opt/htdocs/linux"
            pantheon_base="/opt/htdocs/mirror/slackware"
            liveslak_dir="$src_base/liveslak"
            env_src="$pantheon_base/pantheon"
            env_dest="$liveslak_dir/slackware64-current/slackware64"
            env_dest2="$liveslak_dir/slackware64-current/slackware64/elem"
            tag_src="$liveslak_dir/elem-tagfile"
            tag_dest="$env_dest2/tagfile"

            cp -av "$src_base/slackware64-current" "$liveslak_dir" | tee /tmp/pantheon_copy.log
            mkdir -p "$env_dest/{elem,pkg}"
            cp -av "$pantheon_base/pkg/*" "$env_dest/pkg" | tee /tmp/pantheon_copy.log
            cp -av "$env_src"/* "$env_dest/elem" | tee -a /tmp/pantheon_copy.log
            cp -av "$tag_src" "$tag_dest" | tee -a /tmp/pantheon_copy.log

            dialog --msgbox "Pantheon (Elem) files copied successfully.\n\nStarting make_slackware_elem.sh..." 8 60
            run_build_script "make_slackware_elem.sh" /tmp/make_elem.log
            ;;
        3)
            dialog --infobox "Preparing Cosmic liveslak build..." 5 50
            sleep 1

            src_base="/opt/htdocs/linux"
            cosmic_base="/opt/htdocs/mirror/slackware"
            liveslak_dir="$src_base/liveslak"
            env_src="$cosmic_base/cosmic"
            env_dest="$liveslak_dir/slackware64-current/slackware64"
            env_dest2="$liveslak_dir/slackware64-current/slackware64/cosmic"
            tag_src="$liveslak_dir/cosmic-tagfile"
            tag_dest="$env_dest2/tagfile"

            cp -av "$src_base/slackware64-current" "$liveslak_dir" | tee /tmp/cosmic_copy.log
            mkdir -p "$env_dest/{cosmic,pkg}"
            cp -av "$cosmic_base/pkg/*" "$env_dest/pkg" | tee /tmp/pantheon_copy.log
            cp -av "$env_src"/* "$env_dest/cosmic" | tee -a /tmp/cosmic_copy.log
            cp -av "$tag_src" "$tag_dest" | tee -a /tmp/cosmic_copy.log

            dialog --msgbox "Cosmic files copied successfully.\n\nStarting make_slackware_cosmic.sh..." 8 60
            run_build_script "make_slackware_cosmic.sh" /tmp/make_cosmic.log
            ;;
        4)
            clear
            exit 0
            ;;
        *)
            break
            ;;
    esac
done
