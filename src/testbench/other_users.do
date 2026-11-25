set script_dir [file dirname [file normalize [info script]]]
cd $script_dir

vlib work
vlog -sv random.v other_users.v other_users_tb.v
vsim -voptargs="+acc" work.other_users_tb
add wave *
run -all
