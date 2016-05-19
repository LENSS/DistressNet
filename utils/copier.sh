#!/bin/bash

for each in $(seq 2 6); do scp S91mystuff root@192.168.$each.1:/etc/rc.d/; done
for each in $(seq 7 8); do scp S92storageclient root@192.168.$each.1:/etc/rc.d/; done
