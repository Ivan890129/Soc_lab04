// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_proj_example
 *
 * This is an example of a (trivially simple) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "mprj_counter" for the
 * example programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */

module user_proj_example #(
    parameter BITS = 32,
    parameter DELAYS=10
)(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // IRQ
    output [2:0] irq
);
    wire clk;
    wire rst;

    wire [`MPRJ_IO_PADS-1:0] io_in;
    wire [`MPRJ_IO_PADS-1:0] io_out;
    wire [`MPRJ_IO_PADS-1:0] io_oeb;

    

    bram user_bram (
        .CLK(clk),
        .WE0(),
        .EN0(),
        .Di0(),
        .Do0(),
        .A0()
    );

endmodule


    wire wbs_ack_o_bram;
    wire wbs_dat_o_bram;

    Wish2bram u0 (
         .wb_clk_i(wb_clk_i),
         .wb_rst_i(wb_rst_i),
         .wbs_stb_i(wbs_stb_i),
         .wbs_cyc_i(wbs_cyc_i),
         .wbs_we_i(wbs_we_i),
         .wbs_sel_i(wbs_sel_i),
         .wbs_dat_i(wbs_dat_i),
         .wbs_adr_i(wbs_adr_i),
         .wbs_ack_o(wbs_ack_o_bram),
         .wbs_dat_o(wbs_dat_o_bram)

    );








module Wish2bram #(
    parameter BITS = 32,
    parameter DELAYS=10
)(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // IRQ
    output [2:0] irq
);


    wire clk;
    wire rst;

    wire [`MPRJ_IO_PADS-1:0] io_in;
    wire [`MPRJ_IO_PADS-1:0] io_out;
    wire [`MPRJ_IO_PADS-1:0] io_oeb;

    // output 
    assign wbs_ack_o = ack_reg;
    assign wbs_dat_o = wbs_dat_o_reg;


    reg ack_reg ;
    reg  [31:0] wbs_dat_o_reg;
    reg  [3:0] counter ; 

    // bram //
    wire  en ;
    wire [31:0]Do;
    wire [31:0] A;
    wire [3:0] wen = (wbs_we_i)?wbs_sel_i: 0 ;
    wire [31:0] Di = wbs_dat_i;
    assign  A[31:0] = {10'h0,wbs_adr_i[23:2]};
    assign en = wbs_stb_i && wbs_cyc_i && (wbs_adr_i[31:24]==8'h38);
  
    // output // 
    assign wbs_ack_o = ack_reg ;
    assign wbs_dat_o = wbs_dat_o_reg ; 
    assign la_data_out =  {{(127-BITS){1'b0}},wbs_dat_o_reg};

    always@(posedge wb_clk_i or posedge wb_rst_i )begin 
        if(wb_rst_i)
            counter <= 0;
        else
            if(ack_reg)
                counter <= 0;
            else if(en)
                counter <=  counter +1;
            else
                counter <=  counter;
    end 
    always@(posedge wb_clk_i or posedge wb_rst_i )begin 
        if(wb_rst_i)
            wbs_dat_o_reg <= 0;
        else
            if(counter == DELAYS)
                wbs_dat_o_reg <= Do;
            else
                wbs_dat_o_reg <=  0;
    end 

    always@(posedge wb_clk_i or posedge wb_rst_i )begin 
        if(wb_rst_i)
            ack_reg <= 0;
        else
            if(counter == DELAYS)
                ack_reg <= 1;
            else
                ack_reg <=  0;
    end 



    bram user_bram (
        .CLK(wb_clk_i),
        .WE0(wen),
        .EN0(en),
        .Di0(Di),
        .Do0(Do),
        .A0(A)
    );

endmodule


`default_nettype wire
