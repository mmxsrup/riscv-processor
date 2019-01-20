## Risc-V Processor
RV32I Single Cycle Processor


### How to test
Create a binary file for testing
```sh
cd ./riscv-tests/isa/
make XLEN=32
cd -
```
Create vivado project
```sh
make create_project
```
Execute simulation
```sh
make simulation
```
Confirm test results
```sh
more tests/testlog.txt
```
