onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /alu_trigger/reset_polarity_g
add wave -noupdate /alu_trigger/enable_polarity_g
add wave -noupdate /alu_trigger/signal_ram_depth_g
add wave -noupdate /alu_trigger/record_depth_g
add wave -noupdate /alu_trigger/Add_width_g
add wave -noupdate /alu_trigger/reset
add wave -noupdate /alu_trigger/enable
add wave -noupdate /alu_trigger/trigger_position
add wave -noupdate /alu_trigger/trigger_type
add wave -noupdate /alu_trigger/clk
add wave -noupdate /alu_trigger/trigger
add wave -noupdate /alu_trigger/trigger_found
add wave -noupdate -radix decimal /alu_trigger/addr_in_alu
add wave -noupdate /alu_trigger/start_array_row_in
add wave -noupdate -radix decimal -childformat {{/alu_trigger/wc_to_rc(15) -radix decimal} {/alu_trigger/wc_to_rc(14) -radix decimal} {/alu_trigger/wc_to_rc(13) -radix decimal} {/alu_trigger/wc_to_rc(12) -radix decimal} {/alu_trigger/wc_to_rc(11) -radix decimal} {/alu_trigger/wc_to_rc(10) -radix decimal} {/alu_trigger/wc_to_rc(9) -radix decimal} {/alu_trigger/wc_to_rc(8) -radix decimal} {/alu_trigger/wc_to_rc(7) -radix decimal} {/alu_trigger/wc_to_rc(6) -radix decimal} {/alu_trigger/wc_to_rc(5) -radix decimal} {/alu_trigger/wc_to_rc(4) -radix decimal} {/alu_trigger/wc_to_rc(3) -radix decimal} {/alu_trigger/wc_to_rc(2) -radix decimal} {/alu_trigger/wc_to_rc(1) -radix decimal} {/alu_trigger/wc_to_rc(0) -radix decimal}} -expand -subitemconfig {/alu_trigger/wc_to_rc(15) {-radix decimal} /alu_trigger/wc_to_rc(14) {-radix decimal} /alu_trigger/wc_to_rc(13) {-radix decimal} /alu_trigger/wc_to_rc(12) {-radix decimal} /alu_trigger/wc_to_rc(11) {-radix decimal} /alu_trigger/wc_to_rc(10) {-radix decimal} /alu_trigger/wc_to_rc(9) {-radix decimal} /alu_trigger/wc_to_rc(8) {-radix decimal} /alu_trigger/wc_to_rc(7) {-radix decimal} /alu_trigger/wc_to_rc(6) {-radix decimal} /alu_trigger/wc_to_rc(5) {-radix decimal} /alu_trigger/wc_to_rc(4) {-radix decimal} /alu_trigger/wc_to_rc(3) {-radix decimal} /alu_trigger/wc_to_rc(2) {-radix decimal} /alu_trigger/wc_to_rc(1) {-radix decimal} /alu_trigger/wc_to_rc(0) {-radix decimal}} /alu_trigger/wc_to_rc
add wave -noupdate /alu_trigger/start_array_row_out
add wave -noupdate /alu_trigger/end_array_row_out
add wave -noupdate /alu_trigger/time_since_trig_rise_s
add wave -noupdate /alu_trigger/reset
add wave -noupdate /alu_trigger/enable
add wave -noupdate /alu_trigger/trigger
add wave -noupdate /alu_trigger/trigger_position
add wave -noupdate /alu_trigger/trigger_type
add wave -noupdate -radix decimal /alu_trigger/addr_in_alu
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {197 ps} 0}
configure wave -namecolwidth 233
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {1587 ps}
view wave 
wave clipboard store
wave create -driver freeze -pattern random -initialvalue U -period 120ps -random_type Uniform -seed 5 -starttime 0ps -endtime 2000ps sim:/alu_trigger/trigger 
wave create -driver freeze -pattern random -initialvalue U -period 100ps -random_type Uniform -seed 5 -starttime 0ps -endtime 2000ps sim:/alu_trigger/trigger 
wave create -driver freeze -pattern constant -value 0 -starttime 0ps -endtime 2000ps sim:/alu_trigger/reset 
wave create -driver freeze -pattern constant -value 1 -starttime 0ps -endtime 2000ps sim:/alu_trigger/enable 
wave create -driver freeze -pattern repeater -initialvalue U -period 120ps -sequence { 0 1  } -repeat forever -starttime 0ps -endtime 2000ps sim:/alu_trigger/trigger 
wave create -driver freeze -pattern constant -value 0000000 -range 6 0 -starttime 0ps -endtime 2000ps sim:/alu_trigger/trigger_position 
WaveExpandAll -1
wave create -driver freeze -pattern constant -value 000 -range 2 0 -starttime 0ps -endtime 2000ps sim:/alu_trigger/trigger_type 
wave create -driver freeze -pattern counter -startvalue 00000000 -endvalue 00000111 -type Range -direction Up -period 100ps -step 1 -repeat forever -range 7 0 -starttime 0ps -endtime 2000ps sim:/alu_trigger/addr_in_alu 
wave create -driver freeze -pattern constant -value 000 -range 2 0 -starttime 0ps -endtime 2000ps sim:/alu_trigger/trigger_type 
WaveExpandAll -1
wave create -driver freeze -pattern random -initialvalue UUUUUUUU -period 50ps -random_type Uniform -seed 5 -range 7 0 -starttime 0ps -endtime 2000ps sim:/alu_trigger/addr_in_alu 
WaveExpandAll -1
wave modify -driver freeze -pattern counter -startvalue 00000000 -endvalue 00000111 -type Range -direction Up -period 200ps -step 1 -repeat forever -range 7 0 -starttime 0ps -endtime 2000ps Edit:/alu_trigger/addr_in_alu 
WaveCollapseAll -1
wave clipboard restore
