# Linux scripts

Some scripts end in `_deb` or `_rhel` to specify that they are only for either RHEL or Debian based systems.
However a vast minority of scripts should require this.


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





