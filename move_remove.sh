#move_Files from incoming to backupdir
#put the enrty in crontab for this script.Please find the sample enrty in the next line 
#0,2,4,6,8,10,12,14,16,18,20,24,26,28,30,32,34,36,38,40,42,44,46,48,50,52,54,56,58 * * * * /var/tmp/move_remove.sh >> /dev/null
#!/usr/bin/sh
`mv /var/DWS/incoming/CS40/CCN/*.ccn /var/DWS/bkp/CCN/`
`mv /var/DWS/incoming/CS40/CCN/*.CCN /var/DWS/bkp/CCN/`
`mv /var/DWS/incoming/CS40/AIR/*.AIR /var/DWS/bkp/AIR/`
`mv /var/DWS/incoming/CS40/SDP/*.ASN /var/DWS/bkp/SDP/`
`mv /var/DWS/incoming/CS40/SDP/*.SFD /var/DWS/bkp/SDP/`
`mv /var/DWS/incoming/CS40/SDP/*.ESFD /var/DWS/bkp/SDP/`
`mv /var/DWS/incoming/CS40/SDP/*.ADJ /var/DWS/bkp/SDP/`
`mv /var/DWS/incoming/CS40/SDP/*.LCY /var/DWS/bkp/SDP/`
`mv /var/DWS/incoming/CS40/SDP/*.lcy /var/DWS/bkp/SDP/`