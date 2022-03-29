#!/usr/bin/python
# -*- coding: UTF-8 -*-

from sys import argv
from time import sleep
from binascii import unhexlify

if (len(argv) != 2):
	print("Usage : python3 edit_mbr.py mbr_to_edit")

else:
	# Ouverture du fichier
	file = open(argv[1], "r+b")

	# Recherche de la dernière partition (offset 0x1BE)
	file.seek(446)

	# i contient l'offset juste après la dernière partition
	i = 0
	while (file.read(16).hex() != "00000000000000000000000000000000"):
		i = i + 1
		file.seek(446 + i * 16 + 1)

	# Affichage des bytes à sauvegarder
	last_partition_offset = 446 + (i - 1) * 16
	file.seek(last_partition_offset)

	old_partition = file.read(16)

	print("\nYou have 10 seconds to save this hexa string.\nIt will be necessary to recover your hidden partition.\nString : " + old_partition.hex())
	sleep(10)

	# Récupération de la capacité de la partition cachée
	file.seek(last_partition_offset + 12)
	capacity_of_hidden_partition = int.from_bytes(file.read(4), byteorder='little')

	# Récupération de la capacité de l'ancienne partition visible
	file.seek(last_partition_offset - 16 + 12)
	capacity_of_old_free_partition = int.from_bytes(file.read(4), byteorder='little')

	# Calcul de la nouvelle capacité de la partition
	capacity_of_new_partition = capacity_of_hidden_partition + capacity_of_old_free_partition

	# Effacement de la partition du MBR
	file.seek(last_partition_offset)
	file.write(unhexlify('00000000000000000000000000000000'))

	# Configuration de la fin de la nouvelle dernière partition
	file.seek(last_partition_offset - 4)
	file.write(capacity_of_new_partition.to_bytes(4, byteorder='little'))

	# Fermeture du fichier
	file.close()
