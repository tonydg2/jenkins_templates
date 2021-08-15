
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

# exec vcom -work $lib -2008 -explicit $hdl_path/generic_crc.vhd >@stdout
# exec vcom -work $lib -2008 -explicit $hdl_path/generic_crc_tb.vhd >@stdout

if { [catch {exec vcom -work $lib -2008 -explicit $hdl_path/generic_crc.vhd >@stdout}] } {
  exit 1
}

if { [catch {exec vcom -work $lib -2008 -explicit $hdl_path/generic_crc_tb.vhd >@stdout}] } {
  exit 1
}

exit 0