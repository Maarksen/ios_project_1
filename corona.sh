#!/bin/bash

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

COMMAND="merge"			#variable to store command
AFTER_DATE="0000-01-01"		#variable to store after what date we display logs
BEFORE_DATE="9999-12-31"	#variable to store before what date we display logs
GENDER="N"			#variable to store what gender do we display on the logs
WIDTH=0				#variable that stores the width of histogram
MAX=0
FILTERED=""
graph=false

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
		if ! [[ "$2" =~ ^[0-9]+$ ]]; then
			graph=true
			WIDTH=0
			shift
		else
			graph=true
			WIDTH="$2"
			shift
			shift
		fi
		;;
	-h)
		print_help
		exit 0
		shift
		;;
	 *)
		 if [[ "$1" == *.bz2 ]]; then
            		LIST="$(bzip2 -c -k -d $1) $LIST"
            		shift
        	elif [[ "$1" == *.gz ]]; then  
           		LIST="$(gzip -c -k -d $1) $LIST"
            		shift
        	else 
            		LIST="$(cat $1) $LIST"
            		shift
		fi
		;;
	esac
done


FILTERED=$(echo "$LIST" | awk -F "," \
    -v BEFORE_DATE="$BEFORE_DATE" -v AFTER_DATE="$AFTER_DATE" -v GENDER="$GENDER" \
    '{ if ((GENDER == "N" || GENDER == $4) && (BEFORE_DATE > $2 && $2 > AFTER_DATE)) { print $0 }
    }')


#echo "$FILTERED"

if [[ $COMMAND == "infected" ]]; then
	output=$(echo "$FILTERED" | awk 'END{print NR}')
	echo "$output"
fi

if [[ $COMMAND == "merge" ]]; then
	echo "id,datum,vek,pohlavi,kraj_nuts_kod,okres_lau_kod,nakaza_v_zahranici,nakaza_zeme_csu_kod,reportovano_khs"
       	echo "$FILTERED"
fi

if [[ $COMMAND == "gender" ]]; then
	if [[ $graph == "false" ]]; then
		output=$(echo "$FILTERED" | awk -F "," '$4 == "M" {men++} END{print "M:",men "\nW:", (NR-men)}')
		echo "$output"
	else
		output=$(echo "$FILTERED" | awk -F "," -v WIDTH="$WIDTH" -v MAX="$MAX" '$4 == "M" {men++} END{
		women=NR-men
		if (men > women){
			MAX=men
		}
		else{
			MAX=women
		}
		if(WIDTH == 0){
			printf("M: ")
			for (j = 0; j < men / 100000; j++){
				printf("#")
			}
			printf("\n")
			printf("Z: ")
			for (j = 0; j < women / 100000; j++){
				printf("#")
			}
			printf("\n")
		}
		else{
			printf("M: ")
			for (j = 0; j < (WIDTH/MAX) * men; j++){
				printf("#")
			}
			printf("\n")
			printf("Z: ")
			for (j = 0; j < (WIDTH/MAX) * women; j++){
				printf("#")
			}
			printf("\n")
		}
	} ' | sort)
		echo "$output"
	fi
fi

if [[ $COMMAND == "age"  ]]; then
	if [[ $graph == "true" ]]; then
		output=$(echo "$FILTERED" | awk -F "," -v WIDTH="$WIDTH" -v MAX="$MAX" \
		'{if(0 <= $3 && $3 <= 5){
			age5++
		}
		else if(6 <= $3 && $3 <= 15){
			age15++
		}
		else if(16 <= $3 && $3 <= 25){
			age25++
		}
		else if(26 <= $3 && $3 <= 35){
			age35++
		}
		else if(36 <= $3 && $3 <= 45){
			age45++
		}
		else if(46 <= $3 && $3 <= 55){
			age55++
		}
		else if(56 <= $3 && $3 <= 65){
			age65++
		}
		else if(66 <= $3 && $3 <= 75){
			age75++
		}
		else if(76 <= $3 && $3 <= 85){
			age85++
		}
		else if(86 <= $3 && $3 <= 95){
			age95++
		}
		else if(96 <= $3 && $3 <= 105){
			age105++
		}
		else if($3 > 105){
			age105plus++
		}}
		END{
		age[5]=age5
		age[15]=age15
		age[25]=age25
		age[35]=age35
		age[45]=age45
		age[55]=age55
		age[65]=age65
		age[75]=age75
		age[85]=age85
		age[95]=age95
		age[105]=age105
		age[106]=age105plus
		if( WIDTH == 0){
			printf("0-5   : ")
			for (j = 0; j < int(age[5] / 10000); j++){
				printf("#")
			}
			printf("\n")
			printf("6-15  : ")
			for (j = 0; j < int(age[15] / 10000); j++){
				printf("#")
			}
			printf("\n")
			printf("16-25 : ")
			for (j = 0; j < int(age[25] / 10000); j++){
				printf("#")
			}
			printf("\n")
			printf("26-35 : ")
			for (j = 0; j < int(age[35] / 10000); j++){
				printf("#")
			}
			printf("\n")
			printf("36-45 : ")
			for (j = 0; j < int(age[45] / 10000); j++){
				printf("#")
			}
			printf("\n")
			printf("46-55 : ")
			for (j = 0; j < int(age[55] / 10000); j++){
				printf("#")
			}
			printf("\n")
			printf("56-65 : ")
			for (j = 0; j < int(age[65] / 10000); j++){
				printf("#")
			}
			printf("\n")
			printf("66-75 : ")
			for (j = 0; j < int(age[75] / 10000); j++){
				printf("#")
			}
			printf("\n")
			printf("76-85 : ")
			for (j = 0; j < int(age[85] / 10000); j++){
				printf("#")
			}
			printf("\n")
			printf("86-95 : ")
			for (j = 0; j < int(age[95] / 10000); j++){
				printf("#")
			}
			printf("\n")
			printf("96-105: ")
			for (j = 0; j < int(age[105] / 10000); j++){
				printf("#")
			}
			printf("\n")
			printf(">105  : ")
			for (j = 0; j < int(age[106] / 10000); j++){
				printf("#")
			}
			printf("\n")
	
		}
		else{
			for (i in age){
				if (age[i] > MAX){
				MAX  = age[i] 	
				}
			}
			printf("0-5   : ")
			for (j = 0; j < int((WIDTH/MAX) * age[5]); j++){
				printf("#")
			}
			printf("\n")
			printf("6-15  : ")
			for (j = 0; j < int((WIDTH/MAX) * age[15]); j++){
				printf("#")
			}
			printf("\n")
			printf("16-25 : ")
			for (j = 0; j < int((WIDTH/MAX) * age[25]); j++){
				printf("#")
			}
			printf("\n")
			printf("26-35 : ")
			for (j = 0; j < int((WIDTH/MAX) * age[35]); j++){
				printf("#")
			}
			printf("\n")
			printf("36-45 : ")
			for (j = 0; j < int((WIDTH/MAX) * age[45]); j++){
				printf("#")
			}
			printf("\n")
			printf("46-55 : ")
			for (j = 0; j < int((WIDTH/MAX) * age[55]); j++){
				printf("#")
			}
			printf("\n")
			printf("56-65 : ")
			for (j = 0; j < int((WIDTH/MAX) * age[65]); j++){
				printf("#")
			}
			printf("\n")
			printf("66-75 : ")
			for (j = 0; j < int((WIDTH/MAX) * age[75]); j++){
				printf("#")
			}
			printf("\n")
			printf("76-85 : ")
			for (j = 0; j < int((WIDTH/MAX) * age[85]); j++){
				printf("#")
			}
			printf("\n")
			printf("86-95 : ")
			for (j = 0; j < int((WIDTH/MAX) * age[95]); j++){
				printf("#")
			}
			printf("\n")
			printf("96-105: ")
			for (j = 0; j < int((WIDTH/MAX) * age[105]); j++){
				printf("#")
			}
			printf("\n")
			printf(">105  : ")
			for (j = 0; j < int((WIDTH/MAX) * age[106]); j++){
				printf("#")
			}
			printf("\n")
		}}')
		echo "$output"
	else
		output=$(echo "$FILTERED" | awk -F "," \
		'{if(0 <= $3 && $3 <= 5){
			age5++
		}
		else if(6 <= $3 && $3 <= 15){
			age15++
		}
		else if(16 <= $3 && $3 <= 25){
			age25++
		}
		else if(26 <= $3 && $3 <= 35){
			age35++
		}
		else if(36 <= $3 && $3 <= 45){
			age45++
		}
		else if(46 <= $3 && $3 <= 55){
			age55++
		}
		else if(56 <= $3 && $3 <= 65){
			age65++
		}
		else if(66 <= $3 && $3 <= 75){
			age75++
		}
		else if(76 <= $3 && $3 <= 85){
			age85++
		}
		else if(86 <= $3 && $3 <= 95){
			age95++
		}
		else if(96 <= $3 && $3 <= 105){
			age105++
		}
		else if($3 > 105){
			age105plus++
		}}
		END{
	       	printf("0-5   :%d\n", age5)
 		 printf("6-15  :%d\n", age15)
   		 printf("16-25 :%d\n", age25)
   		 printf("26-35 :%d\n", age35)
   		 printf("36-45 :%d\n", age45)
   		 printf("46-55 :%d\n", age55)
   		 printf("56-65 :%d\n", age65)
   		 printf("66-75 :%d\n", age75)
   		 printf("76-85 :%d\n", age85)
   		 printf("86-95 :%d\n", age95)
   		 printf("96-105:%d\n", age105)
   		 printf(">105  :%d\n", age105plus)
		}')
		echo "$output"
	fi

fi

if [[ $COMMAND == "daily" ]]; then
	if [[ $graph == "false" ]]; then
		output=$(echo "$FILTERED" | awk -F "," '{a[$2]+=1} END{for (i in a)print i": "a[i];}' | sort)
		echo "$output"
	else
		output=$(echo "$FILTERED" | awk -F "," -v WIDTH="$WIDTH" -v MAX="$MAX" '{a[$2]+=1} END{
		for (i in a){
			if (a[i] > MAX){
				MAX  = a[i] 	
			}
		}
		if (WIDTH == 0){
			for(i in a){
				printf("%s: ", i)
				for (j = 0; j < int(a[i] / 500); j++){
					printf("#")
				}
				printf("\n")
			}
		}
		else{
			for(i in a){
				printf("%s: ", i)
				for (j = 0; j < int((WIDTH/MAX) * a[i]); j++){
					printf("#")
				}
				printf("\n")
			}
		}	
	} ' | sort)
		echo "$output"
	fi

fi

if [[ $COMMAND == "monthly" ]]; then
	if [[ $graph == "false" ]]; then
		output=$(echo "$FILTERED" | awk -F "," '{a[substr($2,1,7)]+=1} END{for (i in a)print i": "a[i];}' | sort)
		echo "$output"
	else
		output=$(echo "$FILTERED" | awk -F "," -v WIDTH="$WIDTH" -v MAX="$MAX" '{a[substr($2,1,7)]+=1} END{
		for (i in a){
			if (a[i] > MAX){
				MAX  = a[i] 	
			}
		}
		if (WIDTH == 0){
			for(i in a){
				printf("%s: ", i)
				for (j = 0; j < int(a[i] / 10000); j++){
					printf("#")
				}
				printf("\n")
			}
		}
		else{
			for(i in a){
				printf("%s: ", i)
				for (j = 0; j < int((WIDTH/MAX) * a[i]); j++){
					printf("#")
				}
				printf("\n")
			}
		}	
	} ' | sort)
		echo "$output"
	fi

fi

if [[ $COMMAND == "yearly" ]]; then
	if [[ $graph == "false" ]]; then
		output=$(echo "$FILTERED" | awk -F "," '{a[substr($2,1,4)]+=1} END{for (i in a)print i": "a[i];}' | sort)
		echo "$output"
	else
		output=$(echo "$FILTERED" | awk -F "," -v WIDTH="$WIDTH" -v MAX="$MAX" '{a[substr($2,1,4)]+=1} END{
		for (i in a){
			if (a[i] > MAX){
				MAX  = a[i] 	
			}
		}
		if (WIDTH == 0){
			for(i in a){
				printf("%s: ", i)
				for (j = 0; j < int(a[i] / 100000); j++){
					printf("#")
				}
				printf("\n")
			}
		}
		else{
			for(i in a){
				printf("%s: ", i)
				for (j = 0; j < int((WIDTH/MAX) * a[i]); j++){
					printf("#")
				}
				printf("\n")
			}
		}	
	} ' | sort)
		echo "$output"
	fi

fi

if [[ $COMMAND == "countries" ]]; then
	if [[ $graph == "false" ]]; then
		output=$(echo "$FILTERED" | awk -F "," '{a[$8]+=1} END{for (i in a){
		if (i == "" || i == "CZ") continue; else print i": "a[i];}}' | sort)
		echo "$output"
	else
		output=$(echo "$FILTERED" | awk -F "," -v WIDTH="$WIDTH" -v MAX="$MAX" '{a[$8]+=1} END{
		for (i in a){
			if (i != "" && i != "CZ"){
				if (a[i] > MAX){
					MAX  = a[i]
				} 	
			}
		}
		if (WIDTH == 0){
			for(i in a){
				if (i == "" || i == "CZ") continue;
				printf("%s: ", i)
				for (j = 0; j < int(a[i] / 100); j++){
					printf("#")
				}
				printf("\n")
			}
		}
		else{
			for(i in a){
				if (i == "" || i == "CZ") continue;
				printf("%s: ", i)
				for (j = 0; j < int((WIDTH/MAX) * a[i]); j++){
					printf("#")
				}
				printf("\n")
			}
		}	
	} ' | sort)
		echo "$output"
	fi
fi

if [[ $COMMAND == "districts" ]]; then
	if [[ $graph == "false" ]]; then
		output=$(echo "$FILTERED" | awk -F "," '{a[$6]+=1} END{for (i in a){
		if (i == "") print "None: "a[i]; else print i": "a[i];}}' | sort)
		echo "$output"
	else
		output=$(echo "$FILTERED" | awk -F "," -v WIDTH="$WIDTH" -v MAX="$MAX" '{a[$6]+=1} END{
		for (i in a){
			if (a[i] > MAX){
				MAX  = a[i]
			} 	
		}
		if (WIDTH == 0){
			for(i in a){
				if (i == "") printf("None: ")
				printf("%s: ", i)
				for (j = 0; j < int(a[i] / 1000); j++){
					printf("#")
				}
				printf("\n")
			}
		}
		else{
			for(i in a){
				if (i == "") printf("None: ")
				printf("%s: ", i)
				for (j = 0; j < int((WIDTH/MAX) * a[i]); j++){
					printf("#")
				}
				printf("\n")
			}
		}	
	} ' | sort)
		echo "$output"
	fi
fi

if [[ $COMMAND == "regions" ]]; then
	if [[ $graph == "false" ]]; then
		output=$(echo "$FILTERED" | awk -F "," '{a[$5]+=1} END{for (i in a){
		if (i == "") print "None: "a[i]; else print i": "a[i];}}' | sort)
		echo "$output"
	else
		output=$(echo "$FILTERED" | awk -F "," -v WIDTH="$WIDTH" -v MAX="$MAX" '{a[$5]+=1} END{
		for (i in a){
			if (a[i] > MAX){
				MAX  = a[i]
			} 	
		}
		if (WIDTH == 0){
			for(i in a){
				if (i == "") printf("None: ")
				printf("%s: ", i)
				for (j = 0; j < int(a[i] / 10000); j++){
					printf("#")
				}
				printf("\n")
			}
		}
		else{
			for(i in a){
				if (i == "") printf("None: ")
				printf("%s: ", i)
				for (j = 0; j < int((WIDTH/MAX) * a[i]); j++){
					printf("#")
				}
				printf("\n")
			}
		}	
	} ' | sort)
		echo "$output"
	fi
fi
