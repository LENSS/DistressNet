#!/bin/bash

date -d @`echo "$1+946684800" | bc`
