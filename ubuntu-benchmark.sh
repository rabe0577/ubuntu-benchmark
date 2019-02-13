#!/bin/bash

#Warnmeldung und Sleep
if ! [[ $1 = "--no-upgrade" ]]; then
	echo ""
	echo -e "\033[31m\033[4mDer Server wird geupgradet und eventuell rebootet\033[0m"
	echo -e "Ausführung ohne Upgrade mit Option \033[36m--no-upgrade\033[0m"
	echo ""
	for i in {10..1}; do
		echo -en "\rAbbruch noch $i Sekunden möglich ... "
		sleep 1
	done
	echo -en "\n"
fi

#Updates installieren und ggf reboot
if ! [[ $1 = "--no-upgrade" ]]; then
	export DEBIAN_FRONTEND=noninteractive
	apt-get update
	apt-get upgrade -yq
	apt-get dist-upgrade -yq
	#Screen für Crontab installieren
	apt-get install -yq screen
	if [ -e /var/run/reboot-required ]; then
		echo "@reboot root screen -AmdS ubuntu-benchmark bash $(readlink -f "$0")" > /etc/cron.d/ubuntu-benchmark
		echo ""
		echo "Server wird rebootet, Benchmark wird nach Reboot automatisch im Screen weitergeführt"
		echo -e "Screen abrufbar mit dem Befehl \033[36mscreen -r ubuntu-benchmark\033[0m"
		reboot
	else
		rm -f /etc/cron.d/ubuntu-benchmark
	fi
fi

#Abhängigkeiten installieren
apt-get install -yq htop nano nload zip screen python

#Temp Ordner erstellen
ordner=$(readlink -f "$0" | rev | cut -d"/" -f2- | rev)
mkdir $ordner/ubuntu-bench-temp
cd $ordner/ubuntu-bench-temp/