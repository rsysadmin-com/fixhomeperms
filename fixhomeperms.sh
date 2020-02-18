#!/bin/bash 

#
# fixhomeperms.sh v0.0001
#
# quick and dirty script to fix permissions for all files and directories under $HOME
# 
# the following is assumed to be true for the final results:
#       * directories: rwxr-x-r-x (octal: 755)
#       * regular files: rw-r--r-- (octal: 644)
#       * executable files: rwxr-xr-x (octal: 755)
#           - Shell scripts (.sh)
#           - Perl files (.pl)
#           - Python files (.py)
#           - Ruby files (.rb)
#           - RUN files (.run)
# -------------------------------------------

#
# Functions
#

usage() # option -h
{
    echo "$(basename $0) by Martin Mielke <martin@mielke.com>"
        echo -e "Usage:\t$(basename $0) [-h] [-d] [-n] [-s] [-p] [-P] [-r] [-R] [-a]"
        echo -e "\t-h  Prints this help."
        echo -e "\t-d  Fix permissions on directories (755)."
        echo -e "\t-n  Fix permissions on non-exec files (644)."
        echo -e "\t-s  Fix permissions on shell script files (755)."
        echo -e "\t-p  Fix permissions on Perl files (755)."
        echo -e "\t-P  Fix permissions on Python files (755)."
        echo -e "\t-r  Fix permissions on Ruby files (755)."
        echo -e "\t-R  Fix permissions on RUN files (755)."        
        echo -e "\t-a  Fix permissions on all executable files (.sh, .pl, .py, .rb, .run)."
        echo -e "\t-A  Fix all in one step, including directories and non-exec files."
        exit 1
}

function returnStatus { # helper funcion
    if [[ $? -eq 0 ]]
    then
        echo -e "\t[ OK ]"
    else
        echo -e "\t[ ERROR ]"
    fi
}

function finishMessage {
    echo -e " [$(date +%_H:%M:%S)] -- All set.\n"
    exit 0
}

function fixDirectories {   # option -d
    echo -e " [$(date +%_H:%M:%S)] == Fixing directory permissions (chmod 755) ... \c"
    find $HOME/ -type d -print0 | xargs -0 -n1024 -P0 chmod 755
    returnStatus
}

function fixNonExecFiles {  # option -n
    echo -e " [$(date +%_H:%M:%S)] == Fixing non-exec files permissions (chmod 644) ... \c"
    find $HOME/ -type f \( -not -name '*.sh' -not -name '*.pl' -not -name '*.py' -not -name '*.rb' -not -name '*.run' -not -path '*/\.*' \) -print0 | xargs -0 -n1024 -P0 chmod 644
    returnStatus
}

function fixShellFiles {    # option -s
    echo -e "[$(date +%_H:%M:%S)] == Fixing permissions for Shell scripts... \c"
    find $HOME/ -type f -name '*.sh' -print0 | xargs -0 -n1024 -P0 chmod 755
    returnStatus

}

function fixPerlFiles {     # option -p
    echo -e "[$(date +%_H:%M:%S)] == Fixing permissions for Perl files... \c"
    find $HOME/ -type f -name '*.pl' -print0 | xargs -0 -n1024 -P0 chmod 755
    returnStatus
}

function fixPythonFiles {   # option -P
    echo -e "[$(date +%_H:%M:%S)] == Fixing permissions for Python files... \c"
    find $HOME/ -type f -name '*.py' -print0 | xargs -0 -n1024 -P0 chmod 755
    returnStatus
}

function fixRubyFiles {     # option -r
    echo -e "[$(date +%_H:%M:%S)] == Fixing permissions for Ruby files... \c"
    find $HOME/ -type f -name '*.rb' -print0 | xargs -0 -n1024 -P0 chmod 755
    returnStatus
}

function fixRunFiles {      # option -R
    echo -e "[$(date +%_H:%M:%S)] == Fixing permissions for RUN files... \c"
    find $HOME/ -type f -name '*.run' -print0 | xargs -0 -n1024 -P0 chmod 755
    returnStatus
}

function fixAllExecutableFiles {    # option -a
    fixShellFiles
    fixPerlFiles
    fixPythonFiles
    fixRubyFiles
    fixRunFiles
}

function fixAll {       # option -A
    fixDirectories
    fixNonExecFiles
    fixAllExecutableFiles
}

# main()

if [[ $# -eq 0 ]]
then
        usage
fi

set -- `getopt hdnspPrRaA $*`

if [[ $? -ne 0 ]]
then
        usage
fi


for arg in $*
do
        case $arg in
        -h) usage; shift 1;;
        -d) fixDirectories; exit 0;;
        -n) fixNonExecFiles; exit 0;;
        -s) fixShellFiles; exit 0;;
        -p) fixPerlFiles; exit 0;;
        -P) fixPythonFiles; exit 0;;
        -r) fixRubyFiles; exit 0;;
        -R) fixRunFiles; exit 0;;
        -a) fixAllExecutableFiles; exit 0;;
        -A) fixAll; exit 0;;

        *) usage;;
        esac
done

finishMessage

# The End.
