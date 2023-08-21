//Copyright (C)2014-2023 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//GOWIN Version: V1.9.9 Beta-2
//Part Number: GW1NR-LV9QN88PC6/I5
//Device: GW1NR-9
//Device Version: C
//Created Time: Thu Aug 17 10:11:49 2023

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

    Gowin_rPLL your_instance_name(
        .clkout(clkout_o), //output clkout
        .clkoutp(clkoutp_o), //output clkoutp
        .clkin(clkin_i) //input clkin
    );

//--------Copy end-------------------
