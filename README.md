# ctf_me

## This begins deafult nmap / gobuster / sublist3r
### I do plan on adding more tools, but I just need to automate all the annoying things you do 100% of the time
	===========================================================================================================================
     usage													
     > ./name IP HOSTNAME									
         															
        : 	IP													
         	Enter the CTF Box IP								
         													
        :   HOSTNAME 											
         	Enter the HOSTNAME you would like to set			
         														
         	Example: grandpa.htb							
						 steelmountain.thm						
         														
       **WARNING**  												
         Script WILL install GoBuster and Sublit3r				
         															
		Created by @aChocolateChippPancake 	
	===========================================================================================================================
Default Scans:
  > nmap -sV -sC -O -p $portlist $IP -oA ctf_me/$HOSTNAME/nmap/Generic_OS -Pn
  > nmap --script vuln -p $portlist $IP -oA ctf_me/$HOSTNAME/nmap/vulnerabilityScan -Pn
  > nmap -v -T5 -Pn -sU --top-ports 100 $1 -oA ctf_me/$1/nmap/UDPScan
  > sublist3r -d $HOSTNAME -b -t 100 --output ctf_me/$HOSTNAME/sublist3r_output/sublist3r_output.txt

IF Port 3389:
> nmap -T5 -p 3389 --script rdp-enum-encryption $IP -oA ctf_me/$HOSTNAME/nmap/RDPEnum

IF Port 445:
> nmap --script smb-os-discovery.nse -p445 $IP -oA ctf_me/$HOSTNAME/nmap/SMBenum

IF Port  80:
> gobuster -e -u http://$HOSTNAME:80/ -w /usr/share/wordlists/rockyou.txt -o ctf_me/$HOSTNAME/gobuster_output/port_80_output.txt

IF Port 8080:
> gobuster -e -u http://$HOSTNAME:8080/ -w /usr/share/wordlists/rockyou.txt -o ctf_me/$HOSTNAME/gobuster_output/port_8080_output.txt

IF Port 443:
> gobuster -e -u http://$HOSTNAME:443/ -w /usr/share/wordlists/rockyou.txt -o ctf_me/$HOSTNAME/gobuster_output/port_443_output.txt
