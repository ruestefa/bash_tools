#!/bin/bash

# Free unused memory claimed by linux in WSL2
# src: https://devblogs.microsoft.com/commandline/memory-reclaim-in-the-windows-subsystem-for-linux-2/
free_memory()
{
    echo "echo 1 > /proc/sys/vm/compact_memory"
    echo 1 > /proc/sys/vm/compact_memory
    echo "echo 1 > /proc/sys/vm/drop_caches"
    echo 1 > /proc/sys/vm/drop_caches
}

case "$(whoami)" in
    root)
        free_memory
    ;;
    *)
        echo "root password required"
        export -f free_memory
        su -c free_memory
    ;;
esac
