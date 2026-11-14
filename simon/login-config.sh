#!/bin/sh

source "$(dirname $(readlink $0))/lib.sh"

for d in $(getent passwd | cut -d: -f6 | uniq); do
    check "ssh keys in $d" "test -e $d/.ssh/authorized_keys"
done

check "pam has nullok" "grep -R nullok /etc/pam.d"
check "pam has unconditional permit" "grep -ER '(auth|account|session).*pam_permit' /etc/pam.d"
