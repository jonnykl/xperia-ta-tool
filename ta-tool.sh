#!/bin/bash


TA_DEV="/dev/block/mmcblk0p1"



mainmenu=1


ta_clear_input () {
	#read -t 0.1 -n 10000 discard
	while read -r -t 0; do read -r; done
}

ta_read () {
	ta_clear_input
	read -n1 -p "Drücke eine beliebige Taste ... "
}

ta_check_busybox () {
	# pruefen, ob busybox installiert ist
	if ! [[ "`adb shell "su -c 'type busybox >/dev/null 2>/dev/null && echo ok'"`" =~ "ok" ]] ; then
		return 1
	fi
	
	return 0
}


ta_backup () {
	clear

	echo
	echo "    +-------------------------------------------+"
	echo "    |             Xperia TA Backup              |"
	echo "    +-------------------------------------------+"
	echo "    |  [ ] Prüfe, ob busybox installiert ist    |"
	echo "    |  [ ] TA-Partition sichern                 |"
	echo "    |  [ ] MD5-Summe auf dem Handy berechnen    |"
	echo "    |  [ ] Backup auf den Computer laden        |"
	echo "    |  [ ] MD5-Summen vergleichen               |"
	echo "    +-------------------------------------------+"
	echo
	
	echo -en "\033[7A\033[8C~\r\033[7B"
	
	if ! ta_check_busybox ; then
		echo -en "\033[1A"
		echo "    |  Fehler: Kein Root-Zugriff und/oder       |"
		echo "    |          busybox nicht gefunden!          |"
		echo "    +-------------------------------------------+"
		echo
		
		
		if ! [[ -z "$1" ]] ; then
			exit 0
		fi
		
		ta_read
		return
	fi
	
	echo -en "\033[7A\033[8CX\r\033[7B"
	echo -en "\033[6A\033[8C~\r\033[6B"
	
	adb shell "su -c 'dd if=$TA_DEV of=/sdcard/TA.backup.img >/dev/null 2>/dev/null'"
	
	echo -en "\033[6A\033[8CX\r\033[6B"
	echo -en "\033[5A\033[8C~\r\033[5B"
	
	md5sum0=$(adb shell "sh -c 'md5sum /sdcard/TA.backup.img'" | awk "{print \$1}")
	
	echo -en "\033[5A\033[8CX\r\033[5B"
	echo -en "\033[4A\033[8C~\r\033[4B"
	
	outfile="./TA.img"
	if ! [[ -z "$1" ]] ; then
		outfile="$1"
	fi
	
	adb pull /sdcard/TA.backup.img "$outfile" >/dev/null 2>/dev/null
	if [ $? -ne 0 ] ; then
		echo -en "\033[1A"
		echo "    |  Fehler: Konnte das Backup nicht auf den  |"
		echo "    |          Computer laden!                  |"
		echo "    +-------------------------------------------+"
		echo
		
		
		if ! [[ -z "$1" ]] ; then
			exit 0
		fi
		
		ta_read
		return
	fi
	
	echo -en "\033[4A\033[8CX\r\033[4B"
	echo -en "\033[3A\033[8C~\r\033[3B"
	
	md5sum1=$(md5sum "$outfile" | awk "{print \$1}")
	echo $md5sum1 > "$outfile.md5"
	
	echo -en "\033[3A\033[8CX\r\033[3B"
	
	echo -en "\033[1A"
	if [ "$md5sum0" == "$md5sum1" ] ; then
		echo "    |  Das Backup wurde erfolgreich erstellt!   |"
	else
		echo "    |  Die MD5-Summen stimmen nicht überein:    |"
		echo "    |                                           |"
		echo "    |  Handy: $md5sum0  |"
		echo "    |  PC:    $md5sum1  |"
	fi
	echo "    +-------------------------------------------+"
	echo
	
	
	
	if ! [[ -z "$1" ]] ; then
		exit 0
	fi
	
	ta_read
}

ta_restore () {
	clear

	echo
	echo "    +-------------------------------------------+"
	echo "    |             Xperia TA Restore             |"
	echo "    +-------------------------------------------+"
	echo "    |  [ ] Prüfe, ob busybox installiert ist    |"
	echo "    |  [ ] Backup aufs Handy schieben           |"
	echo "    |  [ ] MD5-Summen vergleichen               |"
	echo "    |  [ ] Wiederherstellung bestätigen         |"
	echo "    |  [ ] Backup wiederherstellen              |"
	echo "    +-------------------------------------------+"
	echo
	
	echo -en "\033[7A\033[8C~\r\033[7B"
	
	if ! ta_check_busybox ; then
		echo -en "\033[1A"
		echo "    |  Fehler: Kein Root-Zugriff und/oder       |"
		echo "    |          busybox nicht gefunden!          |"
		echo "    +-------------------------------------------+"
		echo
		
		ta_read
		return
	fi
	
	echo -en "\033[7A\033[8CX\r\033[7B"
	echo -en "\033[6A\033[8C~\r\033[6B"
	
	infile="./TA.img"
	if ! [[ -z "$1" ]] ; then
		infile="$1"
	fi
	
	if ! [ -f "$infile" ] ; then
		echo -en "\033[1A"
		echo "    |  Fehler: Konnte das Backup nicht finden!  |"
		echo "    +-------------------------------------------+"
		echo
		
		
		if ! [[ -z "$1" ]] ; then
			exit 0
		fi
		
		ta_read
		exit 1
	fi
	
	if ! [ -f "$infile.md5" ] ; then
		echo -en "\033[1A"
		echo "    |  Fehler: Konnte die MD5-Summe-Datei des   |"
		echo "    |          Backups nicht finden!            |"
		echo "    +-------------------------------------------+"
		echo
		
		
		if ! [[ -z "$1" ]] ; then
			exit 0
		fi
		
		ta_read
		exit 1
	fi
	
	adb push "$infile" /sdcard/TA.restore.img >/dev/null 2>/dev/null
	if [ $? -ne 0 ] ; then
		echo -en "\033[1A"
		echo "    |  Fehler: Konnte das Backup nicht aufs     |"
		echo "    |          Handy schieben!                  |"
		echo "    +-------------------------------------------+"
		echo
		
		
		if ! [[ -z "$1" ]] ; then
			exit 0
		fi
		
		ta_read
		return
	fi
	
	echo -en "\033[6A\033[8CX\r\033[6B"
	echo -en "\033[5A\033[8C~\r\033[5B"
	
	
	md5sum0=$(adb shell "sh -c 'md5sum /sdcard/TA.restore.img'" | awk "{print \$1}")
	md5sum1=$(md5sum "$infile" | awk "{print \$1}")
	md5sum2=$(cat "$infile.md5")
	
	if [ "$md5sum0" != "$md5sum1" ] || [ "$md5sum0" != "$md5sum2" ] ; then
		echo -en "\033[1A"
		echo "    |  Die MD5-Summen stimmen nicht überein:    |"
		echo "    |                                           |"
		echo "    |  Handy: $md5sum0  |"
		echo "    |  PC/0:  $md5sum1  |"
		echo "    |  PC/1:  $md5sum2  |"
		echo "    +-------------------------------------------+"
		echo
		
		
		if ! [[ -z "$1" ]] ; then
			exit 0
		fi
		
		ta_read
		return
	fi
	
	
	echo -en "\033[5A\033[8CX\r\033[5B"
	echo -en "\033[4A\033[8C~\r\033[4B"
	
	
	echo "ACHTUNG: WENN DU EIN FALSCHES/DEFEKTES BACKUP WIEDERHERSTELLST IST DAS HANDY NACHER HARD-GEBRICKT!!!"
	echo "         DU KANNST DIE WIEDERHERSTELLUNG JETZT NOCHMAL ABBRECHEN, NACHER NICHT MEHR!!!"
	echo
	ta_clear_input
	read -p "Wenn du fortfahren möchtest, bestätige den Vorgang mit der Eingabe von 'yes-restore-backup': " x
	if [ "$x" != "yes-restore-backup" ] ; then
		echo -en "\033[5A"
		echo "    |  Abgebrochen!                             |"
		echo "    +-------------------------------------------+                                                                                                         "
		echo "                                                                                                                                                          "
		echo "                                                                                                                                                          "
		echo "                                                                                                                                                          "
		echo -en "\033[1A\r                                                                                                                                                    \r"
		echo -en "\033[1A\r                                                                                                                                                    \r"
		echo -en "\033[1A\r                                                                                                                                                    \r"
		echo
		
		
		if ! [[ -z "$1" ]] ; then
			exit 0
		fi
		
		ta_read
		return
	fi
	
	echo -en "\033[1A\r                                                                                                                                                    \r"
	echo -en "\033[1A\r                                                                                                                                                    \r"
	
	
	
	echo -en "\033[4A\033[8CX\r\033[4B"
	echo -en "\033[3A\033[8C~\r\033[3B"
	
	
	adb shell "su -c 'dd if=/sdcard/TA.restore.img of=$TA_DEV >/dev/null 2>/dev/null'"
	
	
	echo -en "\033[3A\033[8CX\r\033[3B"
	
	
	echo -en "\033[1A"
	echo "    |  Das Backup wurde erfolgreich             |"
	echo "    |  wiederhergestellt!                       |"
	echo "    +-------------------------------------------+"
	echo
	
	
	
	if ! [[ -z "$1" ]] ; then
		exit 0
	fi
	
	ta_read
}

ta_quit () {
	if [ $mainmenu -eq 1 ] ; then
		# zurueck springen
		echo -en "\r\033[3B"
	fi
	
	# beenden
	exit 1
}


# pruefen, ob adb verfuegbar ist
if ! hash adb 2>/dev/null ; then
	echo "Fehler: adb wurde nicht gefunden"
	exit 1
fi


if ! [[ -z "$1" ]] ; then
	echo
	echo "    +-------------------------------------------+"
	echo "    |         Xperia TA Backup/Restore          |"
	echo "    +-------------------------------------------+"
	echo "    |  Achtung: Benutzung des Tools auf eigene  |"
	echo "    |           Gefahr! Weder ich noch sonst    |"
	echo "    |           irgendwer anderes, außer dir,   |"
	echo "    |           ist für eventuelle Schäden am   |"
	echo "    |           Gerät verantwortlich!           |"
	echo "    |                                           |"
	echo "    |  Von Jonathan Klamroth                    |"
	echo "    |      jonathan.klamroth@gmail.com          |"
	echo "    +-------------------------------------------+"
	echo
	
	if [ -f "$1" ] ; then
		ta_clear_input
		read -p "Das Backup '$1' wiederherstellen? (y/n) " x
		
		if [[ "$x" == "y" ]] || [[ "$x" == "Y" ]] ; then
			ta_restore "$1"
		else
			echo "Abgebrochen."
			exit 0
		fi
	else
		ta_clear_input
		read -p "Ein Backup erstellen und in '$1' schreiben? (y/n) " x
		
		if [[ "$x" == "y" ]] || [[ "$x" == "Y" ]] ; then
			ta_backup "$1"
		else
			echo "Abgebrochen."
			exit 0
		fi
	fi
fi


# catch ctrl+c
trap "ta_quit" 2


while true ; do
	mainmenu=1
	clear
	
	# menu anzeigen
	echo
	echo "    +-------------------------------------------+"
	echo "    |         Xperia TA Backup/Restore          |"
	echo "    +-------------------------------------------+"
	echo "    |  Achtung: Benutzung des Tools auf eigene  |"
	echo "    |           Gefahr! Weder ich noch sonst    |"
	echo "    |           irgendwer anderes, außer dir,   |"
	echo "    |           ist für eventuelle Schäden am   |"
	echo "    |           Gerät verantwortlich!           |"
	echo "    |                                           |"
	echo "    |  Von Jonathan Klamroth                    |"
	echo "    |      jonathan.klamroth@gmail.com          |"
	echo "    +-------------------------------------------+"
	echo "    |  1) Backup                                |"
	echo "    |  2) Restore                               |"
	echo "    |  3) Beenden                               |"
	echo "    +-------------------------------------------+"
	echo "    |  Auswahl:                                 |"
	echo "    +-------------------------------------------+"
	
	# zur auswahl springen
	echo -en "\033[2A\033[16C"
	
	# auswahl einlesen
	ta_clear_input
	read -n1 x
	
	# zurueck springen
	echo -en "\r\033[3B"
	
	mainmenu=0
	case $x in
		1)
			ta_backup
			;;
		
		2)
			ta_restore
			;;
		
		3)
			exit 0
			;;
		
		
		*)
			echo -en "\r\033[3A\033[16C     Auswahl ungültig!"
			sleep 1
			;;
	esac
done

