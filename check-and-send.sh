#!/bin/bash
# check football fixtures list for any fixtures in the near future
# if found, send a Discord webhook for each
# usage:
#   ./check-and-send.sh
#   ./check-and-send.sh 700 # for testing, set "lookahead time" to be large
# probably create a cron job like:
#   0 4 * * * (cd /usr/alifeee/fixtures; ./check-and-send.sh >> cron.log 2>&1)
# to-do
# - change format of Discord embed (https://birdie0.github.io/discord-webhooks-guide/structure/embeds.html)
# - use bit-field to not trigger notifications (https://discord.com:8443/developers/docs/resources/webhook#execute-webhook-jsonform-params)
# - switch which channel is sent to based on day of match (Mon/Thu/Sat)

CHECK_AHEAD_TIME="${1:-20}" # hrs

date >> /dev/stderr

# load secrets
source .env
if [[ -z "${WEBHOOK_URL}" ]]; then
  echo "no WEBHOOK_URL set, quitting (create a .env file)" >> /dev/stderr
  exit 1
fi

# get fixtures
echo "get fixtures…" >> /dev/stderr
icsdata=$(
  curl -s --fail \
    "https://fixtur.es/en/team/sheffield-united-fc/home"
)
if [[ "${?}" != 0 ]]; then
  echo "something went wrong with CURL !" >> /dev/stderr
  exit 1
fi

# get all events within the next TIME
echo "check for any within time (next ${CHECK_AHEAD_TIME} hrs)…" > /dev/stderr
games=$(
  cat fixtures.ics \
    | awk -v CHECK_AHEAD_TIME="${CHECK_AHEAD_TIME}" \
      -F":" -f parse_ics.awk | jq -c
)

ngames=$(
  echo "${games}" | jq 'length'
)
echo "got ${ngames} games: ${games}" >> /dev/stderr
if [[ "${ngames}" == 0 ]]; then
  echo "got no games… quitting" >> /dev/stderr
  exit 0
fi

echo "for each game, send a webhook" >> /dev/stderr
while read -r game; do
  data=$(
    echo "${game}" | jq -c '
		{
	    avatar_url: "https://www.sufc.co.uk/logo.png",
		  embeds: [{
	  	  title: "Incoming Football Game at Bramall Lane!",
	  	  color: "14879511",
	  	  url: "https://fixtur.es/en/team/sheffield-united-fc/home",
		    "fields": [
		      {
		        "name": (
		          "Time — <t:" + (.START_TS|tostring) + ":R>"
	          ),
		        "value": (
		        	"<t:" + (.START_TS|tostring) + ":F> for "
		          + (((.END_TS - .START_TS)/3600)|tostring) + " hours"
	          )
		      },
		      {
		        "name": "Fixture",
		        "value": .SUMMARY
		      }
	      ]
		  }]
	  }'
  )
  
	# send message
	echo "send msg! data:" >> /dev/stderr
	echo "${data}" >> /dev/stderr
	res=$(
		curl -s --fail -H "Content-Type:application/json" \
		-w "%{http_code}" \
		"${WEBHOOK_URL}" -d "${data}"
	)
	if [[ "${?}" != 0 ]] || [[ "${res}" != 204 ]]; then
		echo "something went wrong trying to send webhook!" > /dev/stderr
		exit 1
	fi
done <<< $(echo "${games}" | jq -c '.[]')

echo "done!" >> /dev/stderr

