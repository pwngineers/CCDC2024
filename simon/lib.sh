RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

check() {
    name="$1"
    shift

    eval "$@"
    code=$?
    [ $code != 0 ] && printf "${RED}FAILED: $name$NC\n" >&2 && return $code
    printf "${GREEN}pass: $name$NC\n" >&2
}
