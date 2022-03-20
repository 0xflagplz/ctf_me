#!/bin/bash
ETC_HOSTS=/etc/hosts
HOSTNAME=$2
IP=$1

# Function which adds host to /etc/hosts
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
	echo "#     > ./ctf_me IP HOSTNAME											"
	echo "#         													"		
	echo "#        : 	IP												"	
	echo "#         	Enter the CTF Box IP										"	
	echo "#         													"
	echo "#        :   HOSTNAME 												"	
	echo "#         	Enter the HOSTNAME you would like to set							"	
	echo "#         													"	
	echo "#         	Example: grandpa.htb										"
	echo "#						 steelmountain.thm							"
	echo "#         													"	
	echo "#       **WARNING**  												"	
	echo "#         Script WILL install GoBuster and Sublit3r								"	
	echo "#         													"		
	echo "#		Created by @aChocolateChippPancake 									"
}
if [ `whoami` != root ]; then
    echo "Please run this script as root or using sudo"
    exit
fi

# add host to /etc/hosts
addhost()

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
	echo "The directory ctf_me Exists!"
	echo "**************************************"
	echo "**************************************"
	echo "**************************************"
	echo "**************************************"
	echo "Creating folder for $HOSTNAME		   "
	mkdir ctf_me/$HOSTNAME
	echo "**************************************"
	echo "**************************************"
	echo "**************************************"
	echo "**************************************"
fi

# If it does not exist, create it
echo "Directory does not exist... making it"
echo ""
echo ""

# Make parent Directory [ctf name]
mkdir -p ctf_me/$HOSTNAME

#test if host is live
if ping -c 1 -W 1 $HOSTNAME; then
  echo "$HOSTNAME is Alive"
  echo ""
  echo ""
  echo ""
else
	echo "$HOSTNAME is Down"
	echo "Check VPN Connection"
	exit;
fi

echo "Start Nmap Scans"

# Make nmap directory
mkdir ctf_me/$HOSTNAME/nmap

# Read the output of the nmap | awk commands into the ports array
IFS=$'\n' read -r -d '' -a ports < <(
  # Pipe the result of nmap to awk for processing
  nmap -sS -oA ctf_me/$HOSTNAME/openports "$IP" |
    awk -F'/' '
      /[[:space:]]+open[[:space:]]+/{
        p[$IP]++
      }
      END{
      for (k in p)
        print k
    }'
)

emptylist=""

# Go through the output ports and add them into a conjoined string like 21,80,8080
if [ ${#ports[@]} -gt 0 ]; then
  for p in "${ports[@]}"; do
  	q="${p:0:2}";
    	emptylist+=$q","
  done
fi

# Edit list name and remove last comma
portlist=${emptylist::-1};
echo "$portlist"

if [[ ! $portlist =~ [0-9] ]]; then
	echo "No Ports are Open!"
	exit;
fi

# portlist has been created

# check if 21 exists, then try anonymous login
if [[ $portlist = *"21"* ]]; then
	echo "Scanning For anonymous FTP result"
	mkdir ctf_me/$HOSTNAME/nmap/AnonFTP
	nmap -T5 -p 21 --script ftp-anon $IP -oA ctf_me/$HOSTNAME/nmap/AnonFTP/AnonFTP
else
	echo "Port 21 is not open skipping FTP Scan..."
fi


# check / scan for RDP
if [[ $portlist == *"3389"* ]]; then
	echo "Scanning for RDP Ciphers and connection details"
	mkdir tf_me/$HOSTNAME/nmap/RDPEnum
	nmap -T5 -p 3389 --script rdp-enum-encryption $IP -oA ctf_me/$HOSTNAME/nmap/RDPEnum/RDPEnum
else
	echo "Port 3389 is not open skipping RDP scan..."
fi

# check / scan for SMB
if [[ $portlist == *"445"* ]]; then
	echo "Scanning for SMB"
	mkdir ctf_me/$HOSTNAME/nmap/SMB_Scan
	nmap --script=smb-enum-shares.nse,smb-enum-users.nse,smb-os-discovery.nse -p445 $IP -oA ctf_me/$HOSTNAME/nmap/SMB_Scan/SMBenum
	nmap -p 445 -vv --script=smb-vuln-cve2009-3103.nse,smb-vuln-ms06-025.nse,smb-vuln-ms07-029.nse,smb-vuln-ms08-067.nse,smb-vuln-ms10-054.nse,smb-vuln-ms10-061.nse,smb-vuln-ms17-010.nse $IP -oA ctf_me/$HOSTNAME/nmap/SMB_Scan/SMBvulnerabilitycheck
	nmap –script smb-check-vulns.nse –script-args=unsafe=1 -p445 $IP -oA ctf_me/$HOSTNAME/nmap/SMB_Scan/anotherVulnCheck
	
else
	echo "Port 445 is not open skipping SMB scan..."
fi


echo "Generic Version Scan"
mkdir ctf_me/$HOSTNAME/nmap/Generic_OS
nmap -sV -sC -O -p $portlist $IP -oA ctf_me/$HOSTNAME/nmap/Generic_OS/Generic_OS -Pn

#echo "Vulnerability Scan"
#mkdir ctf_me/$HOSTNAME/nmap/vulnerabilityScan
#nmap -T4 --script vuln -p $portlist $IP -oA ctf_me/$HOSTNAME/nmap/vulnerabilityScan/vulnerabilityScan 

echo "Scan UDP"
mkdir ctf_me/$HOSTNAME/nmap/UDPScan
nmap -v -T5 -Pn -sU --top-ports 100 $IP -oA ctf_me/$HOSTNAME/nmap/UDPScan/UDPScan


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

command -v gobuster >/dev/null 2>&1 || 
{ 
	echo >&2 "gobuster was not found\n********Installing********"; 
	apt install gobuster;
}


if [[ $portlist == *"80"* ]]; then
	echo "Directory Enumeration via Port 80"
	gobuster dir -u http://$IP:80/ -w /usr/share/wordlists/rockyou.txt -o ctf_me/$HOSTNAME/gobuster_output/port_80_output.txt -t 50 --wildcard switch
else
	echo "Port 80 is not open skipping Directory Enumeration Attempt 1"
fi

if [[ $portlist == *"443"* ]]; then
	echo "Directory Enumeration via Port 443"
	gobuster dir -u http://$IP:443/ -w /usr/share/wordlists/rockyou.txt -o ctf_me/$HOSTNAME/gobuster_output/port_443_output.txt -t 50
else
	echo "Port 443 is not open skipping Directory Enumeration Attempt 2"
fi

if [[ $portlist == *"8080"* ]]; then
	echo "Directory Enumeration via Port 8080"
	gobuster dir -u http://$IP:8080/ -w /usr/share/wordlists/rockyou.txt -o ctf_me/$HOSTNAME/gobuster_output/port_8080_output.txt -t 50
else
	echo "Port 8080 is not open skipping Directory Enumeration Attempt 3"
fi



echo "Checking for sublist3r"

command -v sublist3r >/dev/null 2>&1 || 
{ 
	echo >&2 "sublist3r was not found\n********Installing********"; 
	apt install sublist3r;
}

mkdir ctf_me/$HOSTNAME/sublist3r_output
sublist3r -d $HOSTNAME -b -t 100 --output ctf_me/$HOSTNAME/sublist3r_output/sublist3r_output.txt


