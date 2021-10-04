#!/bin/bash

deviceHostName=$(hostname)
# Add emails you want to notify here. Emails will only be sent if one of the nodes fails it's health check.
declare -a jamfAdminEmail
jamfAdminEmail=( Email@example.com ) 
mailServer=mail.example.com

# To have tomcat nodes run the health chare add their FQDNs tot his array.
declare -a jamftomcatnodes
jamftomcatnodes=( jamf.example.com jamf2.example.com )

function Health_Check {
    healthCheckResult=$(curl -s https://${1}:8443/healthCheck.html |jq -r .)
    # Uncomment the varible below to test a failed healthcheck.
    # healthCheckResult='[{"healthCode":1,"httpCode":503,"description":"DBConnectionError"}]'
    if [[ $healthCheckResult == '[]' ]];then
        result="${1} returned healthy"
    else
        healthCheckDiscription=$(echo $healthCheckResult |jq -r '.[].description')
        result="${1} failed health check with code: ${healthCheckDiscription}"
    fi
    echo "${result}"
}

declare -a allresults
for node in ${jamftomcatnodes[@]}; do
    allresults+=( "$(Health_Check $node)" )
done

if ( echo "${allresults[@]}" | grep "failed" &> /dev/null ); then
   for i in "${allresults[@]}"; do
        echo "${i}"
    done | mail -s "Jamf Health Check Report" -r "JamfAPI@${deviceHostName}" -S smtp="${mailServer}:25" "${jamfAdminEmail[@]}"
    echo "Health checks failed email sent."
else
    echo "All nodes are healthy no email needed."
fi


