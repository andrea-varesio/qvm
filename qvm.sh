#!/bin/bash

# Define templates to be excluded from global operations
exclude_tmpl=(debian-11 debian-11-minimal fedora-36 fedora-36-minimal)

#########################################################################
# GNU GENERAL PUBLIC LICENSE                                            #
# Version 3, 29 June 2007                                               #
#                                                                       #
# "qvm" - Qubes OS VM multitool                                         #
# Copyright (C) 2022 Andrea Varesio <https://www.andreavaresio.com/>.   #
#                                                                       #
# This program is free software: you can redistribute it and/or modify  #
# it under the terms of the GNU General Public License as published by  #
# the Free Software Foundation, either version 3 of the License, or     #
# (at your option) any later version.                                   #
#                                                                       #
# This program is distributed in the hope that it will be useful,       #
# but WITHOUT ANY WARRANTY; without even the implied warranty of        #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
# GNU General Public License for more details.                          #
#                                                                       #
# You should have received a copy of the GNU General Public License     #
# along with this program.  If not, see <https://www.gnu.org/licenses/>.#
#########################################################################

VERSION=20221213.01

print_help () {
    echo "qvm - Qubes OS VM multitool | version: $VERSION"
    echo 'Copyright (C) 2022 Andrea Varesio <https://www.andreavaresio.com/>'
    echo
    echo "usage: $0 [OPTIONS] [VM | ALL] [COMMAND | UPDATE_PATH]

    options:
    -h          print this help text and exit
    -c          clean VM apt cache and bash history
    -I PACKAGE  install package(s) in VM
    -R PACKAGE  remove package(s) in VM
    -r          launch root shell
    -s          shutdown the VM after execution
    -t          sync VM time
    -U          update VM packages
    -u          update this script (place update in VM@/home/user/qvm.sh)
    -v          enable verbosity
    -w          include Whonix templates in 'ALL' (when performing global operations)

    VM | ALL:   you can define a specific VM or pass 'ALL' to imply all supported templates
    "
}

echo_color () {
    # echo text ($2) with color ($1)
    if [[ "$1" == "BLUE" ]]; then color='\033[1;36m'; fi
    if [[ "$1" == "GREEN" ]]; then color='\033[1;32m'; fi
    if [[ "$1" == "RED" ]]; then color='\033[1;31m'; fi
    if [[ "$1" == "YELLOW" ]]; then color='\033[1;33m'; fi

    reset='\033[0m'

    echo -e "${color}${2}${reset}"
}

echo_blue () {
    echo_color "BLUE" "$1"
}

echo_green () {
    echo_color "GREEN" "$1"
}

echo_red () {
    echo_color "RED" "$1" >&2
}

echo_yellow () {
    echo_color "YELLOW" "$1" >&2
}

run_checks () {
    # Check required argument
    if [[ -z "$1" ]]; then echo_red "Missing required argument!"; print_help; exit 2; fi

    # Check if help was requested
    if [[ "$1" == "-h" || "$1" == "h" || "$1" =~ "help" ]]; then print_help; exit 0; fi

    # Check VM argument
    arg_last="${@: -1}"
    arg_last_1="${@: -2:1}"
    if qvm-ls "$arg_last" &> /dev/null || [[ "$arg_last" == "ALL" ]]; then VM="$arg_last"
    elif qvm-ls "$arg_last_1" &> /dev/null || [[ "$arg_last_1" == "ALL" ]]; then VM="$arg_last_1"; VM_CMD="$arg_last"
    else echo_red "VM does NOT exists!" >&2; exit 1
    fi

    # Print warning if a command was requested unnecessarily
    if [[ $root_shell == 1 && -n "$VM_CMD" ]]; then
        echo_yellow "COMMAND will NOT be executed since a root shell was requested!"
    fi 
}

check_tmpl () {
    # Check if the operation should run on a Whonix VM
    if [[ $whonix != 1 && "${1:0:6}" == "whonix" ]]; then local exit_code=1; fi

    # Check whether or not VM ($1) is included in $exclude_tmpl
    if [[ $exit_code != 1 ]]; then
        for tmpl in "${exclude_tmpl[@]}"; do
            if [[ "$1" == "$tmpl" ]]; then
                local exit_code=1
                break
            else 
                local exit_code=0
            fi
        done
    fi

    return "$exit_code"
}

run_cmd () {
    # Run command in VM
    if qvm-run -p -u root "$VM" "$1"; then
        if [[ $verbose == 1 ]]; then echo_blue "VM COMMAND completed:"; echo "$1"; fi
    else
        echo_red "VM COMMAND failed!"
        echo_yellow "$1"
    fi
}

run_cmd_quiet () {
    # Run command in VM with no visible output
    if qvm-run -u root "$VM" "$1" &> /dev/null; then
        if [[ $verbose == 1 ]]; then echo_blue "VM COMMAND completed:"; echo "$1"; fi
    else 
        echo_red "VM COMMAND failed!"
        echo_yellow "$1"
    fi
}

run_cmd_single () {
    # Check if loop is required
    if [[ "$VM" == "ALL" ]]; then
        for VM in $TMPL_LIST; do
            if check_tmpl "$VM"; then
                echo_blue "Processing: $VM"
                run_cmd "$1"
                qvm-shutdown "$VM"
            fi
        done
        exit 0
    else
        run_cmd "$1"
    fi
}

update_script () {
    # Update this script
    if [[ -n "$VM_CMD" ]]; then update_path="$VM_CMD"; else update_path=/home/user/qvm.sh; fi

    if qvm-run "$VM" "cat $update_path" &> /dev/null; then run_cmd "cat $update_path" > "$0"; echo_green "Update complete."
    else echo_red "File could NOT be found in specified path! $update_path"; echo_red "Update failed!"
    fi
}

launch_shell () {
    # Launch shell in VM
    if qvm-run "$VM" 'type gnome-terminal' &> /dev/null; then term_cmd=gnome-terminal
    elif qvm-run "$VM" 'type xfce4-terminal' &> /dev/null; then term_cmd=xfce4-terminal
    else term_cmd=xterm
    fi

    run_cmd_quiet $term_cmd

    if [[ $vm_cleaning == 1 || $vm_shutdown == 1 ]] && [[ "$term_cmd" == "gnome-terminal" ]]; then
        read -r -p "Press [Enter] to continue..."
    fi

    if [[ $vm_cleaning == 1 ]]; then clean_vm; fi
    if [[ $vm_shutdown == 1 ]]; then shutdown_vm; fi
}

update_packages () {
    run_update () {
        # Update VM packages 
        if [[ $verbose == 1 ]]; then run_cmd "apt update"; else run_cmd_quiet "apt update"; fi
        run_cmd "apt upgrade -y"
        if [[ $verbose == 1 ]]; then run_cmd "apt autoremove -y"; else run_cmd_quiet "apt autoremove -y"; fi
        run_cmd_quiet "apt clean";
    }

    # Check if loop is required
    if [[ "$VM" == "ALL" ]]; then
        for VM in $TMPL_LIST; do
            if check_tmpl "$VM"; then
                echo_blue "Processing: $VM"
                run_update
                qvm-shutdown "$VM"
            fi
        done
        exit 0
    else
        run_update "$VM"
    fi
}

install_packages () {
    run_install () {
        # Install packages ($1)
        update_packages
        run_cmd "apt install -y --no-install-recommends $1"
        run_cmd_quiet "apt clean"
    }

    # Check if loop is required
    if [[ "$VM" == "ALL" ]]; then
        for VM in $TMPL_LIST; do
            if check_tmpl "$VM"; then
                echo_blue "Processing: $VM"
                run_install "$1"
                qvm-shutdown "$VM"
            fi
        done
        exit 0
    else
        run_install "$1"
    fi
}

remove_packages () {
    run_purge () {
        # Purge packages ($1)
        run_cmd "apt purge -y $1"
        run_cmd_quiet "apt autoremove -y"
        run_cmd_quiet "apt clean"
    }

    # Check if loop is required
    if [[ "$VM" == "ALL" ]]; then
        for VM in $TMPL_LIST; do
            if check_tmpl "$VM"; then
                echo_blue "Processing: $VM"
                run_purge "$1"
                qvm-shutdown "$VM"
            fi
        done
        exit 0
    else
        run_purge "$1"
    fi
}

clean_vm () {
    # Clean VM cache
    run_cmd "apt clean &> /dev/null; rm -rf /root/.bash_history /root/.cache /home/user/.bash_history /home/user/.cache"
}

shutdown_vm () {
    # Shutdown VM
    if qvm-shutdown --force "$VM"; then
        if [[ $verbose == 1 ]]; then echo_blue "VM shutdown completed."; fi
    fi
}

main () {
    while getopts hcI:R:rstuUvw option; do 
        case "${option}" in
            h)print_help; exit 0;;
            c)vm_cleaning=1;;
            I)new_packages="$OPTARG";;
            R)rem_packages="$OPTARG";;
            r)root_shell=1;;
            s)vm_shutdown=1;;
            t)sync_clock=1;;
            u)update=1;;
            U)update_vm=1;;
            v)verbose=1;;
            w)whonix=1;;
            *) echo invalid argument >&2; exit 1;;
        esac
    done

    TMPL_LIST="$(qvm-ls -O NAME,CLASS | grep TemplateVM | awk '{print $1}')"

    run_checks "$@"

    if [[ $update == 1 ]]; then update_script; exit 0; fi
    if [[ $root_shell == 1 ]]; then launch_shell; exit 0; fi
    if [[ $sync_clock == 1 ]]; then sudo qvm-sync-clock; sleep 2; run_cmd_quiet "qvm-sync-clock"; fi
    if [[ -n "$VM_CMD" ]]; then run_cmd_single "$VM_CMD"; fi
    if [[ $update_vm == 1 ]]; then update_packages; fi
    if [[ -n "$new_packages" ]]; then install_packages "$new_packages"; fi
    if [[ -n "$rem_packages" ]]; then remove_packages "$rem_packages"; fi
    if [[ $vm_cleaning == 1 ]]; then clean_vm; fi
    if [[ $vm_shutdown == 1 ]]; then shutdown_vm; fi

    if [[ $verbose == 1 ]]; then echo_green "All requests completed."; fi
}

main "$@"