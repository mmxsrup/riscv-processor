#
# simulation.tcl  Tcl script for simulation
#
set     project_directory  "../build"
set     project_name        "project"

#
# Open Project
#
open_project [file join $project_directory $project_name]

#
# Set runtime
#
set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]

#
# Run Simulation
#
launch_simulation

#
# Close Project
#
# close_project