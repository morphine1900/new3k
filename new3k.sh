#!/bin/sh

INPUTFILE="new3k.txt"
LINE=""
RANDOMLOOP=0
LISTNUM=0
UNITNUM=0
FILTER=0

show ()
{
	WORD=`echo $LINE | awk '{print $2}'`
	RANK=`echo $LINE | awk '{print $7}'`
#	[ "$FILTER" -eq "1" ] && [ "$RANK" = "Y" ] && return

	echo "\n$WORD: last test: $RANK\n"
	read TMP
	
	STARTLINE=`echo $LINE | awk '{print $5}'`
	ENDLINE=`echo $LINE | awk '{print $6}'`
	sed -n "${STARTLINE},${ENDLINE}p" $INPUTFILE
	
	read -p "remember now? " TMP
	if [ "$TMP" = "y" ] || [ "$TMP" = "Y" ]; then
		 RANK="Y"
	elif [ "$TMP" = "n" ] || [ "$TMP" = "N" ]; then
		 RANK="N"
	fi

	LINENUM=`echo $LINE | awk '{print $1}'`
	LINE=`echo "$LINE" | awk -v rank="$RANK" 'BEGIN{OFS="\t"} {$7=rank;print $0}'`
	
	cat $INPUTFILE.idx | sed "${LINENUM}s/.*/${LINE}/" > $INPUTFILE.new
	mv $INPUTFILE.new $INPUTFILE.idx
}

reverse ()
{
	echo "reversing $INPUTFILE.idx"
	cat /dev/null > `echo $INPUTFILE.rev`
	while read LINE
	do
		LINENUM=`echo $LINE | awk '{print $1}'`
		WORD=`echo $LINE | awk '{print $2}'`
		REVWORD=""
		WORDLEN=`expr length "$WORD"`
		while [ "$WORDLEN" -gt "0" ]
		do
			CHAR=`expr substr "$WORD" $WORDLEN 1`
			REVWORD="$REVWORD$CHAR"
			WORDLEN=`expr $WORDLEN - 1`
		done
		echo "$REVWORD\t$LINENUM" >> $INPUTFILE.tmp
	done < $INPUTFILE.idx
	
	REVNUM=0
	sort $INPUTFILE.tmp | while read LINE
	do
		REVNUM=`expr $REVNUM + 1`
		LINENUM=`echo $LINE | awk '{print $2}'`
		WORD=`echo $LINE | awk '{print $1}'`	
		REVWORD=""
		WORDLEN=`expr length "$WORD"`
		while [ "$WORDLEN" -gt "0" ]
		do
			CHAR=`expr substr "$WORD" $WORDLEN 1`
			REVWORD="$REVWORD$CHAR"
			WORDLEN=`expr $WORDLEN - 1`
		done
		echo "$REVWORD\t$LINENUM" >> $INPUTFILE.rev
	done
	rm $INPUTFILE.tmp
}

parse ()
{
	echo "parsing $INPUTFILE"
	cat /dev/null > $INPUTFILE.idx
	LINENUM=0
	LISTNUM=1
	IDXNUM=1
	while read LINE
	do
		LINENUM=`expr $LINENUM + 1`
		echo "$LINE" | grep -q "List $LISTNUM" || continue

		UNITNUM=1
		while read LINE
		do
			LINENUM=`expr $LINENUM + 1`
			echo "$LINE" | grep -q "Unit $UNITNUM" || continue
			
			WORDNUM=1
			while read LINE
			do
				LINENUM=`expr $LINENUM + 1`
				echo "$LINE" | grep -q "\[*\]" || continue
				WORD=`echo "$LINE" | awk '{print $1}'`
				STARTLINE=$LINENUM

				while read LINE
				do
					LINENUM=`expr $LINENUM + 1`
					echo $LINE | grep -q -E "^$|^ $" || continue
					read LINE
					LINENUM=`expr $LINENUM + 1`
					if echo $LINE | grep -q -E "^$|^ $"; then
						echo "$IDXNUM\t$WORD\t$LISTNUM\t$UNITNUM\t$STARTLINE\t$LINENUM\tN" >> $INPUTFILE.idx
						IDXNUM=`expr $IDXNUM + 1`
						break
					fi
				done
				WORDNUM=`expr $WORDNUM + 1`
				[ "$WORDNUM" -gt "10" ] && break
				[ "$LISTNUM" -eq "27" ] && [ "$UNITNUM" -eq "10" ] && [ "$WORDNUM" -gt "7" ] && break
			done
			
			UNITNUM=`expr $UNITNUM + 1`
			[ "$UNITNUM" -gt "10" ] && break
			[ "$LISTNUM" -eq "31" ] && [ "$UNITNUM" -gt "8" ] && break
		done
		LISTNUM=`expr $LISTNUM + 1`
	done < $INPUTFILE
}

usage ()
{
	echo "$0: <new3k> helper"
	echo "usage: sh new3k.sh [options], where options are:"
	echo "\t-p:\tparse new3k.txt, the source words database."
	echo "\t\tthis will generate the index file and reverse index file"
	echo "\t-f:\tfilter remembered words."
	echo "\t-r:\trandom modes:"
	echo "\t\tpop words by random selection, 50 times by default."
	echo "\t-l[-u]:\tlist number [start from unit x]."
	echo "\t-w:\tfind one word."
}

if [ $# -lt 1 ]; then
	usage
else
while getopts fl:p:r:s:u:w: OPTION
do
	case $OPTION in
	p)
		[ -r "$OPTARG" ] && INPUTFILE=$OPTARG
		parse
		reverse
		exit 0
		;;
	f)
		echo "open filter!"
		FILTER=1
		;;
	r)
		RANDOMLOOP=50
		[ "$OPTARG" != "" ] && RANDOMLOOP=$OPTARG
		echo "random loop: $RANDOMLOOP"
		;;
	l)
		if [ "$OPTARG" = "" ]; then
			echo "please input the list num."
			exit 0
		fi

		LISTNUM=$OPTARG
		echo "list num: $LISTNUM"
		;;
	u)
		if [ "$LISTNUM" = "" ]; then
			echo "in which list?"
			exit 0
		fi
		UNITNUM=$OPTARG
		echo "from unit: $UNITNUM"
		;;
	w)
		if [ "$2" = "" ]; then
			echo "please input a word for searching."
			exit 0
		fi
		LINE=`grep $2 $INPUTFILE.idx`
		if [ "$LINE" = "" ]; then
			echo "$2 not found."
			exit 0
		fi
		show
		exit 0
		;;
	\?)
		usage
		;;
	esac
done
fi

if [ "$LISTNUM" -gt "0" ]; then
	awk -v listnum="$LISTNUM" '{if($3==listnum) print $0}' $INPUTFILE.idx > $INPUTFILE.tmp
	
	if [ "$UNITNUM" -gt "0" ]; then
		awk -v unitnum="$UNITNUM" '{if($4>=unitnum) print $0}' $INPUTFILE.tmp > $INPUTFILE.tmp2
		mv $INPUTFILE.tmp2 $INPUTFILE.tmp
	fi

	if [ "$FILTER" -eq "1" ]; then
		awk '{if($7=="N") print $0}' $INPUTFILE.tmp > $INPUTFILE.tmp2
		mv $INPUTFILE.tmp2 $INPUTFILE.tmp
	fi

	if [ $RANDOMLOOP -gt "0" ]; then
		FILELINES=`cat $INPUTFILE.tmp | wc -l`		
		while [ "$RANDOMLOOP" -gt "0" ]
		do
			BIG=`date +%S%N`
			LINE=`expr $BIG % $FILELINES + 1`
			LINE=`cat $INPUTFILE.tmp | sed -n "${LINE}p"`
			show
			RANDOMLOOP=`expr $RANDOMLOOP - 1`
		done
	else
		LISTNUM=`cat $INPUTFILE.tmp | wc -l`
		TOREAD=1
		while [ "$TOREAD" -le "$LISTNUM" ]
		do
			LINE=`sed -n "${TOREAD}p" $INPUTFILE.tmp`
			show
			TOREAD=`expr $TOREAD + 1`
		done
	fi
	
	rm $INPUTFILE.tmp

elif [ $RANDOMLOOP -gt "0" ]; then
	if [ "$FILTER" -eq "1" ]; then
		awk '{if($7=="N") print $0}' $INPUTFILE.idx > tmp2
	else
		cp $INPUTFILE.idx tmp2
	fi

	FILELINES=`cat tmp2 | wc -l`		
	while [ "$RANDOMLOOP" -gt "0" ]
	do
		BIG=`date +%S%N`
		LINE=`expr $BIG % $FILELINES + 1`
		LINE=`cat tmp2 | sed -n "${LINE}p"`
		show
		RANDOMLOOP=`expr $RANDOMLOOP - 1`
	done
	
	rm tmp2
fi
