#!/bin/bash

export KBUILD_BUILD_USER="Peppe289"

export KBUILD_BUILD_HOST="RaveRules"

export TOOLCHAIN=gcc

export DEVICES=begonia

source helper

gen_toolchain

send_msg "⏳ Start build ${DEVICES}..."

START=$(date +"%s")

for i in ${DEVICES//,/ }
do 

	build ${i} -kernel


done

END=$(date +"%s")

DIFF=$(( END - START ))
