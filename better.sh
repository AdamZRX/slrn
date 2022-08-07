#!/bin/bash

########################################################################
#  - This is the main script that is used to compile/interpret the source code
#  - The script takes 3 arguments
#    1. The compiler that is to compile the source file.
#    2. The source file that is to be compiled/interpreted
#    3. Additional argument only needed for compilers, to execute the object code
#
#  - Sample execution command:   $: ./script.sh g++ file.cpp ./a.out
#
########################################################################

runtime=$1
compiler=$2
file=$3
output=$4
addtionalArg=$5

########################################################################
#  - The script works as follows
#  - It first stores the stdout and std err to another stream
#  - The output of the stream is then sent to respective files
#
#
#  - if third arguemtn is empty Branch 1 is followed. An interpretor was called
#  - else Branch2 is followed, a compiler was invoked
#  - In Branch2. We first check if the compile operation was a success (code returned 0)
#
#  - If the return code from compile is 0 follow Branch2a and call the output command
#  - Else follow Branch2b and output error Message
#
#  - Stderr and Stdout are restored
#  - Once the logfile is completely written, it is renamed to "completed"
#  - The purpose of creating the "completed" file is because NodeJs searches for this file
#  - Upon finding this file, the NodeJS Api returns its content to the browser and deletes the folder
#
#
########################################################################

exec  1> $"/usercode/logfile.txt"
exec  2> $"/usercode/errors"

if [[ $@ == *"py"* ]] || [[ $@ == *"python"* ]]; then
    cp -r /home/files/ /usercode/files
fi

#Branch 1
if [ "$output" = "" ]; then
    if [ "$compiler" = "php" ]; then
        timeout "$runtime" "$compiler" /usercode/$file -< $"/usercode/inputFile" 2> /dev/null
        status=$?
        if [ "$status" -eq 143 ]; then
            echo -e "\nExecution Timed Out!" >> /usercode/errors
            echo -e "4" > /usercode/errorCode
        elif [ "$status" -ne 0 ];  then
            echo -e "5" > /usercode/errorCode
        fi
    elif [[ $compiler == *"py"* ]] || [[ $compiler == *"python"* ]] || [[ $compiler == *"Rscript"* ]]; then
        cd /usercode
        timeout "$runtime" "$compiler" $file -< $"inputFile"
        status=$?
        if [ "$status" -eq 143 ]; then
            echo -e "\nExecution Timed Out!" >> errors
            echo -e "4" > errorCode
        elif [ "$status" -ne 0 ];  then
            echo -e "5" > errorCode
        fi
        cd ..
    else
        timeout "$runtime" "$compiler" /usercode/$file -< $"/usercode/inputFile"
        status=$?
        if [ "$status" -eq 143 ]; then
            echo -e "\nExecution Timed Out!" >> /usercode/errors
            echo -e "4" > /usercode/errorCode
        elif [ "$status" -ne 0 ];  then
            echo -e "5" > /usercode/errorCode
        fi
    fi
    #Branch 2
else
    #In case of compile errors, redirect them to a file
    $compiler /usercode/$file $addtionalArg &> /usercode/errors
    #Branch 2a
    if [ "$?" -eq 0 ];  then
        if [[ $compiler == *"kt"* ]] || [[ $compiler == *"kotlin"* ]]; then
            $output -< $"/usercode/inputFile"
        else
            timeout "$runtime" "$output" -< $"/usercode/inputFile"
        fi
        status=$?
        if [ "$status" -eq 143 ]; then
            echo -e "\nExecution Timed Out!" >> /usercode/errors
            echo -e "4" > /usercode/errorCode
        elif [ "$status" -ne 0 ];  then
            echo -e "5" > /usercode/errorCode
        fi
        #Branch 2b
    else
        # echo -e "\nCompilation Failed!" >> /usercode/errors
        echo -e "2" > /usercode/errorCode
    fi
fi

# This may happen earlier than the time limit when the ulimit's 10MB limit reaches and..
# So, the process is stopped.
# Next the following part checks the filesize and if
#   it is bigger than 100KB, it will only take the
#   first 2048 chars and because most probably
#   the code was infinite loop..
#   it will remove and replace the error with "Timed Out"
maxsize=100000 # 100KB
filesize=$(stat -c%s /usercode/logfile.txt)
if (( filesize > maxsize )); then
    head -c 2048 /usercode/logfile.txt > /usercode/small_logfile.txt
    rm /usercode/logfile.txt
    mv /usercode/small_logfile.txt /usercode/logfile.txt
    echo -e "\nExecution Timed Out!" > /usercode/errors
fi

mv /usercode/logfile.txt /usercode/completed
