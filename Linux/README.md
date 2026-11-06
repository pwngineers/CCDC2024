# Linux scripts

Some scripts end in `_deb` or `_rhel` to specify that they are only for either RHEL or Debian based systems.
However a vast minority of scripts should require this.

| Script Name | Description | Distro |
| ----------- | ----------- | -- |
| create_backup | Creates a backup of the /etc, /opt, and /var/www directories | Any |
| restore_backup | Restores any backups created with `create_backup` | Any |
| disable_ssh | Disables ssh by removing the ssh Service | Any |
| kill_shells | Kills any remote shells connected to the system by looking at processes | Any |
| disable_users | Disables any users on the system by adding `/nologin` to the users | Any |
| debian_setup | TODO | Debian |
| harden | TODO | TODO |
| change_passwords | TODO | TODO |
| iptablesSetup | TODO | TODO |
| obfuscate_ports | TODO | TODO |
| reset | TODO | TODO |
| run all | TODO | TODO |

# User Management

## Change password
To change a password of a user use
```sh
passwd USERNAME
```
and follow the prompts. A blank input to password does NOT disable the account.

## Disable an account
```bash
usermod --expiredate 1 USERNAME
```
This makes the account expire on Jan 2, 1970. To undo this use TODO

> [!WARNING]
>
> The following works but will not disable the other login methods (eg. ssh): `passwd -l USERNAME`

## List users
```bash
getent passwd
```

List users who may be able to login
```bash
getent passwd | grep -Ev "(/sbin/nologin|/bin/sync)"
```

List Logged in users (yes thats the whole command): 
```bash
w
```

# Network Management (NOT about pa firewall)





