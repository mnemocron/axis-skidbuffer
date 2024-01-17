#!/usr/bin/bash

ghdl --version | head -n 1

# delete
rm -rf *.vcd &
rm -rf *.cf &

# analyze
ghdl -a ../basic/skidbuffer.vhd
ghdl -a ../axis/axis_pipeline.vhd
ghdl -a axi4_to_axis.vhd
ghdl -a tb_axi4_to_axis.vhd

# elaborate
ghdl -e tb_axi4_to_axis

# run
ghdl -r tb_axi4_to_axis --vcd=wave.vcd --stop-time=1us
gtkwave wave.vcd waveform.gtkw

# delete
rm -rf *.vcd &
rm -rf *.cf &
