vivado = vivado

create_project: ./scripts/create_project.tcl
	vivado -source ./scripts/create_project.tcl

simulation: ./tests/test.sh
	./tests/test.sh
	
clean: 
	rm -rf vivado* .Xil build ./tests/data.mem ./tests/vivado*