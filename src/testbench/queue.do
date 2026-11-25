set script_dir [file dirname [file normalize [info script]]]
cd $script_dir

vlib work
vlog -sv queue.v queue_tb.v
vsim -voptargs="+acc" work.queue_tb
add wave *
run -all
