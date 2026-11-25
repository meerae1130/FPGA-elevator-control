set script_dir [file dirname [file normalize [info script]]]
cd $script_dir

vlib work
vlog -sv math.v random.v math_tb.v
vsim -voptargs="+acc" work.math_tb
add wave *
run -all
