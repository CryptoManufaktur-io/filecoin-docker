#!/bin/bash
__percent_threshold=10
__kbyte_threshold=104857600
__docker_exe="docker"

dodocker() {
    $__docker_exe "$@"
}

determine_sudo() {
    __maybe_sudo=""
    if ! docker images >/dev/null 2>&1; then
        echo "Will attempt to use sudo to access docker"
        echo "This is expected to fail if sudo prompts for a password"
        __maybe_sudo="sudo"
    fi
}

determine_docker() {
    if [ -n "$__maybe_sudo" ]; then
        __docker_exe="sudo $__docker_exe"
    fi
}

if [ "$(dpkg-query -W -f='${Status}' bc 2>/dev/null | grep -c "ok installed")" = "0" ]; then
  echo "This script requires the bc package, please install it via 'sudo apt install bc'"
  exit 1
fi

cd "$(dirname "$0")" || exit 1

determine_sudo
determine_docker
__docker_dir=$(dodocker system info --format '{{.DockerRootDir}}')
__dryrun=0
__threshold_override=0
for (( i=1; i<=$#; i++ )); do
  var="${!i}"
  if [ "$var" = "--dry-run" ]; then
    __dryrun=1
  fi
  if [ "$var" = "--threshold" ]; then
    j=$((i+1))
    __kbyte_threshold=${!j}
    __threshold_override=1
    re='^[0-9]+$'
    if [ -z "$__kbyte_threshold" ] || [[ ! "$__kbyte_threshold" =~ $re ]]; then
      echo "--threshold requires a size in kbytes"
      exit 1
    fi
  fi
  if [ "$var" = "--help" ]; then
    echo "Check available space on $__docker_dir and prune Filecoin and output to stdout when it is under 400 GiB or under 10%"
    echo "Meant to be run from crontab with a MAILTO, as a simple alerting mechanism."
    echo
    echo "--dry-run"
    echo "  Run and alert on diskspace, but do not start a prune"
    echo "--threshold <kbytes>"
    echo "  Disk free threshold in kbytes at which to alert"
    exit 0
  fi
done

FREE_DISK=$(df -P "$__docker_dir" | awk '/[0-9]%/{print $(NF-2)}')
TOTAL_DISK=$(df -P "$__docker_dir" | awk '/[0-9]%/{print $(NF-4)}')
PERCENT_FREE=$(echo "percent = ($FREE_DISK / $TOTAL_DISK) * 100; scale = 0; percent / 1" | bc -l)
FREE_DISK_GB=$(echo "$FREE_DISK / 1024 / 1024" | bc)

# Try and detect the EL
var="COMPOSE_FILE"
value=$(sed -n -e "s/^${var}=\(.*\)/\1/p" ".env" || true)
# Literal match intended
# shellcheck disable=SC2076
if [[ "${value}" =~ "lotus.yml" ]]; then
  __el=lotus
  if [ "$__threshold_override" -eq 0 ]; then
    __kbyte_threshold=419430400
  fi
fi

# If under kbyte threshold or 10% free, alert
if [ "$FREE_DISK" -lt "${__kbyte_threshold}" ] || [ "$PERCENT_FREE" -lt "${__percent_threshold}" ]; then
  if [ "$__dryrun" -eq 0 ]; then
    if  [ "$__el" = "lotus" ]; then
      echo "Starting $__el prune. $FREE_DISK_GB GiB free on disk, which is $PERCENT_FREE percent."
      exec dodocker exec filecoin-lotus-1 lotus chain prune hot-moving
    fi
  fi
# The previous options will have exited the script before here
  echo "Disk space low, prune or resync may be required. $FREE_DISK_GB GiB free on disk, which is $PERCENT_FREE percent."
fi
