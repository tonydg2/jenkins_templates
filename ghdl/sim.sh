echo "GHDL script start"

ghdl -a --std=08 --work=crc_lib ../hdl/generic_crc.vhd 
ghdl -a --std=08 --work=crc_lib ../hdl/generic_crc_tb.vhd 

ghdl -e --std=08 --work=crc_lib generic_crc_tb

ghdl -r --std=08 --work=crc_lib generic_crc_tb
