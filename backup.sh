#!/bin/bash
#####
##
##  Script to backup files and folders in a remote server.
##
#####

### Define some versioning variables.
VERSION='2.1.0'         # -- Caedus <caedus75@gmail.com>
VDATE='2014-07-17'      # release date
PKG='backup'            # backup-script

### Define functions.
# Put everything where it belongs on the server.
bkp(){
    # $1 = mode; $2 = source directory; $3 = destination directory
    [[ -d $2 ]] || return

    if [[ $1 == "web" ]]; then
        local TARGET="$DETB/$DOT/$3"
    elif [[ $1 == "home" && $3 == "Music" ]]; then
        local TARGET="$DESTM"
    else
        local TARGET="$DESTB/$3"
    fi

    printf "Sync %s\n" $3
    rsync "${OSYNCOPT[@]}" "${DSYNCOPT[@]}" $2/ $SERVER:$TARGET
    sleep 3
}

# Pack dotfiles and send to the server
dot(){
    # $1 = mode; $2 = destination directory; $3,N = list of files
    local TAR="$2.tar"

    [[ -e $TAR ]] || tar -cf $TAR --files-from /dev/null

    printf "Adding %s configuration files to tar archive\n" $1
    case $1 in
        home)
            mkdir -p $2/home/{dot,config,localshare}
            for one in ${@:3}; do
                local one_="$HOME/$one"
                [[ -e $one_ ]] || continue
                case $(echo $one | awk -F '/' '{ print $1 }') in
                    ".config") cp -r $one_ $2/home/config ;;
                    ".local") cp -r $one_ $2/home/localshare ;;
                    *) cp -r $one_ $2/home/dot/$(echo $one | sed 's/^.//') ;;
                esac
            done
            tar -rf $TAR --directory=$2 home
            ;;
        etc)
            mkdir $2/etc
            for one in ${@:3}; do
                local one_="/etc/$one"
                [[ -e $one_ ]] || continue
                cp -r $one_ $2/etc
            done
            tar -rf $TAR --directory=$2 etc
            ;;
    esac
    sleep 3
}

gzipit(){
    # $1 = tar file
    local DATE=$(date "+%Y-%m-%d")

    printf "Compressing archive with gzip\n"
    gzip $1

    printf "Syncing archive to server\n"
    rsync "${DSYNCOPT[@]}" ${1}.gz $SERVER:$DESTB/$DOT/arch/arch-${DATE}.tgz
}

# Check if server is alive to receive the transfers.
isup(){
    if ping -c 1 -w 5 $SERVER &>/dev/null; then
        return 0
    else
        return 1
    fi
}

### Define main.
# $@ = list of options
if [[ -e $HOME/.config/backup.conf ]]; then
    source $HOME/.config/backup.conf
elif [[ -e /etc/backup.conf ]]; then
    source /etc/backup.conf
fi

while (( "$#" )); do
    [[ isup -eq 1 ]] && { printf "Can't connect to server, aborting\n"; exit 1; }

    case $1 in
        home)
            for per in $HOMEDIR; do
                [[ -z $per ]] && break
                bkp home $per $(echo $per | awk -F '/' '{ print $NF }')
            done
            ;;
        web)
            for con in $WEBDIR; do
                [[ -z $con ]] && break
                bkp web $con $(echo $con | awk -F '/' '{ print $NF }' | sed 's/.//')
            done
            ;;
        dotfiles)
            DIR="$(mktemp -d)"
            [[ -n $homeconf ]] && dot home $DIR $homeconf
            [[ -n $etcconf ]] && dot etc $DIR $etcconf
            [[ -e ${DIR}.tar ]] && gzipit ${DIR}.tar
            ;;
        "-h" | "--help")
            printf "\$ %s home  web  chrome  dotfiles\n" $PKG
            printf "%s\n"\
                "home       = home folder"\
                "web        = browser, email"\
                "dotfiles   = .files and .folders"
            break
            ;;
        "-v" | "--version")
            printf "%s © Caedus75 \nversion %s (%s)\n" $PKG $VERSION $VDATE
            break
            ;;
    esac
    shift
done
exit 0
