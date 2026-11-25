set script_dir [file dirname [file normalize [info script]]]
cd $script_dir

vlib work
vlog -sv vga_timing.v vga_font.v vga_display.v vga_tb.v
vsim -voptargs="+acc" work.vga_tb
add wave *
run -all
