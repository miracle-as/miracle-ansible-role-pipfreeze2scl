#!/usr/bin/env bash


SPECFILE=$1
ADDON=$2
INSERTAFTER=$3
if [[ $3 == "" ]];
then
	echo "usage: rtfm"
	exit 543
fi

INSTALLLINE=""

PART1="/tmp/specfilepart1"
PART2="/tmp/specfilepart2"
if [[ -f $SPECFILE && -f $ADDON ]];
then
	INSTALLLINE=`grep "$INSERTAFTER" $SPECFILE`
	grep -P "$INSERTAFTER" $SPECFILE -B100000 |grep -v "^%install" > $PART1
	grep -P "$INSERTAFTER" $SPECFILE -A100000 |grep -v "^%install" > $PART2
fi


cat $PART1
echo $INSTALLLINE
cat $ADDON
cat $PART2

