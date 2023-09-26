#!/usr/bin/bash

ghdl --version | head -n 1

# delete
rm -rf *.vcd &
rm -rf *.cf &

# analyze
ghdl -a skidbuffer.vhd
ghdl -a axis_enable.vhd
ghdl -a tb_axis_enable.vhd
# elaborate
ghdl -e skidbuffer
ghdl -e axis_enable
ghdl -e tb_axis_enable

# run
ghdl -r tb_axis_enable --vcd=wave.vcd --stop-time=1us
gtkwave wave.vcd waveform.gtkw

# delete
rm -rf *.vcd &
rm -rf *.cf &
