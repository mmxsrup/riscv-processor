#
# create_project.tcl  Tcl script for creating project
#
# set     project_directory   [file dirname [info script]]
set     project_directory  "./build"
set     project_name        "project"
set board_part [get_board_parts -quiet -latest_file_version "*zc706*"]

#
# Create project
#
create_project -force $project_name $project_directory

#
# Set project properties
#
if {[info exists board_part ] && [string equal $board_part  "" ] == 0} {
    set_property "board_part"     $board_part      [current_project]
} elseif {[info exists device_part] && [string equal $device_part "" ] == 0} {
    set_property "part"           $device_part     [current_project]
} else {
    puts "ERROR: Please set board_part or device_part."
    return 1
}

#
# Add souce file
#
add_file ./modules/core/alu.sv
add_file ./modules/core/control.sv
add_file ./modules/core/core.sv
add_file ./modules/core/csr_file.sv
add_file ./modules/core/datapath.sv
add_file ./modules/core/decode.sv
add_file ./modules/core/decode_execute.sv
add_file ./modules/core/execute.sv
add_file ./modules/core/fetch.sv
add_file ./modules/core/lsu.sv
add_file ./modules/core/pc_mux.sv
add_file ./modules/core/regfile.sv
add_file ./modules/core/src_a_mux.sv
add_file ./modules/core/src_b_mux.sv
add_file ./modules/core/writeback.sv
add_file ./modules/core/pkg/alu_op_pkg.sv
add_file ./modules/core/pkg/csr_addr_pkg.sv
add_file ./modules/core/pkg/pc_mux_pkg.sv
add_file ./modules/core/pkg/src_a_mux_pkg.sv
add_file ./modules/core/pkg/src_b_mux_pkg.sv
add_file ./modules/core/pkg/type_pkg.sv

add_file ./modules/cache/dcache.sv
add_file ./modules/cache/icache.sv
add_file ./modules/cache/cachemem.sv

add_file ./modules/axi4/axi_lite_if.sv
add_file ./modules/axi4/axi_lite_pkg.sv

add_file ./modules/ram/pkg/ram_pkg.sv
add_file ./modules/ram/blockram.sv
add_file ./modules/ram/ram.sv

add_file ./modules/bus/arbiter.sv
add_file ./modules/bus/interconnect_bus.sv

add_file ./tests/tb_top.sv
add_file ./tests/data.mem
# close_project
