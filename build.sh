#!/bin/bash

if [ ! -f ./manifest.xml ]; then
	echo "Fichier manifest manquant"
	exit 1
fi


monkeyc -m manifest.xml -w -z resources/resources.xml -o CEDRIC.PRG source/CedricWatchApp.mc  source/CedricWatchView.mc -y ../../developer_key.der
