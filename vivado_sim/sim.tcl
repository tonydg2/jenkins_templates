# tclsh sim.tcl
###@#
# clean up log file etc., before run. Deletes everything including compile dir.
proc cleanup {} {
  file delete -force {*}[glob -nocomplain xsim*]
  file delete -force {*}[glob -nocomplain webtalk*]
  file delete -force {*}[glob -nocomplain *.log]
  file delete -force {*}[glob -nocomplain *.jou]
  file delete -force {*}[glob -nocomplain xelab.*]
  file delete -force {*}[glob -nocomplain xvhdl.*]
}

cleanup
#exit

exec xvhdl -relax -work crc_lib ../hdl/generic_crc.vhd >@stdout
exec xvhdl -relax -work crc_lib ../hdl/generic_crc_tb.vhd >@stdout
exec xelab -relax crc_lib.generic_crc_tb -s crc_snap >@stdout
exec xsim -R crc_snap -wdb wave.wdb >@stdout
