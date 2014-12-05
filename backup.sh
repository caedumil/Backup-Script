#!/bin/bash
##
##
##  Script to backup files and folders to a remote server.
##
##

### Define some versioning variables.
PKG='backup'
VERSION='__version'
VDATE='__vdate'

### Define functions.
## Use rsync to sync local to remote.
bkp() {
# $1 = source directory;
# $2 = destination directory;
# $3 = rsync parameters.
    declare -a OPTS=("${!3}")

    printf "Sync %s\n" ${1}
    rsync "${OPTS[@]}" ${1} ${2}
    sleep 3
    printf "Done\n"
}

## Create a tar file with a README inside.
readme() {
    cat <<-INFO > ${1}/README
Configuration files and folders.

The name of the folder here tells you were the config files goes!
    * dot = home folder, hidden files they are.
    * config = .config folder, put them where they belong.
    * localshare = .local/share, an unusual place to these important ones.
    * etc = these goes to /etc, be root to place them.

Now you know everything you should, restore your things! ;)
INFO

    tar -cf ${1}.tar --directory=${1} README
}

## Pack dotfiles in a nice tar file.
dot() {
# $1 = mode;
# $2 = temp folder;
# $3,N = list of files.
    local TAR="${2}.tar"

    [[ -e ${TAR} ]] || readme ${2}

    printf "Adding %s configuration files to tar archive\n" ${1}
    case ${1} in
        home)
            mkdir -p ${2}/home/{dot,config,localshare}
            for one in ${@:3}; do
                local one_="${HOME}/${one}"
                [[ -e ${one_} ]] || continue
                case $(echo ${one} | awk -F '/' '{ print $1 }') in
                    ".config") cp -r ${one_} ${2}/home/config ;;
                    ".local") cp -r ${one_} ${2}/home/localshare ;;
                    *) cp -r ${one_} ${2}/home/dot/$(echo ${one} | sed 's/^.//') ;;
                esac
            done
            tar -rf ${TAR} --directory=${2} home
            ;;
        etc)
            mkdir ${2}/etc
            for one in ${@:3}; do
                local one_="/etc/${one}"
                [[ -e ${one_} ]] || continue
                cp -r ${one_} ${2}/etc
            done
            tar -rf ${TAR} --directory=${2} etc
            ;;
    esac
    sleep 3
}

## Compress tar file and send it to server with correct name.
gzipit() {
# $1 = tar file;
# $2 = destination directory.
    local date="$(date "+%Y-%m-%d")"
    local opts=('-a' '-i')

    printf "Compressing archive with gzip\n"
    gzip ${1}

    printf "Syncing archive to server\n"
    bkp "${1}.gz" "${2}/arch-${date}.tgz" opts[@]
}

### Define main.
# Source config file.
if [[ -e ${HOME}/.config/backup.conf ]]; then
    source ${HOME}/.config/backup.conf
else
    printf "Can't read configuration file, aborting\n"
    exit 1
fi

# Loop through all cli options, checking if server is online on each option.
while (( "$#" )); do
    if ! ( ( ping -c 1 -w 5 ${SERVER} >/dev/null 2>&1 ) ||\
        ( [[ ${1} =~ ^--?[hv] ]] ) ); then
        printf "Can't connect to server, aborting\n"
        exit 1
    fi

    case ${1} in
        all | home)
            for per in ${HOMEDIR}; do
                [[ -n ${per} && -e ${per} ]] || continue
                bkp "${per}" "${SERVER}:${DESTH}" DSYNCOPT[@]
            done
            ;;&
        all | extra)
            for ex in ${OTHERDIR}; do
                [[ -n ${ex} && -e ${ex} ]] || continue
                bkp "${ex}" "${SERVER}:${DESTO}" DSYNCOPT[@]
            done
            ;;&
        all | dotfiles)
            DIR="$(mktemp -d)"
            [[ -n ${homeconf} ]] && dot home ${DIR} ${homeconf}
            [[ -n ${etcconf} ]] && dot etc ${DIR} ${etcconf}
            [[ -e ${DIR}.tar ]] && gzipit "${DIR}.tar" "${SERVER}:${DESTH}/arch"
            ;;&
        all)
            break
            ;;
        "-h" | "--help")
            printf "\$ %s home  web  chrome  dotfiles\n" ${PKG}
            printf "%s\n"\
                "all        = execute all options below"\
                "home       = home folder"\
                "extra      = everything else"\
                "dotfiles   = .files and .folders"
            break
            ;;
        "-v" | "--version")
            printf "%s © Caedus75\n" ${PKG}
            printf "Version %s (%s)\n" ${VERSION} "${VDATE}"
            break
            ;;
    esac
    shift
done
exit 0
