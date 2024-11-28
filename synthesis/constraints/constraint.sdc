set sdc_version 1.7

set_units -capacitance 1pF
set_units -time 1ns

current_design seq

create_clock -name "clk" -period 3 -waveform {0 1.5} [get_ports "clk"]
set_input_delay -max 0.15 [all_inputs] -clock [get_clocks "clk"]
set_output_delay -max 0.15 [all_outputs] -clock [get_clocks "clk"]

set_max_capacitance 6 [all_inputs]
set_max_fanout 32 [all_inputs]

set_clock_latency -source 0.15 [get_clocks "clk"]
set_clock_uncertainty 0.015 [get_clocks "clk"]
