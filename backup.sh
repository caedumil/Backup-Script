#!/bin/bash
####                                                                        ####
##  Script para sincronizar com o 2º PC pastas e arquivos.                    ##
##                                                                            ##
####                                                                        ####

VERSION='13.0'      # -- Caedus <caedus75@gmail.com>
VDATE='2014-05-20'  # release date
PKG='backup'        # backup-script

## Functions
# para os backups
bkp(){
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

# para os extras
dot(){
    [[ -z $dot ]] && printf "Don't know what to sync here, sorry\n"; return

    local DATE=$(date "+%Y-%m-%d")
    local DIR="$(mktemp -d)"
    local TAR="$DIR.tgz"

    printf "Preparing dotfiles-folder\n"
    mkdir $DIR/{home,config,localshare}

    printf "Copying dotfiles to dotfiles-folder\n"
    for one in $dot; do
        local one_="$HOME/$one"
        if [[ -e $one_ ]]; then
            if [[ -n $(echo $one | grep -o "config") ]]; then
                cp -r $one_ $DIR/config
            elif [[ -n $(echo $one | grep -o "local") ]]; then
                cp -r $one_ $DIR/localshare
            else
                cp -r $one_ $DIR/home
            fi
        fi
    done

    printf "Compressing with tar\n"
    tar -czf $TAR --directory=$DIR home config localshare

    printf "Syncing arch.tgz to server\n"
    rsync "${DSYNCOPT[@]}" $TAR $SERVER:$DESTB/$DOT/arch/arch-${DATE}.tgz
    sleep 3
}

isup(){
    printf "%s > Server is " $(date "+%Y-%m-%d--%H:%M")
    if ping -c 1 -w 5 $SERVER &>/dev/null; then
        printf "UP"
        return 0
    else
        printf "DOWN"
        return 1
    fi
}

## Put everything above to some use now!
if [[ -e $HOME/.config/backup.conf ]]; then
    source $HOME/.config/backup.conf
elif [[ -e /etc/backup.conf ]]; then
    source /etc/backup.conf
fi

while (( "$#" )); do
    [[ isup -eq 1 ]] && printf "Can't connect to server, aborting\n"; exit 1

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
        chrome)
            bkp web ~/.config/chromium chromium
            ;;
        dotfiles)
            dot
            ;;
        "-h" | "--help")
            printf "\$ %s home  web  chrome  dotfiles\n" $PKG
            printf "%s\n"\
                "home       = home folder"\
                "web        = browser, email"\
                "chrome     = chromium"\
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
