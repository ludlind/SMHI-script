#!/bin/bash

# CONFIG

smhi_entry_point="https://opendata-download-metfcst.smhi.se"
category="pmp3g"
version="2"
geotype="point"
longitude="16"
latitude="58"

cache_path="weatherCache/data.json"

# FUNCTIONS

# Download recent forecasts
function update_cache() {
	echo 'Updating weather cache'
	wget "$smhi_entry_point/api/category/$category/version/$version/geotype/$geotype/lon/$longitude/lat/$latitude/data.json" -O $cache_path
}

# Retrieve index of time series closest to a given date/time.
# --  $(date +%s) ska bytas ut
function get_index() {
	echo $1
	for dt in $(jq '.timeSeries[].validTime' $cache_path | tr -d \")
	do
		echo $(( $(date -d $dt +%s) - $(date -d $1 +%s) ))
	done | awk 'BEGIN{cls=-1;line=NR} {if($1*$1<cls*cls || cls<0 || $1<0) {cls=$1;line=NR}} END{printf line}'
}

# Get one date by index or get a list of dates from a start to an end index.
function get_date() {
	if (($# == 2)); then
		printf "$(jq ".timeSeries[$1:$2][].validTime" $cache_path | tr -d \")\n"
	else
		printf "$(jq ".timeSeries[$1].validTime" $cache_path | tr -d \")\n"
	fi
}

function get_parameter() {
	if (($# == 3)); then
		jq ".timeSeries[$2:$3][].parameters[] | select(.name == \"$1\") | .values[0]" $cache_path
	else
		jq ".timeSeries[$2].parameters[] | select(.name == \"$1\") | .values[0]" $cache_path
	fi

}

function usage() {
	echo "Usage: $(basename $0) [-aehstuw]" 2>&1
	echo 'Locally stored weather forecast from SMHI.'
	echo '   -a		Print all parameters'
	echo '   -e STOP DATE	Specify the stop date'
	echo '   -d		List date and time of available forecasts'
	echo '   -h             Print help'
	echo '   -s START DATE	Specify the start date'
	echo '   -t		Print temperature'
	echo '   -u		Update weather cache'
	echo '   -w		Print wind information'
	exit $1
}

# RUN

optstring=":aehstuw"

t_flag=false
wd_flag=false
ws_flag=false

start_ind=$(date +%s)
stop_ind=0

while getopts $optstring arg; do
	case $arg in
	  a)
		t_flag=true
		wd_flag=true
		ws_flag=true
		;;
	  e)
		stop_ind=$(get_index $OPTARG)
		echo $stop_ind
		;;
	  d)
		echo $(get_date)
		;;	
	  h)
		usage 0
		;;
	  s)
		start_ind=$(get_index $OPTARG)
		echo $start_ind
		;;
	  t)
		t_flag=true
		;;
	  u)
		update_cache
		;;
	  w)
		wd_flag=true
		ws_flag=true
		;;
	  ?)
		;;
	esac
done


