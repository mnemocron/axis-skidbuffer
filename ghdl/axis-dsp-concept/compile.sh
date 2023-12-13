#!/usr/bin/bash

ghdl --version | head -n 1

# delete
rm -rf *.vcd &
rm -rf *.cf &

# analyze
ghdl -a skidbuffer.vhd
ghdl -a axis_my_dsp.vhd
ghdl -a tb_axis_my_dsp.vhd

# elaborate
ghdl -e skidbuffer
ghdl -e axis_my_dsp
ghdl -e -fsynopsys tb_axis_my_dsp

# run
ghdl -r -fsynopsys tb_axis_my_dsp --vcd=wave.vcd --stop-time=10us
gtkwave wave.vcd waveform.gtkw

# delete
rm -rf *.vcd &
rm -rf *.cf &
