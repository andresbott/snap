#!/bin/bash

# https://stackoverflow.com/questions/3963716/how-to-manually-expand-a-special-variable-ex-tilde-in-bash/29310477#29310477
expandPath() {
  local path
  local -a pathElements resultPathElements
  IFS=':' read -r -a pathElements <<<"$1"
  : "${pathElements[@]}"
  for path in "${pathElements[@]}"; do
    : "$path"
    case $path in
      "~+"/*)
        path=$PWD/${path#"~+/"}
        ;;
      "~-"/*)
        path=$OLDPWD/${path#"~-/"}
        ;;
      "~"/*)
        path=$HOME/${path#"~/"}
        ;;
      "~"*)
        username=${path%%/*}
        username=${username#"~"}
        IFS=: read _ _ _ _ _ homedir _ < <(getent passwd "$username")
        if [[ $path = */* ]]; then
          path=${homedir}/${path#*/}
        else
          path=$homedir
        fi
        ;;
    esac
    resultPathElements+=( "$path" )
  done
  local result
  printf -v result '%s:' "${resultPathElements[@]}"
  printf '%s\n' "${result%:}"
}

printHelp(){

echo "
Usage :
  snap [-t]<type>

  <type>=capture type
  Posible captures are:
    s : (Selection) select the area of your screen
    w : (Window) select a window to capture
"
}


#########################################################################################################################################
########### Begin Script here
#########################################################################################################################################
command -v import >/dev/null 2>&1 || { echo >&2 "import, provided by imagemagic is required but it's not installed.  Aborting."; exit 1; }


main_config="/etc/snap.bash.conf"
if [ -f $main_config ]; then
    . $main_config
fi

user_config="~/.config/snap.bash.conf"
user_config=$(expandPath $user_config)

if [ -f $user_config ]; then
    . $user_config
fi

OUTPUT=$(expandPath $OUTPUT)
mkdir -p "$OUTPUT"


#https://unix.stackexchange.com/questions/6345/how-can-i-get-distribution-name-and-version-number-in-a-simple-shell-script
if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
    # linuxbase.org
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
    # Older Debian/Ubuntu/etc.
    OS=Debian
    VER=$(cat /etc/debian_version)
elif [ -f /etc/SuSe-release ]; then
    # Older SuSE/etc.
    ...
elif [ -f /etc/redhat-release ]; then
    # Older Red Hat, CentOS, etc.
    ...
else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    VER=$(uname -r)
fi



#-comment string      annotate image with comment
# comment get linux os, version date

# -screen to select window

#
#lastFile=`find "$OUTPUT" -maxdepth 1 -name "$FILENAME*" | sort -t_ -nk2,2 | tail -n1`
#filename="${lastFile##*/}"
#filename="${filename%.*}"
#
#filenameLengh=${#FILENAME}
#sequence=${filename:filenameLengh: 3}
#
#nextSequence="$(($sequence + 1))"
#printf -v nextSequence "%04d" $nextSequence
#echo $nextSequence

DATE=`date '+%Y-%m-%d'`
TIME=`date '+%H.%M.%S'`

new_filename="$FILENAME""_""$DATE""_at_""$TIME"



#https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -t|--type)
    TYPE="$2"
    shift # past argument
    shift # past value
    ;;

    -h|--help)
    help=YES
    shift # past argument
    ;;

    --default)
    DEFAULT=YES
    shift # past argument
    ;;

    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;

esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

#if [[ -n $1 ]]; then
#    echo "Last line of file specified as non-opt/last argument:"
#   #tail -1 "$1"
#fi

if [ "$help" = "YES" ]; then
    printHelp
    exit;
fi


PARAMS="-comment \"$OS $VER\""
PARAMS=""

snap_type="${TYPE}"



ScriptName="$(basename "$0")"

if [ "$ScriptName" = "snap.bash.w" ]; then
    snap_type="w"
elif [ "$ScriptName" = "snap.bash.s" ]; then
    snap_type="s"
fi

if [ "$snap_type" = "w" ]; then
    PARAMS="$PARAMS"" -screen"
elif [ "$snap_type" = "s" ]; then
    PARAMS="$PARAMS"
else
    PARAMS="$PARAMS"
fi

if [ "$ADDWINDOW" = "true" ]; then
    PARAMS="$PARAMS"" -frame "
fi

PARAMS="$PARAMS"" $ADITIONALPARAMS"

PARAMS="$(echo -e "${PARAMS}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

#echo "import" $PARAMS "$OUTPUT/$new_filename.png"
#//import "$PARAMS $OUTPUT/$new_filename.png"

r=$(import $PARAMS "$OUTPUT/$new_filename.png")

FileLocation="/usr/local/share/snap.bash/shutter.wav"

if [ "$PLAYSOUND" = "true" ]; then
    r1=`play $FileLocation`
fi


