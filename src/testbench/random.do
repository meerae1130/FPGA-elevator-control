set script_dir [file dirname [file normalize [info script]]]
cd $script_dir

vlib work
vlog -sv random.v random_tb.v
vsim -voptargs="+acc" work.random_tb
add wave *
run -all
