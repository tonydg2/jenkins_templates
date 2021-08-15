


# simulate
#vsim -batch crc_lib.generic_crc_tb -t ns -voptargs=+acc 

# log all signals
log -r /*

#do wave.do ;# not in batch mode!

run 1 us

exit