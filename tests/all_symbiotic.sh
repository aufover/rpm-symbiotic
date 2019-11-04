#!/bin/bash

passed=0
subtests=(unsorted/* mem/* overflows/* undefined/*)
total=${#subtests[@]}
skipped=0
failed=()

for subtest in ${subtests[@]}
do
	  pushd $subtest >/dev/null
	  echo "Running test $subtest:"
    symbiotic_opt=$(grep -m 1 "SYMBIOTIC_OPT=" config  | cut -f2 --delimiter==)
	  symbiotic --prp=$symbiotic_opt ./main.c 2> symbiotic.err | tee symbiotic.out | grep "RESULT" | tee res.sym #>/dev/null
    symbiotic_exp=$(grep -m 1 "SYMBIOTIC_EXP=" config  | cut -f2 --delimiter==)

    grep $symbiotic_exp res.sym >/dev/null
	  result=$?

    #echo "Test $subtest result: $result"
	  if [ "$result" == "0" ]
    then
        echo "Passed"
		    ((passed++))
	  else
        failed+=($subtest)
        echo "Failed"
    fi
    rm -f ./res.sym
    #rm -f symbiotic.out symbiotic.err
	  popd >/dev/null
done

echo "Passed $passed/$total tests"
echo "Failed tests:"
echo ${failed[@]}
#echo "Skipped $skipped/$total tests"
#[[ $total == $((passed + skipped)) ]] || exit 1
