#!/bin/bash
####                                                                        ####
##  Script para sincronizar com o 2º PC pastas e arquivos.                    ##
##                                                                            ##
####                                                                        ####

VERSION='13.0'      # -- Caedus <caedus75@gmail.com>
VDATE='2014-05-20'  # release date
PKG='backup'        # backup-script

### This is the beginning of the script
## Soucer config file
if [[ -e $HOME/.config/backup.conf ]]; then
    source $HOME/.config/backup.conf
elif [[ -e /etc/backup.conf ]]; then
    source /etc/backup.conf
fi

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

    echo -e "\e[1;32m\nsync $3 \e[0m"
    rsync "${OSYNCOPT[@]}" "${DSYNCOPT[@]}" $2/ $SERVER:$TARGET
    sleep 3
}

# para os extras
dot(){
    [[ -z $dot ]] && echo -e "\e[1mDon't know what to sync here, sorry \e[0m"; return

    local DATE=$(date "+%Y-%m-%d")
    local DIR="$(mktemp -d)"
    local TAR="$DIR.tgz"

    echo -e "\e[1;32m\n\npreparing dotfiles-folder \e[0m"
    mkdir $DIR/{home,config,localshare}

    echo -e "\e[1;32mcopying dotfiles to dotfiles-folder \e[0m"
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

    echo -e "\e[1;32mcompressing with tar \e[0m"
    tar -czf $TAR --directory=$DIR home config localshare

    echo -e "\e[1;32msyncing arch.tgz to server \e[0m"
    rsync "${DSYNCOPT[@]}" $TAR $SERVER:$DESTB/$DOT/arch/arch-${DATE}.tgz
    sleep 3
}

isup(){
    echo -en "`date "+%Y-%m-%d--%H:%M"` > Server is "
    if ping -c 1 -w 5 $SERVER &>/dev/null; then
        echo "UP"
        return 0
    else
        echo "DOWN"
        return 1
    fi
}

## Put everything above to some use now!
while (( "$#" )); do
    [[ isup -eq 1 ]] && echo "Can't connect to server, aborting"; exit 1

    case $1 in
        home)
            for per in $HOMEDIR; do
                bkp home $per $(echo $per | awk -F '/' '{ print $NF }')
            done
            ;;
        web)
            for con in $WEBDIR; do
                bkp web $con $(echo $con | awk -F '/' '{ print $NF }' | sed 's/.//')
            done
            ;;
        chrome)
            bkp web ~/.config/chromium chromium
            ;;
        dotfiles)
            dot
            ;;
        '-h' | '--help' | '-v' | '--version')
            echo -e "\e[1m\n\n \$ $PKG home &/| web &/| chrome &/| dotfiles \e[0m"
            echo -e "home\t\t= home folder"
            echo -e "web\t\t= browser, email"
            echo -e "chrome\t\t= chromium"
            echo -e "dotfiles\t= dot files and folders"
            echo -e "\e[1m\n\n$PKG © Caedus75 \nversion $VERSION ($VDATE)"
            break
            ;;
    esac
    shift
done
exit 0
