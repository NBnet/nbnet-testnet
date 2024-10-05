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
source ./common.env

pkill reth
pkill geth
sleep 1

pkill lighthouse
sleep 1

peer_ip=$NBNET_PEER_IP

el_enode=$(curl -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"admin_nodeInfo","params":[],"id":1}' "http://${peer_ip}:8545" | jq '.result.enode' | sed 's/"//g' || exit 1)
cl_enr=$(curl "http://${peer_ip}:5052/eth/v1/node/identity" | jq '.data.enr' | sed 's/"//g' || exit 1)
cl_peer_id=$(curl "http://${peer_ip}:5052/eth/v1/node/identity" | jq '.data.peer_id' | sed 's/"//g' || exit 1)

mkdir -p $el_data_dir $cl_bn_data_dir $cl_vc_data_dir || exit 1
cp ../static_files/jwt.hex ${jwt_path} || exit 1

nohup ${bin_dir}/geth \
    --networkid=${chain_id} \
    --datadir=${el_data_dir} \
    --state.scheme='hash' \
    --bootnodes= \
    --nat=extip:${external_ip} \
    --discovery.port 30303 \
    --http --http.addr='0.0.0.0' --http.port=8545 --http.vhosts='*' --http.corsdomain='*' \
    --http.api='admin,debug,eth,net,txpool,web3,rpc' \
    --ws --ws.addr='0.0.0.0' --ws.port=8546 --ws.origins='*' \
    --ws.api='net,eth' \
    --authrpc.addr='localhost' --authrpc.port=8551 \
    --authrpc.jwtsecret=${jwt_path} \
    --syncmode=full \
    --gcmode=archive \
    --trusted-peers=${el_enode} \
    --bootnodes=${el_enode} \
    >>${el_data_dir}/geth_reth.log 2>&1 &

nohup ${bin_dir}/lighthouse beacon_node \
    --testnet-dir=${testnet_dir} \
    --datadir=${cl_bn_data_dir} \
    --staking \
    --slots-per-restore-point=32 \
    --boot-nodes= \
    --enr-address=${external_ip} \
    --disable-enr-auto-update \
    --disable-upnp \
    --listen-address='0.0.0.0' \
    --port=9000 --discovery-port=9000 --quic-port=9001 \
    --http --http-address='0.0.0.0' --http-port=5052 --http-allow-origin='*' \
    --metrics --metrics-address='0.0.0.0' --metrics-port=5054 --metrics-allow-origin='*' \
    --execution-endpoints="http://localhost:8551" \
    --jwt-secrets=${jwt_path} \
    --suggested-fee-recipient=${fee_recipient} \
    --boot-nodes=${cl_enr} \
    --trusted-peers=${cl_peer_id} \
    --checkpoint-sync-url="http://${peer_ip}:5052" \
    >>${cl_bn_data_dir}/lighthouse.bn.log 2>&1 &

sleep 1

tail -n 3 ${el_data_dir}/geth_reth.log
echo
tail -n 3 ${cl_bn_data_dir}/lighthouse.bn.log

exit 0
