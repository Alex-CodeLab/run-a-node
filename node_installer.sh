#!/bin/bash

if [ "$EUID" -eq 0 ]

    then if (whiptail --title "Do not run as root." --yesno "Do you wish to create a user 'bitcoin' now ?" 8 78) then
        adduser bitcoin
        echo "Run this installer again as non-root user:   \$ su bitccoin "         
        exit 0    
    else
        echo "Run this installer again as non-root user. "        
        exit 0
    fi
fi


function inst_cli() {
    echo "Install c-lightning ..."
    echo "$(tput bold)Update ...$(tput sgr0) "
    sudo apt-get install -y \
        autoconf automake build-essential git libtool libgmp-dev wget software-properties-common \
        libsqlite3-dev python python3 net-tools libsodium-dev  &&
    git clone https://github.com/ElementsProject/lightning.git &&
    cd lightning
    make &&
    sudo make install &&
    mkdir -p ${HOME}/.lightning 
    echo -n "set a lightingnode name: "
    read NODENAME
    printf "alias=${NODENAME} \nnetwork=testnet \nport=9735 \noverride-fee-rates=400/400/400" > ${HOME}/.lightning/config
    echo "$(tput bold)c-lightning successfully installed.$(tput sgr0) "      
}

function inst_btcd() {
    echo "Install btcd ..."
    cd /home/$USER
    # install golang    
    sudo apt-get -y install golang-1.10-go
    if [ "$?" -ne 0 ] ; then
        sudo add-apt-repository ppa:longsleep/golang-backports
        sudo apt-get update
        sudo apt-get install golang-go
    fi 

    go get -u github.com/Masterminds/glide
    cd $GOPATH/src
    git clone https://github.com/roasbeef/btcd $GOPATH/src/github.com/roasbeef/btcd
    cd $GOPATH/src/github.com/roasbeef/btcd
    glide install
    go install . ./cmd/...

}


function inst_lnd() {
    echo "Install lnd ..."
    cd /home/$USER
    # install golang    
    sudo apt-get -qq -y install golang-1.10-go
    if [ "$?" -ne 0 ] ; then
        sudo add-apt-repository ppa:longsleep/golang-backports
        sudo apt-get -qq update
        sudo apt-get -qq install golang-go

    fi 
    goversion=`go version |cut -d ' ' -f 3 |cut -d '.' -f 2`
    goversionp=`go version`
    echo ${goversion}
    if [ "$goversion" -lt 10 ] ; then
       if [ -L "/usr/bin/go" ] ; then
           if [ -f  "/usr/lib/go-1.10/bin/go" ]; then
               if (whiptail --title "golang-go version " --yesno "Your version of golang-go ${goversionp} is too old, '/usr/lib/go-1.10/bin/go' exists.\nChange symbolic link '/usr/bin/go' to  '/usr/lib/go-1.10/bin/go'  " 8 78) then
                   sudo rm /usr/bin/go 
                   sudo ln -s /usr/lib/go-1.10/bin/go /usr/bin/go
               else 
                   exit 0 
               fi 
            fi     
        fi
    fi

    curl https://glide.sh/get | sh    && 
    git clone https://github.com/lightningnetwork/lnd $GOPATH/src/github.com/lightningnetwork/lnd &&
    cd $GOPATH/src/github.com/lightningnetwork/lnd  &&
    glide install
    if [ "$?" -ne 0 ] ; then
        exit 
    fi
    go install . ./cmd/...  
    if [ "$?" -ne 0 ] ; then
        exit 
    fi
    echo "LND succesfully installed "
}

function inst_btc(){
    echo "Install bitcoind ..."
    sudo apt-get install autotools-dev pkg-config libssl-dev libevent-dev bsdmainutils 
    sudo apt-get install libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-test-dev libboost-thread-dev
    sudo apt-get install software-properties-common
    sudo add-apt-repository ppa:bitcoin/bitcoin
    sudo apt-get update
    sudo apt-get install libdb4.8-dev libdb4.8++-dev
    sudo apt-get install libzmq3-dev
    git clone https://github.com/bitcoin/bitcoin.git
    cd bitcoin
    ./autogen.sh
    ./configure
    make
    sudo make install 
    mkdir -p ${HOME}/.bitcoin
    cp contrib/debian/examples/bitcoin.conf ${HOME}/.bitcoin
    NEW_ID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 42 | head -n 1)
    printf "\ntestnet=1 \nrpcuser=${USER} \nrpcpassword=${NEW_ID}" >> ${HOME}/.bitcoin/bitcoin.conf
}


function confirm_install(){
    if (whiptail --title "Install " --yesno "This will install ${choice} in ${HOME}/    continue? " 8 78) then
            cd ${HOME}          
            echo "$(tput bold)apt-get update $(tput sgr0) "      
            sudo apt-get update
        else
            exit 0
    fi
}


choice=$(whiptail --title " Bitcoin Node installer" --radiolist \
"What do you want to install" 20 78 4 \
"c-lightning" "" on \
"lnd" "" off \
"btcd" "" off \
"bitcoind" "" off 3>&1 1>&2 2>&3)

if [ "$choice" = "c-lightning" ] ; then
    confirm_install
    inst_cli 
fi

if [ "$choice" = "lnd" ] ; then
    confirm_install
    mkdir -p ~/gocode/bin
    export GOPATH=~/gocode &&
    export PATH=$PATH:$GOPATH/bin &&
    inst_lnd
fi

if [ "$choice" = "bitcoind" ] ; then    
    confirm_install
    inst_btc
fi

if [ "$choice" = "btcd" ] ; then    
    confirm_install
    mkdir -p ~/gocode/bin
    export GOPATH=~/gocode &&
    export PATH=$PATH:$GOPATH/bin &&
    inst_btcd
fi


function ufw_rules(){
    if hash ufw 2>/dev/null; then
        sudo apt-get install ufw
    fi
    sudo ufw allow 9735 comment 'allow Lightning'
    sudo ufw deny 8333 comment  'deny Bitcoin mainnet'
    sudo ufw allow 18333 comment 'allow Bitcoin testnet'
    sudo ufw enable
    sudo ufw status
}


if (whiptail --title "Firewall." --yesno "Do you wish to add some firewall rules ?" 8 78) then
    ufw_rules
else
    echo ""        
fi






