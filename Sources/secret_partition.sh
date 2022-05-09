#!/bin/bash

echo

function help(){

    echo "This script can create a hidden partition on your USB key."
    echo "It will create a new MBR on it, then create a partition table."
    echo "Then, it will make dissapear the last partition of the key."
    echo
    echo "Options:"
    echo "--help : Show help of the script"
    echo "-r | --recover : Restore the hidden partition on the key"
    echo "-h | --hide : Hide the last partition of an USB key"
    echo "-a | --all : All-in-one option to initialize an USB key and hide a partition"
    echo
    exit

}

function edit_mbr(){

    # Début des opérations

    # Extraction du mbr de la clé
    dd if=/dev/$disque of=fake_usb_mbr.dump bs=512 count=1 status=none
    cp fake_usb_mbr.dump original_usb_mbr.dump

    # Modification du MBR via python
    if [ $action == 0 ]; then
        python3 edit_mbr.py fake_usb_mbr.dump
    fi

    if [ $action == 0 ]; then
        python3 restore_mbr.py fake_usb_mbr.dump
    fi

    # Écriture du MBR modifié
    dd if=fake_usb_mbr.dump of=/dev/$disque bs=512 count=1 status=none

    # Vérification du MBR
    dd if=/dev/$disque of=usb_mbr.dump2 bs=512 count=1 status=none
    cmp --silent fake_usb_mbr.dump usb_mbr.dump2

    if [ $? -eq 0 ]; then
        echo "Success!"
    else
        echo "It looks like it failed, trying to restore original mbr..."
        dd if=original_usb_mbr.dump of=/dev/$disque bs=512 count=1
    fi

    # Fin du script
    echo "Please, unmount the usb key properly"
    shred -zn 5 fake_usb_mbr.dump original_usb_mbr.dump usb_mbr.dump2
    rm -f fake_usb_mbr.dump original_usb_mbr.dump usb_mbr.dump2
    echo
    exit
}

function prepare_usb(){

    echo "Enter the size of the hidden parition in MB."
    echo "Bigger it is, less secure it is."
    read taille

    re='^[0-9]+$'
    if ! [[ $taille =~ $re ]] ; then
        echo "Enter a integer!"  
        echo
        exit
    fi

    $tailleCle = fdisk -l | grep $disque | grep -oP "^[^\d]*\d+.{6}\d+.{9}(\d+)" | cut -d' ' -f6
    taillePartition1 = $tailleCle - (($taille * 1000000) / 512 )

    # Creation de la table des partitions
    (
        echo o

        echo n 
        echo p 
        echo 1 
        echo 1 
        echo $taillePartition1

        echo n 
        echo p 
        echo 2  
        echo $taillePartition1 + 1
        echo $tailleCle

        echo w

    )|fdisk $disque

    # Formatage des deux patitions
    mkntfs "${disque}1"
    cryptsetup --verbose luksFormat --verify-passphrase "${disque}2"

    # Disparition de la dernière partition
    action=0
    edit_mbr
}

if [ "$EUID" -ne 0 ]; then
	echo "Please run this script as root"
	echo
 	exit
fi

if [ $# -eq 0 ]; then
        echo "Invalid usage. Try secret_partition.sh --help"
        echo
	    exit
fi

OPTION = $1

case OPTION in

    --help)
        help
    ;;

    -r|--recover)
        
        if [[ ! $2 =~ "sd"[a-zA-Z]+ ]]; then
            echo "Script usage : hide_partition.sh -r sdX"
            echo
            exit
        fi

        disque=$2

        echo "Warning : This program will edit MBR of disk ${disque}."
        echo "I am not responsible for any damages caused by this script."
        echo "Please, be sure to do a backup of your key and to be sure to know how restore a clean MBR Partition Schems"
        echo
        echo "Are you sure ${disque} is the right disk? Otherwise you may loose a lot of data : Y/[N]"
        read choix

        if [ $choix != "y" ] && [ $choix != "Y" ]; then
            echo "Exiting"
            echo
            exit
        fi

        action=1
        edit_mbr
    ;;

    -h|--hide)
        
        if [[ ! $2 =~ "sd"[a-zA-Z]+ ]]; then
            echo "Script usage : hide_partition.sh -r sdX"
            echo
            exit
        fi

        disque=$2

        echo "Warning : This program will edit MBR of disk ${disque}."
        echo "I am not responsible for any damages caused by this script."
        echo "Please, be sure to do a backup of your key and to be sure to know how restore a clean MBR Partition Schems"
        echo
        echo "Are you sure ${disque} is the right disk? Otherwise you may loose a lot of data : Y/[N]"
        read choix

        if [ $choix != "y" ] && [ $choix != "Y" ]; then
            echo "Exiting"
            echo
            exit
        fi

        action=0
        edit_mbr
    ;;

    -a|--all)

        if [[ ! $2 =~ "sd"[a-zA-Z]+ ]]; then
            echo "Script usage : hide_partition.sh -a sdX"
            echo
            exit
        fi

        disque=$2

        echo "Warning : this script is about to create a new MBR on ${disque}."
        echo "All data will be LOOSE."
        echo "Are you sure to continue ? Y/[N]"
        read choix

        if [ $choix != "y" ] && [ $choix != "Y" ]; then
            echo "Exiting"
            echo
            exit
        fi

        pepare_usb
        action=0
        edit_mbr
    ;;

    *)
        help
    ;;