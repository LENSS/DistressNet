#!/bin/bash

for each in $(seq $1 $2)
do
sh ucigen.sh $each > tmpconfig
scp tmpconfig root@192.168.$each.1:/tmp
ssh root@192.168.$each.1 'sh /tmp/tmpconfig'
done