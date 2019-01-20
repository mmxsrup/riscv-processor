path="./riscv-tests/isa/"
for file in $(ls $path | grep -v "\." | grep rv32ui-p-*); do
	echo $file
	riscv32-unknown-elf-objcopy -O binary $path$file $path$file.bin
	hexdump -v -e '1/4 "%08x" "\n"' $path$file.bin > ./tests/data.mem
	vivado -mode batch -quiet -source ./scripts/simulation.tcl
	echo $file >> ./build/project.sim/sim_1/behav/xsim/testlog.txt
done
