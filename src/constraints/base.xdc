# IIC
set_property -dict {PACKAGE_PIN U9 IOSTANDARD LVCMOS33} [get_ports audio_i2c_scl_io]
set_property PULLUP true [get_ports audio_i2c_scl_io];
set_property -dict {PACKAGE_PIN T9 IOSTANDARD LVCMOS33} [get_ports audio_i2c_sda_io]
set_property PULLUP true [get_ports audio_i2c_sda_io];

# I2S
set_property -dict { PACKAGE_PIN U5   IOSTANDARD LVCMOS33 } [get_ports audio_clk_10mhz];
create_clock -name mclk -period 10 [get_ports audio_clk_10mhz];
set_property -dict { PACKAGE_PIN R18   IOSTANDARD LVCMOS33 } [get_ports bclk];
set_property -dict { PACKAGE_PIN T17   IOSTANDARD LVCMOS33 } [get_ports lrclk];
set_property -dict { PACKAGE_PIN G18   IOSTANDARD LVCMOS33 } [get_ports sdata_o];
set_property -dict { PACKAGE_PIN F17   IOSTANDARD LVCMOS33 } [get_ports sdata_i];
set_property -dict { PACKAGE_PIN M17   IOSTANDARD LVCMOS33 } [get_ports {codec_addr[0]}];
set_property -dict { PACKAGE_PIN M18   IOSTANDARD LVCMOS33 } [get_ports {codec_addr[1]}];

# switches
set_property -dict {PACKAGE_PIN M20 IOSTANDARD LVCMOS33} [get_ports {sw[0]}];
set_property -dict {PACKAGE_PIN M19 IOSTANDARD LVCMOS33} [get_ports {sw[1]}];

# debug on PMODA [3:0]
set_property -dict {PACKAGE_PIN Y19 IOSTANDARD LVCMOS33} [get_ports {i2s_data[1]}];
set_property -dict {PACKAGE_PIN Y18 IOSTANDARD LVCMOS33} [get_ports {i2s_data[0]}];
set_property -dict {PACKAGE_PIN Y17 IOSTANDARD LVCMOS33} [get_ports {i2s_data[3]}];
set_property -dict {PACKAGE_PIN Y16 IOSTANDARD LVCMOS33} [get_ports {i2s_data[2]}];

