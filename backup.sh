#!/bin/bash
#####
##
##  Script to backup files and folders in a remote server.
##
#####

### Define some versioning variables.
VERSION='2.2.1'         # -- Caedus <caedus75@gmail.com>
VDATE='2014-07-21'      # release date
PKG='backup'            # backup-script

### Define functions.
# Put everything where it belongs on the server.
bkp(){
    # $1 = source directory; $2 = destination directory; $3 = rsync parameters
    declare -a OPTS=("${!3}")

    printf "Sync %s\n" ${1}
    rsync "${OPTS[@]}" ${1} ${2}
    sleep 3
    printf "Done\n"
}

# Pack dotfiles in a nice tar file
dot(){
    # $1 = mode; $2 = temp folder; $3,N = list of files
    local TAR="${2}.tar"

    [[ -e ${TAR} ]] || tar -cf ${TAR} --files-from /dev/null

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

# Compress tar file and send it to server with correct name.
gzipit(){
    # $1 = tar file; $2 = destination directory
    local date="$(date "+%Y-%m-%d")"
    local opts=('-a' '-i')

    printf "Compressing archive with gzip\n"
    gzip ${1}

    printf "Syncing archive to server\n"
    bkp "${1}.gz" "${2}/arch-${date}.tgz" opts[@]
}

# Check if server is alive to receive the transfers.
isup(){
    if ping -c 1 -w 5 ${SERVER} &>/dev/null; then
        return 0
    else
        return 1
    fi
}

### Define main.
# $@ = list of options
if [[ -e ${HOME}/.config/backup.conf ]]; then
    source ${HOME}/.config/backup.conf
elif [[ -e /etc/backup.conf ]]; then
    source /etc/backup.conf
fi

while (( "$#" )); do
    [[ isup -eq 1 ]] && { printf "Can't connect to server, aborting\n"; exit 1; }

    case ${1} in
        home)
            for per in ${HOMEDIR}; do
                [[ -n ${per} && -e ${per} ]] || continue
                bkp "${per}" "${SERVER}:${DESTH}" DSYNCOPT[@]
            done
            ;;
        web)
            for con in ${WEBDIR}; do
                [[ -n ${con} && -e ${con} ]] || continue
                bkp "${con}" "${SERVER}:${DESTW}" DSYNCOPT[@]
            done
            ;;
        extra)
            for ex in ${OTHERDIR}; do
                [[ -n ${ex} && -e ${ex} ]] || continue
                bkp "${ex}" "${SERVER}:${DESTO}" DSYNCOPT[@]
            done
            ;;
        dotfiles)
            DIR="$(mktemp -d)"
            [[ -n ${homeconf} ]] && dot home ${DIR} ${homeconf}
            [[ -n ${etcconf} ]] && dot etc ${DIR} ${etcconf}
            [[ -e ${DIR}.tar ]] && gzipit "${DIR}.tar" "${SERVER}:${DESTH}/arch"
            ;;
        "-h" | "--help")
            printf "\$ %s home  web  chrome  dotfiles\n" ${PKG}
            printf "%s\n"\
                "home       = home folder"\
                "web        = web stuff"\
                "extra      = everything else"\
                "dotfiles   = .files and .folders"
            break
            ;;
        "-v" | "--version")
            printf "%s © Caedus75 \nversion %s (%s)\n" ${PKG} ${VERSION} ${VDATE}
            break
            ;;
    esac
    shift
done
exit 0
