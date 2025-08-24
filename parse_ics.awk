# parse ICS file
# for each event which is between now and CHECK_AHEAD_TIME hours in the future:
#   print JSON representation of event
# usage:
#   cat calendar.ics | awk -v CHECK_AHEAD_TIME="20" -F":" -f parse_ics.awk
BEGIN {
  # default val
  if (CHECK_AHEAD_TIME == "")
    CHECK_AHEAD_TIME = 20
  now_ts=systime()
  printf "["
}
{sub("\r$", "")}
$1=="UID"{UID=$2}
$1=="DTSTART"{DTSTART=$2}
$1=="SEQUENCE"{SEQUENCE=$2}
$1=="STATUS"{STATUS=$2}
$1=="DTEND"{DTEND=$2}
$1=="SUMMARY"{SUMMARY=$2}
$1=="DTSTAMP"{DTSTAMP=$2}
$1=="CREATED"{CREATED=$2}
$1=="LAST-MODIFIED"{LASTMODIFIED=$2}
$1=="END" && $2=="VEVENT"{
	# parsing date format to timestamp
  datespec_fmt = "\\1 \\2 \\3 \\4 \\5 \\6"
  start_ts = mktime(gensub(/(....)(..)(..)T(..)(..)(..)Z/, datespec_fmt, 1, DTSTART))
  end_ts = mktime(gensub(/(....)(..)(..)T(..)(..)(..)Z/, datespec_fmt, 1, DTEND))
  # output
  # check event not in past and N hours in future
  if (((start_ts - now_ts) > 0) && ((start_ts - now_ts) < (60 * 60 * CHECK_AHEAD_TIME))) {
  	printf "%s", fs
  	printf "{"
		printf "\"SUMMARY\": \"%s\",", SUMMARY
		printf "\"START_TS\": %i,", start_ts
		printf "\"END_TS\": %s", end_ts
		printf "}"
	  #printf "  %s – %s\n", strftime("%a %b %d @ %H:%M", start_ts), strftime("%H:%M", end_ts)
	  #printf "  timestamp: START %s END %s\n", start_ts, end_ts
	  #printf "  Discord timestamp: <t:%s:F>\n", start_ts
	  fs=","
  }
}
END {
  printf "]"
}

