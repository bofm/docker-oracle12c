#!/usr/bin/env bash
set -e
for arg in "$@"; do
    if [ "$arg" == '--shm' ]; then
        # 50% of total RAM
        echo "Mounting /dev/shm..."
        size=$((`grep MemTotal /proc/meminfo| awk '{print $2}'` /2/1024))m
        mount -t tmpfs shmfs -o remount,size=$size /dev/shm
    fi
done

args=( "$@" )
del=(--shm)
args=( "${args[@]/$del}" )

exec gosu oracle entrypoint_oracle.sh ${args[@]}
# exec "$@"
