#!/usr/bin/bash

ghdl --version | head -n 1

# delete
rm -rf *.vcd &
rm -rf *.cf &

# analyze
ghdl -a skidbuffer.vhd
ghdl -a tb_skid.vhd

# elaborate
ghdl -e skidbuffer
ghdl -e tb_skid

# run
ghdl -r tb_skid --vcd=wave.vcd --stop-time=1us
gtkwave wave.vcd waveform.gtkw

# delete
rm -rf *.vcd &
rm -rf *.cf &
