#!/usr/bin/env bash

#
# WARNING:
# This script is very experimental, use with caution!
#

#################################################
#### Ensure we are in the right path. ###########
#################################################
if [[ 0 -eq $(echo $0 | grep -c '^/') ]]; then
    # relative path
    EXEC_PATH=$(dirname "`pwd`/$0")
else
    # absolute path
    EXEC_PATH=$(dirname "$0")
fi

EXEC_PATH=$(echo ${EXEC_PATH} | sed 's@/\./@/@g' | sed 's@/\.*$@@')
cd $EXEC_PATH || exit 1
#################################################
source utils.sh
source common.env

NUMBER_OF_VALIDATORS="64"
EL_AND_CL_MNEMONIC="giant issue aisle success illegal bike spike question tent bar rely arctic volcano long crawl hungry vocal artwork sniff fantasy very lucky have athlete"

cfg_dir="../cfg_files"
cfg_path="${cfg_dir}/custom.env"
vc_dir="${cfg_dir}/__tmp__vcdata"

rm -rf ${vc_dir}
mkdir ${vc_dir} || die

validator_cnt=$(grep -Po '(?<=NUMBER_OF_VALIDATORS=")\d+' $cfg_path)
mnemonics=$(grep -Po '(?<=EL_AND_CL_MNEMONIC=")[\s\w]+(?=")' $cfg_path)

if [[ "" == $validator_cnt || "" == $mnemonics ]]; then
    die "$LINENO"
fi

# --testnet-dir=${testnet_dir} \
echo ${mnemonics} | ../testdata/bin/lighthouse \
    account validator recover \
    --stdin-inputs \
    --datadir=${vc_dir} \
    --count=${validator_cnt} \
    --store-withdrawal-keystore

