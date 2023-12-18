#!/usr/bin/bash

ghdl --version | head -n 1

# delete
rm -rf *.vcd &
rm -rf *.cf &

# analyze
ghdl -a ../basic/skidbuffer.vhd
ghdl -a axis_pipeline.vhd
ghdl -a tb_axis.vhd

# elaborate
ghdl -e axis_pipeline
ghdl -e tb_axis

# run
ghdl -r tb_axis --vcd=wave.vcd --stop-time=1us
gtkwave wave.vcd waveform.gtkw

# delete
rm -rf *.vcd &
rm -rf *.cf &
