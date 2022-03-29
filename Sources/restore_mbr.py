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

	# Entrée par l'utilisateur des informations de la partition à restaurer
	original = input("Enter original partition hex data : ")

	# Recherche de la dernière partition (offset 0x1BE)
	file.seek(446)

	# i contient l'offset juste après la dernière partition
	i = 0
	while (file.read(16).hex() != "00000000000000000000000000000000"):
		i = i + 1
		file.seek(446 + i * 16 + 1)

	# Écriture des informations de la partition cachée
	file.seek(446 + i * 16)
	file.write(unhexlify(original))
	
	# Récupération de la taille de la partition cachée
	hidden_partition_size = original[-8:]
	hidden_partition_size = [hidden_partition_size[i:i+2] for i in range(0, len(hidden_partition_size), 2)]
	size_in_big = ''.join(hidden_partition_size[::-1])
	hidden_partition_size = int.from_bytes(unhexlify(size_in_big), 'big')
	
	# Position de la dernière partition visible
	last_partition_offset = 446 + i * 16

	# Récupération de la capacité de l'ancienne partition visible
	file.seek(last_partition_offset -16 + 12)
	capacity_of_old_free_partition = int.from_bytes(file.read(4), byteorder='little')

	# Calcul de la nouvelle capacité de la partition
	capacity_of_new_partition = capacity_of_old_free_partition - hidden_partition_size

	# Configuration de la fin de la nouvelle dernière partition
	file.seek(last_partition_offset - 4)
	file.write(capacity_of_new_partition.to_bytes(4, byteorder='little'))

	# Fermeture du fichier
	file.close()
