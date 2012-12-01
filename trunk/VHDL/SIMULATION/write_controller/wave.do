onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /alu_data/reset_polarity_g
add wave -noupdate /alu_data/signal_ram_depth_g
add wave -noupdate /alu_data/signal_ram_width_g
add wave -noupdate /alu_data/record_depth_g
add wave -noupdate /alu_data/Add_width_g
add wave -noupdate /alu_data/num_of_signals_g
add wave -noupdate /alu_data/clk
add wave -noupdate /alu_data/reset
add wave -noupdate /alu_data/data_in
add wave -noupdate /alu_data/addr_in_alu
add wave -noupdate /alu_data/aout_valid_alu
add wave -noupdate /alu_data/data_in_RAM
add wave -noupdate /alu_data/current_addr_row_s
add wave -noupdate /alu_data/current_array_row_s
add wave -noupdate /alu_data/current_array_col_s
add wave -noupdate /alu_data/ram_array_row_c
add wave -noupdate /alu_data/ram_array_column_c
add wave -noupdate /alu_data/data_in
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
configure wave -namecolwidth 226
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
WaveRestoreZoom {0 ps} {854 ps}
view wave 
wave clipboard store
wave create -driver freeze -pattern random -initialvalue UUUUUUUUU -period 100ps -random_type Uniform -seed 5 -range 8 0 -starttime 10ps -endtime 1000ps sim:/alu_data/data_in 
WaveExpandAll -1
WaveCollapseAll -1
wave clipboard restore
