# NBnet-Testnet

> **NOTE:**    
> Can only run on recent versions of `Ubuntu/Debian/Fedora Linux` by default.    
> For building on non-standard OS platforms, check [**github.com/NBnet/EGG**](https://github.com/NBnet/EGG/blob/master/README.md#build-on-custom-os-platforms).

### Generate the initial node

```shell
# Execute on demand when there are code changes,
# this operation will trigger the `sudo` command.
#
# For building on your custom OS platforms,
# you should install all dependencies manually,
# and then use `make minimal_prepare` instead.
#
make prepare

# Create genesis data for the new testnet,
# and create an initial node instance for it.
make create_initial_node

# Start the node.
make start_initial_node

# Stop it.
make stop_initial_node
```
