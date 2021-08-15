
# exec vsim -batch crc_lib.generic_crc_tb -t ns -voptargs=+acc -do run.do >@stdout 

# use 'tee' command in linux to direct output to file AND stdout 

if { [catch {exec vsim -batch crc_lib.generic_crc_tb -t ns -voptargs=+acc -do run.do > sim.log} catchErrVar] } {
  puts $catchErrVar
  exit 1
}

set fid [open sim.log r]
set file_data [read $fid]
#exit [regex "Failure:" $file_data] ;# linux
puts $file_data
set fs [string first "Failure:" $file_data]
if {$fs == -1} {
  exit 0 ;# did not find "Failure:", so exit normally
} else {
  exit 1 ;# found "Failure:", so exit with error
}

