#!/bin/bash
ETC_HOSTS=/etc/hosts
HOSTNAME=$2
IP=$1

addhost() {
    echo "adding host";
    HOSTS_LINE="$IP\t$HOSTNAME"
    if [ -n "$(grep $HOSTNAME /etc/hosts)" ]
        then
            echo "$HOSTNAME already exists : $(grep $HOSTNAME $ETC_HOSTS)"
        else
            echo "Adding $HOSTNAME to your $ETC_HOSTS";
            sudo -- sh -c -e "echo '$HOSTS_LINE' >> /etc/hosts";

            if [ -n "$(grep $HOSTNAME /etc/hosts)" ]
                then
                    echo "$HOSTNAME was added succesfully \n $(grep $HOSTNAME /etc/hosts)";
                else
                    echo "Failed to Add $HOSTNAME, Try again!";
					exit
            fi
    fi
}


function usage {
	echo "#     usage													"
	echo "#     > ./ctf_me IP HOSTNAME									"
	echo "#         													"		
	echo "#        : 	IP												"	
	echo "#         	Enter the CTF Box IP							"	
	echo "#         													"
	echo "#        :   HOSTNAME 										"	
	echo "#         	Enter the HOSTNAME you would like to set		"	
	echo "#         													"	
	echo "#         	Example: grandpa.htb							"
	echo "#						 steelmountain.thm						"
	echo "#         													"	
	echo "#       **WARNING**  											"	
	echo "#         Script WILL install GoBuster and Sublit3r			"	
	echo "#         													"		
	echo "#		Created by @aChocolateChippPancake 						"
}
function needSomeSpace {
echo -e " "
echo -e " "
echo -e " "
echo -e " "
echo -e " "
echo -e " "
echo -e " "
echo -e " "
}



if [ `whoami` != root ]; then
    echo "Please run this script as root or using sudo"
    exit
fi


# IP and hostname are provided
if [ -z "$1" ] || [ -z "$2" ]
  then
	usage
	exit;
fi
# check for help
if [ $1 = "help" ] || [ $1 = "h" ] || [ $1 = "-h" ] || [ $1 = "-help" ]; then
	usage
	exit;
fi
# Checking if directory exists
if [ -d "ctf_me" ] 
then
	echo -e "The directory ctf_me Exists!"
	echo -e "**************************************"
	echo -e "**************************************"
	echo -e "**************************************"
	echo -e "**************************************"
	echo -e "Creating folder for $HOSTNAME		   "
	mkdir ctf_me/$HOSTNAME
	echo -e "**************************************"
	echo -e "**************************************"
	echo -e "**************************************"
	echo -e "**************************************"
fi
# If it does not exist, create it
echo -e "Directory does not exist... making it"
mkdir -p ctf_me/$HOSTNAME
needSomeSpace




#test if host is live
if ping -c 1 -W 1 $HOSTNAME; then
  echo "$HOSTNAME is Alive"
else
	echo "$HOSTNAME is Down"
	echo "Check VPN Connection"
	exit;
fi

echo -e "Start Nmap Scans"
mkdir ctf_me/$HOSTNAME/nmap
# Read the output of the nmap | awk commands into the ports array
IFS=$'\n' read -r -d '' -a ports < <(
  # Pipe the result of nmap to awk for processing
  nmap -sS -oA ctf_me/$IP/openports "$IP" |
    awk -F'/' '
      /[[:space:]]+open[[:space:]]+/{
        p[$IP]++
      }
      END{
      for (k in p)
        print k
    }'
)
portlist=""

if [ ${#ports[@]} -gt 0 ]; then
  for p in "${ports[@]}"; do
    portlist+=$p","
  done
fi
portlist=${portlist::-1}
if [ -z "$portlist" ]
then
      echo "No ports available"
	  echo "Exiting"
	  exit;
else

# portlist has been created

# check if 21 exists, then try anonymous login
if [[ $portlist == *"21"* ]]; then
	echo "Scanning For anonymous FTP result"
	nmap -T5 -p 21 --script ftp-anon $IP -oA ctf_me/$HOSTNAME/nmap/AnonFTP
fi

# check / scan for RDP
if [[ $portlist == *"3389"* ]]; then
	echo "Scanning for RDP Ciphers and connection details"
	nmap -T5 -p 3389 --script rdp-enum-encryption $IP -oA ctf_me/$HOSTNAME/nmap/RDPEnum
fi
# check / scan for SMB
if [[ $portlist == *"445"* ]]; then
	echo "Scanning for RDP Ciphers and connection details"
	nmap --script smb-os-discovery.nse -p445 $IP -oA ctf_me/$HOSTNAME/nmap/SMBenum
fi

echo "Generic Version Scan"
nmap -sV -sC -O -p $portlist $IP -oA ctf_me/$HOSTNAME/nmap/Generic_OS -Pn

echo "Vulnerability Scan"
nmap --script vuln -p $portlist $IP -oA ctf_me/$HOSTNAME/nmap/vulnerabilityScan -Pn

echo "Scan UDP"
nmap -v -T5 -Pn -sU --top-ports 100 $1 -oA ctf_me/$1/nmap/UDPScan

# nmaps completed

# GoBuster with /usr/share/rockyou.txt
mkdir ctf_me/$HOSTNAME/gobuster_output
wordlist=/usr/share/rockyou.txt
if test -f "$wordlist"; then
    echo "$wordlist exists."
else
	echo "Unzipping Rockyou.txt"
	gzip -d /usr/share/wordlists/rockyou.txt.gz
	echo "Rockyou.txt unzipped."
fi

echo "Checking for GoBuster"
if ! command -v <gobuster> &> /dev/null
then
    echo "gobuster was not found"
	echo "***Installing***"
	apt install gobuster
else
	echo "gobuster is already installed. Continuing."
fi

if [[ $portlist == *"80"* ]]; then
	echo "Directory Enumeration via Port 80"
	gobuster -e -u http://$HOSTNAME:80/ -w /usr/share/wordlists/rockyou.txt -o ctf_me/$HOSTNAME/gobuster_output/port_80_output.txt
fi
if [[ $portlist == *"443"* ]]; then
	echo "Directory Enumeration via Port 443"
	gobuster -e -u http://$HOSTNAME:443/ -w /usr/share/wordlists/rockyou.txt -o ctf_me/$HOSTNAME/gobuster_output/port_443_output.txt
fi
if [[ $portlist == *"8080"* ]]; then
	echo "Directory Enumeration via Port 8080"
	gobuster -e -u http://$HOSTNAME:8080/ -w /usr/share/wordlists/rockyou.txt -o ctf_me/$HOSTNAME/gobuster_output/port_8080_output.txt
fi


echo "Checking for sublist3r"
if ! command -v <sublist3r> &> /dev/null
then
    echo "sublist3r was not found"
	echo "***Installing***"
	apt install sublist3r
else
	echo "sublist3r is already installed. Continuing."
fi
mkdir ctf_me/$HOSTNAME/sublist3r_output
sublist3r -d $HOSTNAME -b -t 100 --output ctf_me/$HOSTNAME/sublist3r_output/sublist3r_output.txt

