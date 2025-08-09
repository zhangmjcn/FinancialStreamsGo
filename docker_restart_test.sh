#\!/bin/sh
echo "$(date): Docker restart test started"
echo "$(date): This script will exit after 30 seconds to test restart policy"
sleep 30
echo "$(date): Script exiting to test restart mechanism"
exit 1
