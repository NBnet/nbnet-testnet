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

genesis: minimal_prepare
	cp cfg_files/custom.env submodules/egg/
	cd submodules/egg && make build
	rm -rf testdata/node
	mkdir -p testdata/node/cl/vc
	cp -r submodules/egg/data testdata/node/meta
	cd testdata/node && cp -r meta/vcdata/* cl/vc/

create_initial_node: stop_initial_node genesis
	bash -x tools/init.sh

start_initial_node:
	bash -x tools/start.sh

stop_initial_node:
	bash -x tools/stop.sh

archive_node: stop_initial_node
	sleep 3
	tar -zcpf initial_node.tar.gz testdata

jwt:
	bash -x tools/update_jwt.sh

fmt:
	find tools -type f | xargs sed -i 's/\t/    /g'
	find tools -type f | grep -v '\.md' | xargs sed -i 's/ $$//g'

update:
	git pull --prune
	git submodule update --init --recursive
