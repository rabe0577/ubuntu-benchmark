#!/bin/bash

#Warnmeldung und Sleep
echo ""
echo -e "\033[31m\033[4mDer Server wird geupgradet und eventuell rebootet\033[0m"
echo -e "Ausführung ohne Upgrade mit Option \033[36m--no-upgrade\033[0m"
echo ""
for i in {10..1}; do
	echo -en "\rAbbruch noch $i Sekunden möglich "
	sleep 1
done
echo -en "\n"

#Updates installieren und ggf reboot
apt-get update
if ! [ $1 = "--no-upgrade" ]; then
	export DEBIAN_FRONTEND=noninteractive
	apt-get upgrade -yp
	apt-get dist-upgrade -yp
	if [ -e /var/run/reboot-required ]; then
		echo "@reboot root XX" > /etc/cron.d/ubuntu-benchmark
		reboot
	else
		rm -f /etc/cron.d/ubuntu-benchmark
	fi
fi

#Abhängigkeiten installieren
apt-get install -yp htop nano nload zip screen python