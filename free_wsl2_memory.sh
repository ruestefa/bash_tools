#!/bin/bash

# Free unused memory claimed by linux in WSL2
# src: https://devblogs.microsoft.com/commandline/memory-reclaim-in-the-windows-subsystem-for-linux-2/
echo "root password required"
su -c 'echo 1 > /proc/sys/vm/drop_caches'
