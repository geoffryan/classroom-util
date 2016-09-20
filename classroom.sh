#!/bin/bash
# -----------------------------------------------------------------------------
#   Github Classroom collect homework
#
#   with thanks to: Keith Chappelow on Education GitHub forums.
#                   (https://education.github.community/t/
#                       automatically-gathering-collecting-assignments/2595/8)
# -----------------------------------------------------------------------------

function print_usage {
    echo "usage: classroom mode org_name homework_name [due_date]"
    echo "      'mode' can be one of \"collect\", \"grade\", or \"return\"."
    echo "          \"collect\": clones/pulls all matching repos."
    echo "          \"grade\": Requires due_date. Branches off most recent"
    echo "                  commit before due_date"
    echo "          \"return\": Merges graded into master, pushes to origin."
}

## Parse arguments ##

students="students.txt"
logfile="class.log"

collect_mode="collect"
grade_mode="grade"
return_mode="return"


if [ "$#" -lt 3 ]
then
    print_usage
    exit 1
fi

mode=$1
org=$2
prefix=$3

if [ "$mode" = "$grade_mode" ]
then
    if [ "$#" -lt 4 ]
    then
        print_usage
        exit 1
    else
        duedate="$4"
    fi
fi


# Primary function. Updates or clones a given repo,
# finds last commit before due date, tags it, and starts
# a new "grading branch" off it.

function collect {

    workdir=$(pwd)
    log="$workdir/$logfile"
    repo="$prefix-$1"
    echo -n "$repo"

    if [ -d $repo ]
    then
        echo -n " updating"
        cd "$repo"
        git pull git@github.com:"$org"/"$repo" >> "$log" 2>&1
        cd "$workdir"
    else
        echo -n " cloning"
        git clone git@github.com:"$org"/"$repo" >> "$log" 2>&1
    fi
    echo ""
}

function grade {

    workdir=$(pwd)
    log="$workdir/$logfile"
    repo="$prefix-$1"
    echo -n "$repo"

    cd "$repo"

    if [ "$duedate" ]
    then
        commit=$(git rev-list -n 1 --before="$duedate" HEAD 2>>"$log")
    else
        commit="HEAD"
    fi
    if [ -z "$commit" ]
    then
        echo "  LATE: no commits before date $duedate"
        return 1
    fi

    git tag -a Graded -m "This version is graded." "$commit" >> "$log" 2>&1
    git checkout -b grading-branch "$commit" >> "$log" 2>&1

    echo ""
    cd "$workdir"
}

function returnFunc {
    echo "Not implemented."
}

echo "mode: $mode"
echo "org: $org"
echo "hw prefix: $prefix"
if [ "$mode" = "$collect_mode" ]
then
    echo "duedate: $duedate"
fi

while IFS='' read -r line || [[ -n "$line" ]];
do
    if [ "$mode" = "$collect_mode" ]
    then
        collect $line
    elif [ "$mode" = "$grade_mode" ]
    then
        grade $line
    elif [ "$mode" = "$return_mode" ]
    then
        returnFunc $line
    fi

done < $students

