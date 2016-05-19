#!/bin/bash

for each in $(seq $1 $2); do scp $3 root@192.168.50.$each:$4; done
