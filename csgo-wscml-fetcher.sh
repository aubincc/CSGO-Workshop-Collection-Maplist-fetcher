#!/bin/bash
##########################################################
##                                                      ##
##  CSGO Workshop Collection Maplist fetcher - by Mole  ##
##      Molobox.com - Supermole.eu - VeryGames.net      ##
##                                                      ##
## Version 1.2.1 - 2013-08-26                           ##
## http://scripts.mbx.so/csgo-wscml-fetcher/            ##
##                                                      ##
##########################################################
# Prerequisites:                                         #
# curl w3m grep sed cat cut                              #
##########################################################
# SCRIPT HISTORY
### v1.2.1 (2013-08-26)
# FIXED filling up files instead of recreating them
### v1.2 (2013-08-24)
# ADDED 'refreshall' to update maplist data into all collection files
### v1.1 (2013-08-23)
# Cleaned up and reorganised help reading of script
### v1.0.1 (2013-08-20)
# ADDED security with underscore in $WSCID_*.txt to prevent deleting collection ID
### v1.0 (2013-08-20)
# Just displays the list of maps on screen
##########################################################

##############################
#      TO BE MODIFIED        #
##############################

# MODIFY DESTINATION DIRECTORY OF FETCHED DATA
# If null, destination directory will be "script directory/workshop/" 
# Example:	DESTDIR=$(dirname $0)/workshop
# 		DESTDIR=$(pwd)/workshop
# 		DESTDIR=/home/user/workshop
# 		DESTDIR=~/workshop
#		DESTDIR=./workshop

DESTDIR=./workshop

##############################
#       DO NOT MODIFY        #
##############################

read DAY MONTH YEAR <<< $(date +'%d %m %Y')
WSCID=$1

function error_create_destdir
{
        if [ ! -d "$DESTDIR" ]; then
                echo "Destination directory could not be created"
                echo "Terminating..."
                exit 1
        fi
}

function check_usercanwrite
{
        if [ ! -w "$DESTDIR" ]; then
                echo "Cannot create any file into destination directory $DESTDIR"
                echo "Terminating..."
                exit 1
        fi
}

function check_usernotroot
{
	if [ $UID -eq 0 ]; then
		echo "It is NOT recommended to use this script as ROOT!"
		read -p "Are you sure you want to continue? (Y/N)" -n 1 -r
		echo
		if [[ ! $REPLY =~ ^[Yy]$ ]]; then
			echo "Terminating..."
			exit 1
		fi
	fi
}

#
#
#

check_usernotroot
[[ -z "$DESTDIR" ]] && DESTDIR=$(dirname $0)/workshop
[[ ! -d "$DESTDIR" ]] && mkdir -p $DESTDIR; error_create_destdir
check_usercanwrite

# list the collections we have and generate a list file
ls $DESTDIR > $DESTDIR/.list

# 
# 
# 

function show_scriptusage
{
	echo "	$0 usage"
	echo "		Displays this message."
	echo "	$0 refresh (not active yet)"
	echo "		Be careful with this one, it can take some time."
	echo "		It will get the list of all previously searched"
	echo "		collections, and it will retrieve them again to"
	echo "		refresh them."
	echo "	$0 <Collection_ID>"
	echo "		If collection ID is valid, the script will fetch"
	echo "		the collection name and maps to generate a clean"
	echo "		list in $DESTDIR."
	echo "		You can set up a different destination directory"
	echo "		by editing the line DESTDIR inside the script."
	echo "		Example: $0 125624862"
	echo ""
}

function getparse_html
{
	curl http://steamcommunity.com/sharedfiles/filedetails/?id=$WSCID -s | w3m -dump > $DESTDIR/.$WSCID.html
	TEMPHTML=$DESTDIR/.$WSCID.html


	WSCTITLE=$(sed -n 's/<title>\(.*\)<\/title>/\1/Ip' $TEMPHTML)
	WSCERROR=$(echo "Steam Community :: Error")
        	case "$WSCTITLE" in
                	$WSCERROR)      echo "Steam Community :: Error" && rm $DESTDIR/.$WSCID.html && exit 0 ;;
                	*)      echo "$WSCTITLE" ;;
        	esac
	cat $TEMPHTML | grep '<div class="workshopItemTitle' | grep 'filedetails' > $DESTDIR/.$WSCIDmaps.html
	wscmaps=$DESTDIR/.$WSCIDmaps.html

}

function remove_olddata
{
	# [[ -f $DESTDIR/$WSCID*.txt ]] && rm -f $DESTDIR/$WSCID*.txt
	rm -f $DESTDIR/$WSCID*
	# echo "Map ID	  :: Map name" > $DESTDIR/$WSCFILENAME.txt  (cannot occur before 'showstore_newdata' as is)
	# truncate -s 0 $DESTDIR/$WSCID*.txt
	# echo > $DESTDIR/$WSCID_*.txt
}

function showstore_newdata
{
	# move parameters up a bit to allow input of "Map ID      :: Map name" at top of file
	# echo > $DESTDIR/$WSCFILENAME.txt
	# echo "Map ID      :: Map name" > $DESTDIR/$WSCFILENAME.txt
	while read line
	do
	# extract the map ID
		WSMID=$(echo $line | sed "s/\"></\n/g" | sed 's/.*id=//g;$d')
	# extract the map name
		WSMNAME=$(echo $line | sed "s/<\/div/\n/g" | sed 's/.*workshopItemTitle\">//g;$d')
	# display the map ID and the map name if not 
		[[ "$WSCID" -ne refreshall ]] && echo $WSMID :: $WSMNAME
	# clean the collection title
		WSCCLEANTITLE=$(echo "$WSCTITLE" | sed 's/&quot;/\&/g' | sed 's/ /_/g' | sed -r 's/[^a-zA-Z0-9\-]+/_/g')
		WSCNOANDTITLE=$(echo "$WSCTITLE" | sed 's/&quot;/\&/g')
	# generate the txt filename where all this is going to be stored
		WSCFILENAME=$(echo "$WSCID"_-"$WSCCLEANTITLE")
	# store every map ID and map name in the txt file
		echo "$WSMID :: $WSMNAME" >> $DESTDIR/$WSCFILENAME.txt
	done <$wscmaps
}

function clean_html {
	rm $DESTDIR/.*.html
}

function refresh_all {
	while read line
	do
	# extract every collection ID from $DESTDIR/.list and refresh all data in collection files
		WSCID=$(echo $line | cut -c1-9)
		# echo $WSCID
		getparse_html
		remove_olddata
		showstore_newdata
		clean_html
		echo "-"
		sleep 2
	done <$DESTDIR/.list
}

#
#
#

case $1 in
	"usage")
		# show script information
		show_scriptusage
		exit 1
	;;
	"refreshall")
		# refreshes data of all collections already added || 
		# list of files in "$DESTDIR/.list" 
		refresh_all
		exit 1
	;;
	*[!0-9]*)
		# when the given parameter is not a valid ID
		echo "Obviously, this only works with valid Steam Workshop ID !!!!!!!!!!!!"
		echo "Terminating..."
		exit 1
	;;
	*[0-9]*)
		# OK
		getparse_html
		remove_olddata
		showstore_newdata
		clean_html
		echo ""
		echo "End of maplist for Collection $WSCID :: $WSCNOANDTITLE"
		exit 0
	;;
	*)
		# any empty or nonexistent parameter
		echo "No valid option was specified..."
		echo "Script usage:"
		show_scriptusage
		exit 1
	;;
esac

