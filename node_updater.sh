#!/bin/bash

if [ "$EUID" -eq 0 ] ; then 
        echo "Run this updater again as non-root user. ('bitcoin')"        
        exit 0
fi


function upd_cli() {
    echo "Update c-lightning ..."
    cd ${HOME}/lightning  &&
    BCLI=`whereis lightning-cli | cut -d " " -f 2` &&   
    ${BCLI} stop
    sleep 4
    git pull
    make 
    sudo make install
}

function upd_btc() {
    echo "Update bitcoind"
    cd ${HOME}/bitcoin
    BTC=`whereis bitcoin-cli | cut -d " " -f 2 `
    sleep 4 
    git pull 
    make 
    sudo make install 
}


function confirm_update(){
    if (whiptail --title "Update " --yesno "This will update ${choice} in ${LOC}    continue? " 8 78) then
            cd ${HOME}          
            echo "$(tput bold)apt-get update $(tput sgr0) "      
            sudo apt-get update
        else
            exit 0
    fi
}


choice=$(whiptail --title " Bitcoin Node Update" --radiolist \
"What do you want to update" 20 78 4 \
"c-lightning" "" on \
"lnd" "" off \
"btcd" "" off \
"bitcoind" "" off 3>&1 1>&2 2>&3)

exitstatus=$?
if [ $exitstatus = 1 ]; then
    exit 0
fi

if [ "$choice" = "c-lightning" ] ; then
    LOC=${HOME}/lightning
    confirm_update
    upd_cli 
fi

if [ "$choice" = "lnd" ] ; then
    confirm_update
    export GOPATH=~/gocode &&
    export PATH=$PATH:$GOPATH/bin &&
    upd_lnd
fi

if [ "$choice" = "bitcoind" ] ; then    
    LOC=${HOME}/bitcoin
    confirm_update
    upd_btc
fi

if [ "$choice" = "btcd" ] ; then    
    confirm_update
    export GOPATH=~/gocode &&
    export PATH=$PATH:$GOPATH/bin &&
    upd_btcd
fi


