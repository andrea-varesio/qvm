# Qubes OS VM multitool

## Installation
Download `qvm.sh` in a VM and location of your choosing. Then move it to `dom0` (change `$source_vm` and `$source_path` accordingly):
```
[user@dom0 ~]$ source_vm=disp1234; source_path=/home/user/qvm.sh
[user@dom0 ~]$ mkdir -p $HOME/.local/bin
[user@dom0 ~]$ qvm-run -p $source_vm "cat $source_path" > $HOME/.local/bin/qvm
```

If you're unable to call the `qvm` command, you may need to add it to `$PATH`:

You can add it to `/etc/environment` (then logout):
```
[user@dom0 ~]$ echo "PATH=$PATH:$HOME/.local/bin" | sudo tee -a /etc/environment &> /dev/null
```
Alternatively, you can add it to `$HOME/.bashrc` (then close the terminal window):
```
[user@dom0 ~]$ echo "PATH=$PATH:$HOME/.local/bin" >> .bashrc
```

## Usage
```
usage: qvm [OPTIONS] [VM | ALL] [COMMAND | UPDATE_PATH]

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
```

## DISCLAIMER
This tool is neither affiliated with nor sponsored by Qubes OS.

## LICENSE
GNU GENERAL PUBLIC LICENSE
Version 3, 29 June 2007

"qvm" - Qubes OS VM multitool<br />
Copyright (C) 2022-2023 Andrea Varesio <https://www.andreavaresio.com/>.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a [copy of the GNU General Public License](https://github.com/andrea-varesio/qvm/blob/main/LICENSE)
along with this program.  If not, see <https://www.gnu.org/licenses/>.