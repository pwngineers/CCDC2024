#!/bin/bash

#
# This script disables log in for all other users
# it requires elevated priviledges
#

############# TODO ############ 
#  This script has not been tested
############################### 

set -e

if [ $# = 0 ]; then 
  printf "./reset.sh disable all users, change passwords of select users and reenable them\n"
  printf "usage: ./reset.sh USER1 USER2 USER3 ...\n"
  printf "warning don't ctrl+c in the middle of this script and logout or anything\n"
  exit 1
fi

# disable users who are not us
echo "Locking out all users"
for i in $(getent passwd | cut -d: -f 1); do
    if [ "$i" != $(whoami) ]; then
      usermod --expiredate 1 "$i" 
      printf "Locked out: %s\n" "$i"
    fi
done
echo "Locked out all users"


for i in "$@"; do
  printf "Reset password for %s\n" "$i"
  passwd "$i"
  usermod --expiredate '' "$i" 
  printf "Reenabled %s\n" "$i"
done


