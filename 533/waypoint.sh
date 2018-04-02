#!/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
export DISPLAY=:0.0

# 100103  12:25 script to feed navit a list of destinations, one at the time
# and set the next waypoint as destination if you are near the current waypoint
# start it from cron every minute
# * * * * * if test -s /home/navit/scripts/waypoint.sh; then /home/navit/scripts/waypoint.sh; fi

LANG=POSIX # needed to prevent lat/lon strings beeing formatted into 1,234,567.89
SOURCE_FILE=~/trip.csv
WAYPOINTS=~/itinerary.csv
DEST_SET_FILE=/dev/shm/destination.set # a switch to see if the route was set already.

# cp "${SOURCE_FILE}" "${WAYPOINTS}" # do this by hand at the start of your trip
FIELD_SEPERATOR=';'
MAX_DELTA=100 # number to indicate how close you want to be to your current waypoint before taking the next waypoint as destination

# for example, with max_delta=10000 and the waypoint at lat=52.100 and long 5.100 then any location between 52.000,5.000 and 52.200,5.200
# would be "close" (100 * 100 = 10000)
#                                               52.100,5.100 and 52.100,5.100 
# with a max_delta of 1024 any location between 52.068,5.068 and 52.132,5.132 would be close ( 32 * 32 = 1024 ) -> aprox 10   Km radius at this latitude
# with a max_delta of  100 any location between 52.090,5.090 and 52.110,5.110 would be close ( 10 * 10 =  100 ) -> aprox  2   Km radius at this latitude
# with a max_delta of    9 any location between 52.097,5.097 and 52.103,5.103 would be close (  3 *  3 =    9 ) -> aprox  0.1 Km radius at this latitude
# if this script is run every minute and your max speed is 120 Km/h (=2 Km/min) you don't want to go below max_delta=100

if test -s "${WAYPOINTS}"; then
 GO_AHEAD=1
else
 exit 2
fi

if gpsbabel -V >/dev/null 2>&1; then
 GO_AHEAD=1
else
 echo 'gpsbabel not found in path, exiting'
 exit 3
fi

if gpspipe -V >/dev/null 2>&1; then
 GO_AHEAD=1
else
 echo 'gpspipe not found in path, exiting'
 exit 4
fi

OLD_IFS="${IFS}"
IFS=$'\n'

N=1
for WAYPOINT in `cat "${WAYPOINTS}" | tr ',' '.' `; do
 DEST_LAT[${N}]=`echo "${WAYPOINT}" | awk -F "${FIELD_SEPERATOR}" '{print $1}'`
 DEST_LON[${N}]=`echo "${WAYPOINT}" | awk -F "${FIELD_SEPERATOR}" '{print $2}'`
 N=$(( ${N} + 1 ))
done

IFS="${OLD_IFS}"

NUMBER_OF_WAYPOINTS="${N}"

# set the first waypoint as destination
N=1
DEST_LAT=${DEST_LAT[${N}]}
DEST_LON=${DEST_LON[${N}]}

# "${DEST_SET_FILE}" is a switch whether we have set our destination already
if test -f "${DEST_SET_FILE}"; then
 GO_AHEAD=1
else
 dbus-send --print-reply --dest=org.navit_project.navit /org/navit_project/navit/default_navit org.navit_project.navit.navit.set_destination string:"${DEST_LON} ${DEST_LAT}" string:"comment"
 touch "${DEST_SET_FILE}"
fi


get_current_lat_lon()
{

# read lines of nmea data from gpsd
NOW=`date +%s`
START_TIME="${NOW}"
STOP_TIME=$(( ${START_TIME} + 55 )) \
# if it takes more then 55 seconds to collect the nmea data, don't use it.
# if this script is started every minute, another run is on it's way or already running.

N=1
IFS=$'\n'
for NMEA_LINE in `gpspipe -r -n 100 2>/dev/null`; do
 NMEA_DATA[${N}]="${NMEA_LINE}"
 N=$(( N + 1 ))
done
IFS="${OLD_IFS}"

NOW=`date +%s`
if test "${NOW}" -gt "${STOP_TIME}"; then exit 5; fi

# convert the nmea data into lat/long data and cut out bad locations (90,0)
CURRENT_LAT=`\
echo "${NMEA_DATA[@]}" |\
gpsbabel -i nmea -f - -o gpx -F - |\
grep '<trkpt' |\
grep -v 90.000000000 |\
grep -v 0.000000000  |\
awk -F'"' '{print $2}' |\
tail -1`

CURRENT_LON=`\
echo "${NMEA_DATA[@]}" |\
gpsbabel -i nmea -f - -o gpx -F - |\
grep '<trkpt' |\
grep -v 90.000000000 |\
grep -v 0.000000000  |\
awk -F'"' '{print $4}' |\
tail -1`
}

get_current_lat_lon

################################################################################
## test block to set the current lat/lon manually                             ##
################################################################################
#CURRENT_LAT=38.773276
#CURRENT_LON=-120.814478
################################################################################

if test "${CURRENT_LAT}"; then
 ROUNDED_CURRENT_LAT=`printf "%'.3f" "${CURRENT_LAT}" | tr -d '.'`
else
 exit 6
fi

if test "${CURRENT_LON}"; then
 ROUNDED_CURRENT_LON=`printf "%'.3f" "${CURRENT_LON}" | tr -d '.'`
else
 exit 7
fi


if test "${DEST_LAT}"; then
 ROUNDED_DEST_LAT=`printf "%'.3f" "${DEST_LAT}" | tr -d '.'`
else
 exit 8
fi

if test "${DEST_LON}"; then
 ROUNDED_DEST_LON=`printf "%'.3f" "${DEST_LON}" | tr -d '.'`
else
 exit 9
fi

DIFF_LAT=$(( ${ROUNDED_CURRENT_LAT} - ${ROUNDED_DEST_LAT} ))
DIFF_LON=$(( ${ROUNDED_CURRENT_LON} - ${ROUNDED_DEST_LON} ))

# abs2 is a way to always have a positive delta (-12345 * -12345 = positive)
ABS2_DIFF_LAT=$(( ${DIFF_LAT} * ${DIFF_LAT} ))
ABS2_DIFF_LON=$(( ${DIFF_LON} * ${DIFF_LON} ))

if test "${ABS2_DIFF_LAT}" -lt "${MAX_DELTA}" -a "${ABS2_DIFF_LON}" -lt "${MAX_DELTA}"; then
 # we are close to our waypoint, so generate a new waypoints file, starting with the next waypoint (n=2)
 rm "${WAYPOINTS}"
 N=2
 while test "${N}" -lt "${NUMBER_OF_WAYPOINTS}"; do
  echo "${DEST_LAT[${N}]}"';'"${DEST_LON[${N}]}" >> "${WAYPOINTS}"
  N=$(( N + 1 ))
 done

 # set the next waypoint as destination
 N=2
 DEST_LAT=${DEST_LAT[${N}]}
 DEST_LON=${DEST_LON[${N}]}
 dbus-send --print-reply --dest=org.navit_project.navit /org/navit_project/navit/default_navit org.navit_project.navit.navit.set_destination string:"${DEST_LON} ${DEST_LAT}" string:"comment"
fi
