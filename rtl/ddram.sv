//
// ddram.v
// Copyright (c) 2017,2019 Sorgelig
//
//
// This source file is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version. 
//
// This source file is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of 
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License 
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
// ------------------------------------------
//

// 16-bit version

module ddram
(
	input         DDRAM_CLK,

	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	input  [27:1] wraddr,
	input  [15:0] din,
	input         we_req,
	output reg    we_ack,

	input  [27:1] rdaddr,
	output [15:0] dout,
	input  [15:0] rom_din,
	input   [1:0] rom_be,
	input         rom_we,
	input         rom_req,
	output reg    rom_ack,

	input  [27:1] rdaddr2,
	output [15:0] dout2,
	input         rd_req2,
	output reg    rd_ack2,

	// v1.6A private savestate transport channel. ss_addr is a 64-bit-word
	// offset from physical 0x3E000000. Request/ack are toggle handshakes.
	input  [21:0] ss_addr,
	input  [63:0] ss_din,
	input   [7:0] ss_be,
	input         ss_rnw,
	input         ss_req,
	output reg [63:0] ss_dout = 64'd0,
	output reg    ss_ack = 1'b0
);

assign DDRAM_BURSTCNT = ram_burst;
assign DDRAM_BE       = ram_be | {8{ram_read}};
assign DDRAM_ADDR     = {4'b0011, ram_address}; // RAM at 0x30000000
assign DDRAM_RD       = ram_read;
assign DDRAM_DIN      = ram_data;
assign DDRAM_WE       = ram_write;

assign dout  =  ram_q[{rdaddr[2:1],  4'b0000} +:16];
assign dout2 = ram_q2[{rdaddr2[2:1], 4'b0000} +:16]; 

reg  [7:0] ram_burst;
reg [63:0] ram_q, next_q, ram_q2, next_q2;
reg [63:0] ram_data;
reg [27:3] ram_address, cache_addr, cache_addr2;
reg        ram_read = 0;
reg        ram_write = 0;
reg  [7:0] ram_be = 0;

reg [2:0]  state  = 0;
reg        ch = 0;

// Synchronize the private request toggle into DDRAM_CLK. Existing ROM
// channels predate this project and retain their original handshake.
reg ss_req_meta = 1'b0;
reg ss_req_sync = 1'b0;
// Latch the token when taking ownership; never acknowledge a later request.
reg ss_token = 1'b0;
localparam [24:0] SS_BASE_QWORD = 25'h1C00000; // 0x3E000000/8 - 0x30000000/8

always @(posedge DDRAM_CLK) begin

	ss_req_meta <= ss_req;
	ss_req_sync <= ss_req_meta;

	// Capture a private read response regardless of BUSY.
	if((state == 3'd4) && DDRAM_DOUT_READY) begin
		ram_write     <= 0;
		ram_read      <= 0;
		ss_dout       <= DDRAM_DOUT;
		ss_ack        <= ss_token;
		state         <= 0;
	end
	// Never abandon an outstanding untagged read on timeout. The source
	// reports timeout and drains the handshake; this FSM retains ownership.
	else if(!DDRAM_BUSY || (((state == 2) || (state == 3)) && DDRAM_DOUT_READY)) begin
		// Keep asserted commands and their payload stable until acceptance.
		if(!DDRAM_BUSY) begin
			ram_write <= 0;
			ram_read  <= 0;
		end
		case(state)
			0: if(we_ack != we_req) begin
					ram_be      <= 8'd3<<{wraddr[2:1],1'b0};
					ram_data		<= {4{din}};
					ram_address <= wraddr[27:3];
					ram_write 	<= 1;
					ram_burst   <= 1;
					ch          <= 1;
					state       <= 1;
				end
				else if(rom_req != rom_ack) begin
					if(rom_we) begin
						ram_be      <= {6'd0,rom_be}<<{rdaddr[2:1],1'b0};
						ram_data		<= {4{rom_din}};
						ram_address <= rdaddr[27:3];
						ram_write 	<= 1;
						ram_burst   <= 1;
						ch          <= 0;
						state       <= 1;
					end
					else if(cache_addr == rdaddr[27:3]) rom_ack <= rom_req;
					else if((cache_addr+1'd1) == rdaddr[27:3]) begin
						rom_ack     <= rom_req;
						ram_q       <= next_q;
						cache_addr  <= rdaddr[27:3];
						ram_address <= rdaddr[27:3]+1'd1;
						ram_read    <= 1;
						ram_burst   <= 1;
						ch 			<= 0; 
						state       <= 3;
					end
					else begin
						ram_address <= rdaddr[27:3];
						cache_addr  <= rdaddr[27:3];
						ram_read    <= 1;
						ram_burst   <= 2;
						ch 			<= 0; 
						state       <= 2;
					end 
				end
				else if(ss_req_sync != ss_ack) begin
					ss_token   <= ss_req_sync;
					ram_address <= SS_BASE_QWORD + {{3{1'b0}},ss_addr};
					ram_burst   <= 1;
					if(ss_rnw) begin
						ram_read <= 1;
						state    <= 4;
					end
					else begin
						ram_be    <= ss_be;
						ram_data  <= ss_din;
						ram_write <= 1;
						state     <= 5;
					end
				end
				else if(rd_req2 != rd_ack2) begin
					if(cache_addr2 == rdaddr2[27:3]) rd_ack2 <= rd_req2;
					else if((cache_addr2+1'd1) == rdaddr2[27:3]) begin
						rd_ack2     <= rd_req2;
						ram_q2      <= next_q2;
						cache_addr2 <= rdaddr2[27:3];
						ram_address <= rdaddr2[27:3]+1'd1;
						ram_read    <= 1;
						ram_burst   <= 1;
						ch 			<= 1;
						state       <= 3;
					end
					else begin
						ram_address <= rdaddr2[27:3];
						cache_addr2 <= rdaddr2[27:3];
						ram_read    <= 1;
						ram_burst   <= 2;
						ch 			<= 1;
						state       <= 2;
					end 
				end 

			1: begin
					cache_addr  <= '1;
					cache_addr2 <= '1;
					cache_addr[3]  <= 0;
					cache_addr2[3] <= 0;
					if(ch) we_ack <= we_req;
					else rom_ack <= rom_req;
					state <= 0;
				end

			2: if(DDRAM_DOUT_READY) begin
					if (~ch) begin
						ram_q  <= DDRAM_DOUT;
						rom_ack <= rom_req;
					end
					else begin
						ram_q2  <= DDRAM_DOUT;
						rd_ack2 <= rd_req2;
					end 
					state <= 3;
				end

			3: if(DDRAM_DOUT_READY) begin
					if (~ch) begin
						next_q <= DDRAM_DOUT;
					end
					else begin
						next_q2 <= DDRAM_DOUT;
					end 
					state <= 0;
				end

			// v1.6A-r4 private savestate read wait. Completion is handled
			// above the DDRAM_BUSY gate so the one-cycle DOUT_READY pulse
			// cannot be lost while the controller reports BUSY.
			4: ;

			// The asserted write is accepted on this non-busy edge. Ack it and
			// invalidate ROM caches because the address space is physically shared.
			5: begin
					cache_addr  <= '1;
					cache_addr2 <= '1;
					cache_addr[3]  <= 0;
					cache_addr2[3] <= 0;
					ss_ack <= ss_token;
					state  <= 0;
				end
		endcase
	end
end

endmodule
