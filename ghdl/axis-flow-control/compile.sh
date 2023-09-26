#!/usr/bin/bash

ghdl --version | head -n 1

# delete
rm -rf *.vcd &
rm -rf *.cf &

# analyze
ghdl -a skidbuffer.vhd
ghdl -a axis_flow_control.vhd
ghdl -a tb_axis.vhd
# elaborate
ghdl -e skidbuffer
ghdl -e axis_flow_control
ghdl -e tb_axis

# run
ghdl -r tb_axis --vcd=wave.vcd --stop-time=1us
gtkwave wave.vcd waveform.gtkw

# delete
rm -rf *.vcd &
rm -rf *.cf &
