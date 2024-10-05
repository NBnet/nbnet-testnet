all: create_initial_node

prepare_code:
	git submodule update --init --recursive

prepare_bin: prepare_code
	rm -rf testdata/bin; mkdir -p testdata/bin
	cd submodules/lighthouse && make && cp ./target/release/lighthouse ../../testdata/bin/
	cd submodules/reth && make build && cp ./target/release/reth ../../testdata/bin/
	cd submodules/go-ethereum && make geth && cp build/bin/geth ../../testdata/bin/

prepare: prepare_bin
	cd submodules/egg && make prepare

minimal_prepare: prepare_bin
	cd submodules/egg && make minimal_prepare

restore_initial_validators: minimal_prepare
	bash -x tools/restore_validator_keys.sh
	rm -rf testdata/node; mkdir -p testdata/node/cl/vc
	mv cfg_files/__tmp__vcdata/* testdata/node/cl/vc/

genesis: prepare_code restore_initial_validators
	cp cfg_files/custom.env submodules/egg/
	cd submodules/egg && make build
	cp -r submodules/egg/data testdata/node/cfg

create_initial_node: stop_initial_node genesis
	bash -x tools/init.sh

start_initial_node:
	bash -x tools/start.sh

stop_initial_node:
	bash -x tools/stop.sh

archive_node: stop_initial_node
	sleep 3
	tar -zcpf initial_node.tar.gz testdata

fmt:
	find tools -type f | xargs sed -i 's/\t/    /g'
	find tools -type f | grep -v '\.md' | xargs sed -i 's/ $$//g'

jwt:
	bash -x tools/update_jwt.sh
