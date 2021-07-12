#!/bin/bash

IS_BROWSERSTACK_TEST=false
IS_IP_FETCH_REQUIRED=false
IS_PARALLEL_COUNT_FLAG=false
TOTAL_PARALLEL_TESTS=1

parallel_count_arr=0
arr_no=0
for var in "$@"
do
    arr_no=$((arr_no+1))
    case $var in
        "--browserstack")
            IS_BROWSERSTACK_TEST=true
            ;;
        "--ip-check")
            IS_IP_FETCH_REQUIRED=true
            ;;
        "--parallel-threads")
            parallel_count_arr=$((arr_no))
            IS_PARALLEL_COUNT_FLAG=true
            ;;
    esac
done

echo $IS_BROWSERSTACK_TEST
echo $IS_IP_FETCH_REQUIRED
echo $IS_PARALLEL_COUNT_FLAG

if [ "$IS_PARALLEL_COUNT_FLAG" = true ] ; then
    re='^[1-9][0-9]+$'
    arr_index=$(($parallel_count_arr+1))
    temp=${!arr_index}
    echo $temp
    if ! [[ $temp =~ $re ]] ; then
        TOTAL_PARALLEL_TESTS=1
    else
        TOTAL_PARALLEL_TESTS=$((temp))
    fi
fi
params=""
if [ "$IS_BROWSERSTACK_TEST" = true ] ; then
    params+=" --browserstack"
fi
if [ "$IS_IP_FETCH_REQUIRED" = true ] ; then
    params+=" --ip-check"
fi

for i in $(seq 1 $TOTAL_PARALLEL_TESTS); 
do
        bash find-ip-rtt.sh "TEST NO: $i" $params &
done

