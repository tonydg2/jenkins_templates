
set lib crc_lib
set hdl_path "../hdl"

#**************************************************************************************************
# 
#**************************************************************************************************
proc cleanup {} {
  set fileDelete "work crc_lib"
  
  foreach fileDel $fileDelete {file delete -force $fileDel}
  
}
#**************************************************************************************************
# 
#**************************************************************************************************
proc sim_setup {} {
  upvar lib lib
  
  #file copy -force /opt/modelsim_65f/modeltech/modelsim.ini modelsim.ini
  if { [catch {exec vmap -c >@stdout} sout] } {	puts $sout }
  exec vlib $lib >@stdout
  exec vmap $lib $lib >@stdout
}

#**************************************************************************************************
# script start
#**************************************************************************************************
#testp

cleanup
sim_setup

#exec $vcom axi_pkg.vhd -work my_lib -2008 >@stdout

exec vcom -work $lib -2008 -explicit $hdl_path/generic_crc.vhd >@stdout
exec vcom -work $lib -2008 -explicit $hdl_path/generic_crc_tb.vhd >@stdout


#exec vsim -batch -do run.do > vsim.log
#exec vsim -batch -do run.do >@stdout

exec vsim -batch crc_lib.generic_crc_tb -t ns -voptargs=+acc -do run.do >@stdout
