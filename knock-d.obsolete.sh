#!/bin/bash /etc/rc.common
# by 1um3n
#
#	 			___ port knocking daemon 4 openwrt ___
#
#
# script ajouté dans /etc/init.d/knock-d.sh	#	#	#	#	#	#	#

START=99
STOP=1
USE_PROCD=1

# Option 1: session SSH (mode propre)
# Option 2: session SSH (mode paranoid)
# Option 3: Nmaper adresse source
# Option 4: ? (Anti DoS?)

INET_IFACE=
LAN_IFACE=
INET_IP=
LAN_IP=
PORT_SSH=41513
SPORT_P1_1=72771
SPORT_P2_1=56811
SPORT_P2_2=80332
SPORT_P1_3=60673
SPORT_P2_3=73103
SPORT_P1_4=40064
SPORT_P2_4=78634
DPORT=51413

# les fonctions :

	calcul_index() {
		# on passe la chaine en 1er argument et la recherche en 2eme
		chaine=$1;
		recherche=$2;
		# on enleve la valeur de la variable "recherche" et tout ce qui suit dans la variable chaine :
		debut_chaine="${chaine%%${recherche}*}";
		# la longueur de la nouvelle chaine correspond à position de l'élement recherche :
		position=$((${#debut_chaine}));
		#Si l'élément recherché ne se trouve pas dans la chaine, on met la valeur de "position" à "0" :
		if [ "$position" -eq $((${#chaine})) ] 
		then 
			position="0";
		fi
		echo $position;
	}
	extract_adresse_source() {
		# calcul position :
		i1=$(calcul_index "$1" "SRC=");
		position_debut=$(($i1+4));
		# calcul longueur :
		i2=$(calcul_index "$1" "DST=");
		n=$(($i2-1));
		longueur=$(($n-$position_debut));
		# extraction de l'adresse :
		echo ${1:$position_debut:$longueur}; 
	}
	extract_port_destination() {
		# calcul position :
		i1=$(calcul_index "$1" "DPT=");
		position_debut=$(($i1+4));
		# calcul longueur :
		i2=$(calcul_index "$1" "LEN=");
		n=$(($i2-1));
		longueur=$(($n-$position_debut));
		# extraction de l'adresse :
		echo ${1:$position_debut:$longueur}; 
	}
	verification_temps() {
		convert_mois () {
			case $1 in                                                                                                         
			Jan ) echo 01 ;;                                                                                                   
			Feb ) echo 02 ;;                                                                                                   
			Mar ) echo 03 ;;                                                                                                   
			Apr ) echo 04 ;;                                                                                                   
			May ) echo 05 ;;                                                                                                   
			Jun ) echo 06 ;;                                                                                                   
			Jul ) echo 07 ;;                                                                                                   
			Aug ) echo 08 ;;                                                                                                   
			Sep ) echo 09 ;;                                                                                                   
			Oct ) echo 10 ;;                                                                            
			Nov ) echo 11 ;;                                                                            
			Dec ) echo 12 ;;                                                                            
			* ) echo FALSE;;                                                                            
			esac
		}			
		# verifier si le premier paquet est entre il y a moins de 1 seconde :                        
		heure=${1:11:8}                                                                             
		annee=${1:20:4}                                                                             
		mois_nc=${1:4:3}                                                                            
		mois=$(convert_mois "$mois_nc")                                                             
		jour=${1:8:2}                                                                               
		date_paquet=$annee"-"$mois"-"$jour" "$heure                                                 
		#convertir un timestamp en date :                                                            
		#date -d @1314826776                                                               
		#convertir la date en timestamp :                                                  
		t_paquet=`date -d "$date_paquet" +%s`                                             
                # inferieur ou egal au timestamp actuel moins 4 seconde ?        
                t_systeme=$(date +%s)                                              
                ecart=$(($t_systeme - 4))                                          
                if [ "$t_paquet" -ge "$ecart" ]                                    
                then                                                               
                        echo 0;                                                    
                else                                                              
                        echo 1;                                                   
                fi                                                                 
        }
	generation_ip() {
		echelle=255
		nombre1=$RANDOM
		nombre2=$RANDOM
		nombre3=$RANDOM
		nombre4=$RANDOM
		let "nombre1 %= $echelle"
		let "nombre2 %= $echelle"
		let "nombre3 %= $echelle"
		let "nombre4 %= $echelle"
		echo $nombre1.$nombre2.$nombre3.$nombre4	
	}
	function plus_ou_moins () {
		#nombre=$(( $nbr % 2 ))
			n=$(( $1 % 2 ))
			if [ "$1" == "255" ]
			then
				result="255"
			elif [ $n -eq 0 ]
			then
				result="pair"
			elif [ $n -ne 0 ]
			then
				result="impair"
			fi
			echo $result
		}
	extract_port_source() {
		# calcul position :
		i1=$(calcul_index "$1" "SPT=");
		position_debut=$(($i1+4));
		# calcul longueur :
		i2=$(calcul_index "$1" "DPT=");
		n=$(($i2-1));
		longueur=$(($n-$position_debut));
		# extraction de l'adresse :
		echo ${1:$position_debut:$longueur}; 
	}
	function demise_au_secret () 
		{
			# -7
			case $2 in
				"255" ) n=$1 ;;
				"pair" ) n=$(( $1 -7 )) ;;
				"impair" ) n=$(($1 + 7)) ;;
			esac
			echo $n
		}



# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	start_service() {
		# logs :
		logger starting knock-d.sh
		echo Le `date +%Y%m%d` a `date +%T` : "starting knock-d.sh" >> /var/log/knock.log

		# ajoute une regle pour qu'iptable log en INPUT :
		#iptables -I INPUT -j LOG;
	
		while true
		do
			# =============== Option 1: session SSH (mode propre) : ===============
			if [ -n "`logread | tail -n 200 | grep SPT=$SPORT_P1_1 | grep DPT=$DPORT`" ] && [  -n "`logread | tail -n 200 | grep SPT=$SPORT_P2_1 | grep DPT=$DPORT`" ]
			then 
				parse1=$(logread | tail -n 200 | grep SPT=$SPORT_P1_1 | grep DPT=$DPORT)
				parse2=$(logread | tail -n 200 | grep SPT=$SPORT_P2_1 | grep DPT=$DPORT)

				# Verifications :
				# stocker les 2 IP et les comparer :
				IP_SOURCE=$(extract_adresse_source "$parse1")
				ip2=$(extract_adresse_source "$parse2")
				# verification du temps :
				time=$(verification_temps "$parse1")
				if [ "$IP_SOURCE" == "$ip2" ] && [ "$time" == "0" ] 
				then
					# ajout des regles iptables :
					iptables -t nat -A PREROUTING -i $INET_IFACE -p tcp -s $IP_SOURCE --dport $PORT_SSH -j DNAT --to-destination $LAN_IP:22
					iptables -t nat -A POSTROUTING -o $LAN_IFACE -p tcp -s $IP_SOURCE -d $LAN_IP --dport 22 -j SNAT --to-source $INET_IP
					iptables -t nat -A PREROUTING -i $LAN_IFACE -p tcp -s $LAN_IP --sport 22 -d $INET_IP -j DNAT --to-destination $IP_SOURCE
					iptables -t nat -A POSTROUTING -o $INET_IFACE -p tcp -s $LAN_IP -d $IP_SOURCE -j SNAT --to-source $INET_IP:$PORT_SSH #changer -o durant les tests!
					iptables -I FORWARD -i $INET_IFACE -p tcp -s $IP_SOURCE -d $LAN_IP --dport 22 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT # TODO completer pour etre plus restrictif 
					echo Le `date +%Y%m%d` a `date +%T` : "ouverture port \"$PORT_SSH\" pour session ssh de  l' IP : \"$IP_SOURCE\" " >> /var/log/knock.log

					sleep 4

					# suppression des regles iptables :
					iptables -D FORWARD -i $INET_IFACE -p tcp -s $IP_SOURCE -d $LAN_IP --dport 22 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT  
					iptables -t nat -D PREROUTING -i $INET_IFACE -p tcp -s $IP_SOURCE --dport $PORT_SSH -j DNAT --to-destination $LAN_IP:22
					iptables -t nat -D POSTROUTING -o $LAN_IFACE -p tcp -s $IP_SOURCE -d $LAN_IP --dport 22 -j SNAT --to-source $INET_IP
					iptables -t nat -D PREROUTING -i $LAN_IFACE -p tcp -s $LAN_IP --sport 22 -d $INET_IP -j DNAT --to-destination $IP_SOURCE
					iptables -t nat -D POSTROUTING -o $INET_IFACE -p tcp -s $LAN_IP -d $IP_SOURCE -j SNAT --to-source $INET_IP:$PORT_SSH
					echo Le `date +%Y%m%d` a `date +%T` :"fermeture port \"$PORT_SSH\"" >> /var/log/knock.log
				fi
				



			# =============== Option 2: session SSH (mode paranoid) : ===============
			elif [ -n "`logread | tail -n 300 | grep SPT=$SPORT_P2_2 | grep DPT=$DPORT`" ] && [ -n "`logread | tail -n 300 | grep SRC=194. | grep .45. | grep DPT=$DPORT`" ]
			then
				# verifier la presence du 3eme paquet
				if [ -n "`logread | tail -n 300 | grep SRC=78. | grep .202. | grep DPT=$DPORT`" ]
				then
					nbr_paquets=3
					parse3=$(logread | tail -n 300 | grep SRC=78. | grep .202. | grep DPT=$DPORT)
					sport3=$(extract_port_source "$parse3")
				else
					nbr_paquets=2
				fi
				time=$(verification_temps "$parse1")
				# parse les deux paquets
				parse2=$(logread | tail -n 200 | grep SPT=$SPORT_P2_2 | grep DPT=$DPORT)
				parse1=$(logread | tail -n 200 | grep SRC=194. | grep .45. | grep DPT=$DPORT)
				# adresse source du paquet motif, compter le nombre de chaque terme et le nombre total et verifier si pair, impair ou 255
				motif=$(extract_adresse_source "$parse2")
				terme1=`echo "$motif"|cut -d. -f 1` 
				terme2=`echo "$motif"|cut -d. -f 2`
				terme3=`echo "$motif"|cut -d. -f 3`
				terme4=`echo "$motif"|cut -d. -f 4`
				nbr=`echo "$motif"|wc -m`
				nbr_total=$(($nbr - 4)) 
				lng1=$((`echo "$terme1"|wc -m` - 1))
				lng2=$((`echo "$terme2"|wc -m` - 1))
				lng3=$((`echo "$terme3"|wc -m` - 1))
				lng4=$((`echo "$terme4"|wc -m` - 1))
				parite1=$(plus_ou_moins "$terme1")
				parite2=$(plus_ou_moins "$terme2")
				parite3=$(plus_ou_moins "$terme3")
				parite4=$(plus_ou_moins "$terme4")
				# recuperer port source de l'autre paquet ainsi que les 2eme et 4eme terme de l'adresse source et reconstituer $secretRassemble
				sport1=$(extract_port_source "$parse1")
				adrss=$(extract_adresse_source "$parse1")
				trm2=`echo "$adrss"|cut -d. -f 2`
				trm4=`echo "$adrss"|cut -d. -f 4`
				case $nbr_total in
					4 ) secretRassemble=$sport1 ;;                                                                                                   
					5 ) secretRassemble=$sport1${trm2:0:1} ;;                                                                                                   
					6 ) secretRassemble=$sport1${trm2:0:2} ;;                                                                        
					7 ) secretRassemble=$sport1${trm2:0:2}${trm4:0:1} ;;                                                                                                   
					8 ) secretRassemble=$sport1${trm2:0:2}${trm4:0:2} ;;                                                                                                   
					9 ) secretRassemble=$sport1${trm2:0:2}${trm4:0:2}${sport3:0:1} ;;                                                                                                   
					10 ) secretRassemble=$sport1${trm2:0:2}${trm4:0:2}${sport3:0:2} ;;                                                                  
					11 ) secretRassemble=$sport1${trm2:0:2}${trm4:0:2}${sport3:0:3} ;;                                                                 
					12 ) secretRassemble=$sport1${trm2:0:2}${trm4:0:2}${sport3:0:4} ;;                                                                 
                                                                                   
					# * ) echo FALSE;;                                                                            
				esac
				# couper a nouveau chaque terme selon paquet motif et demise_au_secret() 
				t1=${secretRassemble:0:$lng1}
				depart2=$(( 0 + $lng1 ))
				t2=${secretRassemble:$depart2:$lng2}
				depart3=$(( $depart2 + $lng2 ))
				t3=${secretRassemble:$depart3:$lng3}
				depart4=$(( $depart3 + $lng3 ))
				t4=${secretRassemble:$depart4:$lng4}
				veritas1=$(demise_au_secret "$t1" "$parite1")
				veritas2=$(demise_au_secret "$t2" "$parite2")
				veritas3=$(demise_au_secret "$t3" "$parite3")
				veritas4=$(demise_au_secret "$t4" "$parite4")
				# reconstitution de l'adresse source et regles iptables
				adresse_source=$veritas1.$veritas2.$veritas3.$veritas4

				iptables -t nat -A PREROUTING -i $INET_IFACE -p tcp -s $adresse_source --dport $PORT_SSH -j DNAT --to-destination $LAN_IP:216
				iptables -t nat -A POSTROUTING -o $LAN_IFACE -p tcp -s $adresse_source -d $LAN_IP --dport 216 -j SNAT --to-source $INET_IP
				iptables -t nat -A PREROUTING -i $LAN_IFACE -p tcp -s $LAN_IP --sport 216 -d $INET_IP -j DNAT --to-destination $adresse_source
				iptables -t nat -A POSTROUTING -o $INET_IFACE -p tcp -s $LAN_IP -d $adresse_source -j SNAT --to-source $INET_IP:$PORT_SSH 
				iptables -I FORWARD -i $INET_IFACE -p tcp -s $adresse_source -d $LAN_IP --dport 216 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT  
				echo Le `date +%Y%m%d` a `date +%T` : "ouverture port \"$PORT_SSH\" pour session ssh \"paranoiac mode\"" >> /var/log/knock.log

				sleep 4

				# suppression des regles iptables 
				iptables -D FORWARD -i $INET_IFACE -p tcp -s $adresse_source -d $LAN_IP --dport 216 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT  
				iptables -t nat -D PREROUTING -i $INET_IFACE -p tcp -s $adresse_source --dport $PORT_SSH -j DNAT --to-destination $LAN_IP:216
				iptables -t nat -D POSTROUTING -o $LAN_IFACE -p tcp -s $adresse_source -d $LAN_IP --dport 216 -j SNAT --to-source $INET_IP
				iptables -t nat -D PREROUTING -i $LAN_IFACE -p tcp -s $LAN_IP --sport 216 -d $INET_IP -j DNAT --to-destination $adresse_source
				iptables -t nat -D POSTROUTING -o $INET_IFACE -p tcp -s $LAN_IP -d $adresse_source -j SNAT --to-source $INET_IP:$PORT_SSH
				echo Le `date +%Y%m%d` a `date +%T` :"fermeture port \"$PORT_SSH\"" >> /var/log/knock.log
				




			# =============== Option 3: Nmaper adresse source : ===============
			elif [ -n "`logread | tail -n 200 | grep SPT=$SPORT_P1_3 | grep DPT=$DPORT`" ] && [  -n "`logread | tail -n 200 | grep SPT=$SPORT_P2_3 | grep DPT=$DPORT`" ]
			then 
				parse1=$(logread | tail -n 200 | grep SPT=$SPORT_P1_3 | grep DPT=$DPORT);
				parse2=$(logread | tail -n 200 | grep SPT=$SPORT_P2_3 | grep DPT=$DPORT);

				# Verifications :
				# stocker les 2 IP et les comparer
				IP_SOURCE=$(extract_adresse_source "$parse1")
				ip2=$(extract_adresse_source "$parse2")
				if [ "$IP_SOURCE" == "$ip2" ]  
				then
				echo Le `date +%Y%m%d` a `date +%T` : "nmap de l'adresse \"$IP_SOURCE\" : \n" >> /var/log/knock.log
				# IP aleatoire : 
				nmap -T4 -n -O -Pn $IP_SOURCE >> /var/log/knock.nmap.log 

			fi




			# =============== Option 4: ? (Anti DoS?) : ===============
			elif [ -n "`logread | tail -n 200 | grep SPT=$SPORT_P1_4 | grep DPT=$DPORT`" ] && [  -n "`logread | tail -n 200 | grep SPT=$SPORT_P2_4 | grep DPT=$DPORT`" ]
			then
				sleep 1
				# ...



			fi
		done
		exit 0;
	}
	
	
	stop_service() {
		echo Le `date +%Y%m%d` a `date +%H` : "stopping knock-d.sh" >> /tmp/knock.log;
		logger stopping knock-d.sh

		exit 0;
	}
