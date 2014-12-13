#!/bin/bash
##
##
##  Script to backup files and folders.
##
##

### Define some versioning variables.
PKG='backup'
VERSION='__version'
VDATE='__vdate'

### Set modes and traps.
set -o errexit

trap "cleanup 'Aborting\n'" ERR
trap "cleanup 'Terminated by user\n'" SIGINT SIGTERM SIGKILL
trap cleanup EXIT

### Define functions.
## Create folder on /tmp and return the path.
tempdir() {
    local dir="arch-$(date "+%Y-%m-%d")"
    local path="/tmp/${dir}"

    mkdir ${path}
    echo ${path}
}
## Use rsync to sync files.
bkp() {
    local SRC="${1}"
    local DEST="${2}"
    declare -a OPTS=("${!3}")

    printf "Sync %s\n" ${SRC}
    rsync "${OPTS[@]}" ${SRC} ${DEST} 2>/dev/null
    sleep 3
    printf "Done\n"
}

## Create a tar file with a README inside.
readme() {
    local TMP="${1}"

    cat <<-INFO > ${TMP}/README
Configuration files and folders.

The name of the folder here tells you were the config files goes!
    * dot = home folder, hidden files they are.
    * config = .config folder, put them where they belong.
    * localshare = .local/share, an unusual place to these important ones.
    * etc = these goes to /etc, be root to place them.

Now you know everything you should, restore your things! ;)
INFO

    tar -cf ${TMP}.tar --directory=${TMP} README
}

## Pack dotfiles in a nice tar file.
dot() {
    local MODE="${1}"
    local TMP="${2}"
    local TAR="${3}"
    declare -a SRCS=("${!4}")

    [[ -e ${TAR} ]] || readme ${TMP}

    printf "Adding %s configuration files to tar archive\n" ${MODE}
    case ${MODE} in
        home)
            mkdir -p ${TMP}/home/{dot,config,localshare}
            for one in ${SRCS[@]}; do
                local one_="${HOME}/${one}"
                [[ -e ${one_} ]] || continue
                case $(echo ${one} | awk -F '/' '{ print $1 }') in
                    ".config") cp -r ${one_} ${TMP}/home/config ;;
                    ".local") cp -r ${one_} ${TMP}/home/localshare ;;
                    *) cp -r ${one_} ${TMP}/home/dot/$(echo ${one} | sed 's/^.//') ;;
                esac
            done
            tar -rf ${TAR} --directory=${TMP} home
            ;;
        etc)
            mkdir ${TMP}/etc
            for one in ${SRCS[@]}; do
                local one_="/etc/${one}"
                [[ -e ${one_} ]] || continue
                cp -r ${one_} ${TMP}/etc
            done
            tar -rf ${TAR} --directory=${TMP} etc
            ;;
    esac
    sleep 3
}

## Compress tar file and send it to server with correct name.
gzipit() {
    local TAR="${1}"
    local DEST="${2}"
    local opts=('-a' '-i')

    printf "Compressing archive with gzip\n"
    gzip ${TAR}

    printf "Syncing archive to server\n"
    bkp "${TAR}.gz" "${DEST}" opts[@]
}

## Cleanup the mess.
cleanup() {
    [[ -n ${1} ]] && printf "%s\n" "${1}"
    [[ -e ${DIR} ]] && rm -r "${DIR}"
    exit
}

### Define main.
# Source config file.
[[ -e ${HOME}/.config/backup.conf ]] || printf "Can't read config file.\n"
source ${HOME}/.config/backup.conf

# Show message and exit if asking for help
if [[ ${1} =~ ^--?[hv] ]]; then
    case ${1} in
        "-h" | "--help")
            printf "\$ %s home  web  chrome  dotfiles\n" ${PKG}
            printf "%s\n"\
                "all        = execute all options below"\
                "home       = home folder"\
                "extra      = everything else"\
                "dotfiles   = .files and .folders"
            ;;
        "-v" | "--version")
            printf "%s © Caedus75\n" ${PKG}
            printf "Version %s (%s)\n" ${VERSION} "${VDATE}"
            ;;
    esac
    exit
fi

# Check if destination is remote and online.
if [[ -n ${SERVER} ]]; then
    ping -c 1 -w 5 ${SERVER} >/dev/null 2>&1
    SERVER+=":"
fi

# Loop through all CLI options.
while (( "$#" )); do
    case ${1} in
        all | home)
            DEST="${SERVER}${DESTH}"
            for per in ${HOMEDIR}; do
                [[ -n ${per} && -e ${per} ]] || continue
                bkp "${per}" "${DEST}" RSYNCOPT[@]
            done
            ;;&
        all | extra)
            DEST="${SERVER}${DESTO}"
            for ex in ${OTHERDIR}; do
                [[ -n ${ex} && -e ${ex} ]] || continue
                bkp "${ex}" "${DEST}" RSYNCOPT[@]
            done
            ;;&
        all | dotfiles)
            DIR="$(tempdir)"
            TAR="${DIR}.tar"
            DEST="${SERVER}${DESTD}"
            [[ ${#homeconf[@]} -ne 0 ]] && dot home ${DIR} ${TAR} homeconf[@]
            [[ ${#etcconf[@]} -ne 0 ]] && dot etc ${DIR} ${TAR} etcconf[@]
            [[ -e ${TAR} ]] && gzipit "${TAR}" "${DEST}"
            ;;&
        all)
            break
            ;;
    esac
    shift
done
