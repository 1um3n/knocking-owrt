#!/bin/bash /etc/rc.common
# by 1um3n
#
#	 			___ port knocking script client  ___
#
#
# A utiliser avec Netcat	#	#	#	#	#	#	#	#	#



# Option 1: session SSH (mode propre)
# Option 2: session SSH (mode paranoid)
# Option 3: Nmaper adresse source
# Option 4: ? (Anti DoS?)


PORT_SSH=1112
SPORT_P1_1=72771
SPORT_P2_1=56811
SPORT_P2_2=80332
SPORT_P1_3=60673
SPORT_P2_3=73103
SPORT_P1_4=40064
SPORT_P2_4=78634
DPORT=51413
		


		function list ()
		{
			echo -e "                                                                      "
			echo -e "       Port-Kn 0 cking-                                               "
			echo -e "    0       Client        0                                           "
			echo -e "                                                                      "
			echo -e "              .ô.                                                     "
			echo -e "             /   \                                                    "
			echo -e "            (_   _)                                                   "
			echo -e "         o.-|_|-|_|-.o                                                "
			echo -e "           )   o   (                                                  "
			echo -e "          @         @                                                 "
			echo -e "         (           )                                                "
			echo -e "           '.  _  .'                                                  "
			echo -e "             O(_)O                                                    "
			echo -e "               °                                                      "
			echo -e "    0                     0                                           "
			echo -e "             0.2.1                                                    "
			echo -e "                                                                      "
			echo -e "                                                                      "
			echo -e "        0ption 1ist :                                                 "
			echo -e "                                                                      "
			echo -e "Option 1: session SSH (mode propre)"
			echo -e "Option 2: session SSH (mode parano)"
			echo -e "Option 3: Nmaper adresse source"
			echo -e "Option 4: ? (Anti DoS?)"
			echo -e " "
			echo -e " "
			echo -e -n "Enter option number : "
			read option
		}
		function dest ()
		{
			echo -e " "
			echo -e -n "Enter destination address : "
			read IP
			echo -e " "
		}
		function nombreAleatoire ()
		{
			if [ $1 -eq 1 ]
			then
				echelle=9 #entre 1 et 9
				plancher=1
				nombre=0
				while [ $nombre -lt $plancher ]
				do
					nombre=$RANDOM
					let "nombre %= $echelle"
				done
				echo $nombre
			elif [ $1 -eq 2 ]
			then
				echelle=99 #entre 11 et 99
				plancher=11
				nombre=0
				while [ $nombre -lt $plancher ]
				do
					nombre=$RANDOM
					let "nombre %= $echelle"
				done
				echo $nombre
			elif [ $1 -eq 3 ]
			then
				echelle=254 #entre 100 et 254 (exclure 192 et 172)
				plancher=100
				nombre=0
				while [ $nombre -lt $plancher ] 
					#&& [ $nombre -eq 192 ] && [ $nombre -eq 172 ]
				do
					nombre=$RANDOM
					let "nombre %= $echelle"
				done
				echo $nombre
			fi	
		}
		function mise_au_secret () 
		{
			# +7
			case $2 in
			1 ) if [ $1 -ge 3 ] && [ $1 -le 7 ]
			then
				n=$1	
				parite="255"	
			else
				n=$(($1 + 7))	
				parite="pair"
			fi ;;
			2 ) if [ $1 -gt 92 ]
			then
				n=$(($1 - 7))	
				parite="impair"
			else
				n=$(($1 + 7))	
				parite="pair"
			fi ;;
			3 ) if [ $1 -gt 248 ]
			then
				n=$(($1 - 7))	
				parite="impair"
			else
				n=$(($1 + 7))	
				parite="pair" 
			fi ;;
			esac
			echo $n
		}
		function plus_ou_moins () 
		{
			case $2 in
			1 ) if [ $1 -ge 3 ] && [ $1 -le 7 ]
			then
				parite="255"	#verifier!
			else
				parite="pair"
			fi ;;
			2 ) if [ $1 -gt 92 ]
			then
				parite="impair"
			else
				parite="pair"
			fi ;;
			3 ) if [ $1 -gt 248 ]
			then
				parite="impair"
			else
				parite="pair" #resoudre nom variable!
			fi ;;
			esac
			echo $parite
		}
		function pariteAleatoire () {
			# terme impair si resultat chiffrement paquetn=°1  >248  >92 et fin du terme = 255 si pas de  chiffrement car compris entre 3 et 7 compris
			nbr=$(nombreAleatoire "$2")
			nombre=$(( $nbr % 2 ))

			if [ "$1" == "pair" ]
			then
				while [ $nombre -ne 0 ]
				do
					nbr=$(nombreAleatoire "$2")
					nombre=$(( $nbr % 2 ))
				done
			elif [ "$1" == "impair" ]
			then
				while [ $nombre -eq 0 ]
				do
					nbr=$(nombreAleatoire "$2")
					nombre=$(( $nbr % 2 ))
				done
			elif [ "$1" == "255" ]
			then
				nbr=255
			fi
			echo $nbr
		}


		list;
		dest;




		# ===============         Option 1 : session ssh mode propre        ===============
		if [ $option -eq 1 ]
		then
			echo merci | nc -u -p $SPORT_P1_1 $IP $DPORT
			echo youpi | nc -u -p $SPORT_P2_1 $IP $DPORT
			echo ----------------------------------------- 
			sleep 2 
			ssh harmony@${IP} -p $PORT_SSH  





		# ===============         Option 2 : session ssh mode paranoid       ===============
		elif [ $option -eq 2 ]
		then
		# but :
		#	- ne pas reveler l'adresse source avant d'entamer la connexion ssh
		#	- garder les paquets du knocking indiferentiables parmis les autres paquets entrants 
		# (lancer en tant que root pour l'execution des regles iptables)

			# recuperation de l'adresse publique que j'utilise(veritable adresse source)
			ip_publique=`wget http://checkip.dyndns.org/ -O - -o /dev/null | cut -d: -f 2 | cut -d\< -f 1 | cut -d " " -f 2` 
echo $ip_publique
			terme1=`echo "$ip_publique"|cut -d. -f 1` 
			terme2=`echo "$ip_publique"|cut -d. -f 2`
			terme3=`echo "$ip_publique"|cut -d. -f 3`
			terme4=`echo "$ip_publique"|cut -d. -f 4`
			# nombre de chiffre de la veritable adresse source 
			nbr=`echo "$ip_publique"|wc -m`
			chiffres=$(($nbr - 4)) 
echo chiffres : $chiffres
			if [ $chiffres -ge 9 ]
			then 
				nbr_packets=3 
			else
				nbr_packets=2
			fi

			# ----- paquet n=°1 -----  
			# masquage de chaque terme :
			lng1=$((`echo "$terme1"|wc -m` - 1))
			secret1=$(mise_au_secret "$terme1" "$lng1")
			parite1=$(plus_ou_moins "$terme1" "$lng1")
			lng2=$((`echo "$terme2"|wc -m` - 1))
			secret2=$(mise_au_secret "$terme2" "$lng2")
			parite2=$(plus_ou_moins "$terme2" "$lng2")
			lng3=$((`echo "$terme3"|wc -m` - 1))
echo lng2 : $lng2
			secret3=$(mise_au_secret "$terme3" "$lng3")
			parite3=$(plus_ou_moins "$terme3" "$lng3")
echo secret3 : $secret3
			lng4=$((`echo "$terme4"|wc -m` - 1))
			secret4=$(mise_au_secret "$terme4" "$lng4")
			parite4=$(plus_ou_moins "$terme4" "$lng4")
			secretRassemble=$secret1$secret2$secret3$secret4
echo $secretRassemble
			nbrSecret=$((`echo "$secretRassemble"|wc -m` - 1))
			# 4 premiers chiffres -> port source
			SPORT_P1_2=${secretRassemble:0:4} 
echo sportP1 : $SPORT_P1_2
			# chiffres suivants dans 2eme et 4eme terme de l'adresse source + sport_p3 si besoin (devrait etre une fonction)
			case $nbrSecret in
			5 ) adrSrcT2=${secretRassemble:4:1}
				adrSrcT4=$(nombreAleatoire "3");;
			6 ) adrSrcT2=${secretRassemble:4:2}
				adrSrcT4=$(nombreAleatoire "3");;
			7 ) adrSrcT2=${secretRassemble:4:2}
				adrSrcT4_a=${secretRassemble:6:1}
				adrSrcT4_b=$(nombreAleatoire "1")
				adrSrcT4=$adrSrcT4a$adrSrcT4b;;
			8 ) adrSrcT2=${secretRassemble:4:2}
				adrSrcT4=${secretRassemble:6:2};;
			9 ) adrSrcT2=${secretRassemble:4:2}
				adrSrcT4=${secretRassemble:6:2}
				SPORT_P3_2_b=${secretRassemble:8:1}
				SPORT_P3_2_a=$(nombreAleatoire "1")
				SPORT_P3_2=$SPORT_P3_2_a$SPORT_P3_2_b;;
			10 ) adrSrcT2=${secretRassemble:4:2}
				adrSrcT4=${secretRassemble:6:2}
				SPORT_P3_2=${secretRassemble:8:2};;
			11 ) adrSrcT2=${secretRassemble:4:2}
				 adrSrcT4=${secretRassemble:6:2}
				 SPORT_P3_2=${secretRassemble:8:3};;
			12 ) adrSrcT2=${secretRassemble:4:2}
				 adrSrcT4=${secretRassemble:6:2}
				 SPORT_P3_2=${secretRassemble:8:4};;
			# * ) echo FALSE ;;
			esac
			adrSrcT1=194
			adrSrcT3=45
			ip_source_P1=$adrSrcT1.$adrSrcT2.$adrSrcT3.$adrSrcT4	

			# ----- paquet n=°2 (paquet-motif) ----- 
			# calcul adresse source|motif, debut de terme aleatoire
			aleaTerme1=$(pariteAleatoire "$parite1" "$lng1")
			aleaTerme2=$(pariteAleatoire "$parite2" "$lng2")
			aleaTerme3=$(pariteAleatoire "$parite3" "$lng3")
			aleaTerme4=$(pariteAleatoire "$parite4" "$lng4")
			ip_source_P2=$aleaTerme1.$aleaTerme2.$aleaTerme3.$aleaTerme4	
			iptables -t nat -A POSTROUTING -o wlan0 -p udp -d $IP --sport $SPORT_P1_2 -j SNAT --to-source $ip_source_P1
			iptables -t nat -A POSTROUTING -o wlan0 -p udp -d $IP --sport $SPORT_P2_2 -j SNAT --to-source $ip_source_P2
			if [ $nbr_packets == 3 ] 
			then
				aleaT2=$(nombreAleatoire "3")
				aleaT4=$(nombreAleatoire "1")
				ip_source_P3=78.$aleaT2.202.$aleaT4
				iptables -t nat -A POSTROUTING -o wlan0 -p udp -d $IP --sport $SPORT_P3_2 -j SNAT --to-source $ip_source_P3
				echo " " | nc -u -p $SPORT_P3_2 $IP $DPORT
			fi
			echo " " | nc -u -p $SPORT_P1_2 $IP $DPORT
			sleep 1.$(nombreAleatoire "1")	
			echo " " | nc -u -p $SPORT_P2_2 $IP $DPORT
			echo ----------------------------------------- 
			iptables -t nat -D POSTROUTING -o wlan0 -p udp -d $IP --sport $SPORT_P1_2 -j SNAT --to-source $ip_source_P1
			iptables -t nat -D POSTROUTING -o wlan0 -p udp -d $IP --sport $SPORT_P2_2 -j SNAT --to-source $ip_source_P2
			iptables -t nat -D POSTROUTING -o wlan0 -p udp -d $IP --sport $SPORT_P3_2 -j SNAT --to-source $ip_source_P3

			sleep 1.$(nombreAleatoire "1")	
			ssh harmony@${IP} -p $PORT_SSH  





		# =============== Option 3 : sequence pour nmaper l'adresse cliente ===============
		elif [ $option -eq 3 ]
		then
			echo " " | nc -u -p $SPORT_P1_3 $IP $DPORT
			echo " " | nc -u -p $SPORT_P2_3 $IP $DPORT






		# ===============             Option 4 : reaction DoS ?             ===============
		elif [ $option -eq 4 ]
		then		
			echo lotusbleu | nc -u -p $SPORT_P1_4 $IP $DPORT
			echo merci | nc -u -p $SPORT_P2_4 $IP $DPORT





		fi
		exit 0
