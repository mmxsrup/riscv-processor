## Risc-V Processor
RV32I Single Cycle Processor

### Howt to download
```
git clone --recursive git@github.com:mmxsrup/riscv-processor.git
```

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
