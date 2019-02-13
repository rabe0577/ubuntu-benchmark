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
apt-get install -yq htop nano nload zip screen python sysbench fio gcc libgl1-mesa-dev libxext-dev perl perl-modules make git

#Temp Ordner erstellen
ordner=$(readlink -f "$0" | rev | cut -d"/" -f2- | rev)
mkdir $ordner/ubuntu-bench-temp
cd $ordner/ubuntu-bench-temp/


# --- Benchmarks ---

#Speedtest
wget -O speedtest-cli --no-check-certificate https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py
chmod a+x speedtest-cli
speedserver=`./speedtest-cli --list | tail -n +2 | head -n 15 | cut -d")" -f1 | tr -d ' '`
for server in $speedserver; do
	./speedtest-cli --csv --csv-delimiter ";" --no-upload --server $server | tee -a speedtest_download.log
done
for server in $speedserver; do
	./speedtest-cli --csv --csv-delimiter ";" --no-download --server $server | tee -a speedtest_upload.log
done

#Ram Test
sysbench --test=memory --num-threads=1 --memory-block-size=1M --memory-total-size=10000G run | tee -a sysbench_memory_test.log

#Festplatten Test
mount=`df -h / | tail -n +2 | cut -d" " -f1`
round=0
while [ $round -lt 5 ]; do
	hdparm -tT --direct $mount | tee -a hdparm.log
	round=$(( $round + 1 ))
done

#Unixbench
git clone https://github.com/kdlucas/byte-unixbench.git
cd byte-unixbench/UnixBench/
./Run | tee -a unixbench.log