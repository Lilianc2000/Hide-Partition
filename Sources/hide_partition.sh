#!/bin/bash

echo

if [ "$EUID" -ne 0 ]; then
	echo "Please run this script as root"
	echo
 	exit
fi

if [ $# -eq 0 ]; then
        echo "Script usage : hide_partition.sh sdX"
        echo
	exit
fi

if [[ ! $1 =~ "sd"[a-zA-Z]+ ]]; then
	echo "Script usage : hide_partition.sh sdX"
	echo
	exit
fi

disque=$1

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

# Début des opérations

# Extraction du mbr de la clé
dd if=/dev/$disque of=fake_usb_mbr.dump bs=512 count=1 status=none
cp fake_usb_mbr.dump original_usb_mbr.dump

# Modification du MBR via python
python3 edit_mbr.py fake_usb_mbr.dump

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