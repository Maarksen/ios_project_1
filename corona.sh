#!/bin/sh

export LC_NUMERIC=en_US.UTF-8
export POSIXLY_CORRECT=yes


print_help(){		#function that prints help if called
	echo "USAGE"
	echo "	corona [-h--help]"
	echo "	corona [-h] [FILTERS] [COMMAND] [LOG [LOG2[...]]]"
	echo
	echo "OPTIONS"
	echo "	Commands"		#list of commands
	echo "		infected	counts all infected people"	
	echo "		merge		merges various lists into one, respecting the order"
	echo "		gender		displays all infected people of given gender"
	echo "		age		displays the statistics of infected people sorted by age"
	echo "		daily		displays the statistics of infected people for given days"
	echo "		monthly		displays the statistics of infected people for given months"
	echo "		yearly		displays the statistics of infected people for given years"
	echo "		countires	displays the statistics of infected people for individual countires"
	echo "		districts	displays the statistics of infected people for individual districts"
	echo "		regions		displats the statistics of infected people for individual regions"
	echo
	echo "	Filters"		#list of filters
	echo "		-a DATETIME			only logs taken after this date"
	echo "		-b DATETIME			only logs taken before this date"
	echo "		-g GENDER			displays only logs of of one gender"
	echo "		-s [WIDTH]			sets the width of histogram"
	echo "		-d DISTRICT_FILE[optional]	displays the code of a district"
	echo "		-r REGIONS_FILE[optional]	displays the code of a region"
	echo "		-h HELP				displays help[all commands and their use]"

}

error_message(){
	echo "error"
}

COMMAND=""			#variable to store command
AFTER_DATE="0000-01-01"		#variable to store after what date we display logs
BEFORE_DATE="9999-12-31"	#variable to store before what date we display logs
GENDER="N"			#variable to store what gender do we display on the logs
WIDTH="0"			#variable that stores the width of histogram
FILTERED=""

#parse_argumets(){		#function to parse the possible arguments
	
	while [ "$#" -gt 0 ]; do
	       case "$1" in
		infected | merge | gender | age | daily | monthly | yearly | countries | districts | regions)
			COMMAND="$1"
			shift
			;;
	  	-a)
			AFTER_DATE="$2"
			shift		
			shift
			;;
		-b)
			BEFORE_DATE="$2"
			shift
			shift
			;;
		-g)
			GENDER="$2"
			shift
			shift
			;;
		-s)
			if [[ "$2" -gt 0 ]]; then
				WIDTH="$2"
				shift
				shift
			else
				error_message
			fi
			;;
		-h)
			print_help
			exit 0
			shift
			;;
		 *)
			 if [[ "$1" == *bz2 ]]; then
				 FILE_BZ2="$1 $FILE_BZ2"
			 elif [[ "$1" == *gz ]]; then 
				FILE_GZ="$1 $FILE_GZ"
			 else
				FILE="$1 $FILE"
			 fi
			 shift
			 ;;
	esac
done
#}

LIST=$(cat $FILE)

FILTERED=$(echo "$LIST" | awk -F "," \
    -v BEFORE_DATE="$BEFORE_DATE" -v AFTER_DATE="$AFTER_DATE" -v GENDER="$GENDER" \
    '{ if ((GENDER == "N" || GENDER == $4) && (BEFORE_DATE >= $2 && $2 >= AFTER_DATE)) { print $0 }
    }')
        

echo "$FILTERED"
