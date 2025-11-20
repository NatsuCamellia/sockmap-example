# sockmap-example

This is the accompany repo for [my note on HackMD](https://hackmd.io/@NatsuCamellia/sockmap).

## Prerequisites

- sockperf
- clang
- libbpf

## How to Run?

```
$ make
# ./run_test.sh
```

Build the program with `make` and run the test script with `./run_test.sh`. The script runs two sockperf tests with and without SOCKMAP respectively.

## Credits

- [jsitnicki/kubecon-2024-sockmap](https://github.com/jsitnicki/kubecon-2024-sockmap)
