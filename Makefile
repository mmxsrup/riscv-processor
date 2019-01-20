vivado = vivado

create_project: ./scripts/create_project.tcl
	echo "" > ./tests/data.mem
	vivado -source ./scripts/create_project.tcl

simulation: ./tests/test.sh
	./tests/test.sh
	cp ./build/project.sim/sim_1/behav/xsim/testlog.txt ./tests/
	
clean: 
	rm -rf vivado* .Xil build ./tests/data.mem ./tests/vivado*