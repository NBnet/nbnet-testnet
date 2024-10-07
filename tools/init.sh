#!/bin/bin/env bash

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

pkill lighthouse
pkill reth
pkill geth

sleep 1

mkdir -p $el_data_dir $cl_bn_data_dir $cl_vc_data_dir || die
cp ../static_files/jwt.hex ${jwt_path} || die

${bin_dir}/geth init \
    --datadir=${el_data_dir} \
    --state.scheme='hash' \
    ${genesis_json_path} \
    >> ${el_data_dir}/eth1_geth_reth.log 2>&1 || die

# ${bin_dir}/reth init \
#     --chain=${genesis_json_path} \
#     --datadir=${el_data_dir} \
#     --log.file.directory=${el_data_dir}/logs \
#     >> ${el_data_dir}/eth1_geth_reth.log || die

echo '**=============================================================**' \
    >> ${el_data_dir}/eth1_geth_reth.log || die

# remove the `--gcmode=archive` for a full node
#
# --metrics
# --metrics.port 6060
# --discovery.v5
nohup ${bin_dir}/geth \
    --networkid=${chain_id} \
    --datadir=${el_data_dir} \
    --state.scheme='hash' \
    --bootnodes= \
    --nat=extip:${NBNET_EXT_IP} \
    --discovery.port 30303 \
    --http --http.addr='0.0.0.0' --http.port=8545 --http.vhosts='*' --http.corsdomain='*' \
    --http.api='admin,debug,eth,net,txpool,web3,rpc' \
    --ws --ws.addr='0.0.0.0' --ws.port=8546 --ws.origins='*' \
    --ws.api='net,eth' \
    --authrpc.addr='localhost' --authrpc.port=8551 \
    --authrpc.jwtsecret=${jwt_path} \
    --syncmode=full \
    --gcmode=archive \
    >>${el_data_dir}/eth1_geth_reth.log 2>&1 &

# # add the `--full` for a fullnode
# #
# # --enable-discv5-discovery
# # --discovery.v5.port 9200
# #
# nohup ${bin_dir}/reth node \
#     --chain=${genesis_json_path} \
#     --datadir=${el_data_dir} \
#     --log.file.directory=${el_data_dir}/logs \
#     --ipcdisable \
#     --nat=extip:${NBNET_EXT_IP} \
#     --discovery.port 30303 \
#     --http --http.addr='0.0.0.0' --http.port=8545 --http.corsdomain='*' \
#     --http.api='admin,debug,eth,net,txpool,web3,rpc' \
#     --ws --ws.addr='0.0.0.0' --ws.port=8546 --ws.origins='*' \
#     --ws.api='eth,net' \
#     --authrpc.addr='localhost' --authrpc.port=8551 \
#     --authrpc.jwtsecret=${jwt_path} \
#     >>${el_data_dir}/eth1_geth_reth.log 2>&1 &

nohup ${bin_dir}/lighthouse beacon_node \
    --testnet-dir=${testnet_dir} \
    --datadir=${cl_bn_data_dir} \
    --staking \
    --slots-per-restore-point=32 \
    --boot-nodes= \
    --enr-address=${NBNET_EXT_IP} \
    --disable-enr-auto-update \
    --disable-upnp \
    --listen-address='0.0.0.0' \
    --port=9000 --discovery-port=9000 --quic-port=9001 \
    --http --http-address='0.0.0.0' --http-port=5052 --http-allow-origin='*' \
    --metrics --metrics-address='0.0.0.0' --metrics-port=5054 --metrics-allow-origin='*' \
    --execution-endpoints='http://localhost:8551' \
    --jwt-secrets=${jwt_path} \
    --suggested-fee-recipient=${fee_recipient} \
    >>${cl_bn_data_dir}/lighthouse.bn.log 2>&1 &

nohup ${bin_dir}/lighthouse validator_client \
    --testnet-dir=${testnet_dir} \
    --datadir=${cl_vc_data_dir}\
    --beacon-nodes='http://localhost:5052' \
    --init-slashing-protection \
    --suggested-fee-recipient=${fee_recipient} \
    --http --http-address='0.0.0.0' --http-port='5062' --http-allow-origin='*' \
    --unencrypted-http-transport \
    --metrics --metrics-address='0.0.0.0' --metrics-port=5064 --metrics-allow-origin='*' \
    >>${cl_vc_data_dir}/lighthouse.vc.log 2>&1 &

sleep 1

tail -n 3 ${el_data_dir}/eth1_geth_reth.log
echo
tail -n 3 ${cl_bn_data_dir}/lighthouse.bn.log
echo
tail -n 3 ${cl_vc_data_dir}/lighthouse.vc.log

