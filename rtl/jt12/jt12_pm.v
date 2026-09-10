/*  This file is part of jt12.

    jt12 is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    jt12 is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with jt12.  If not, see <http://www.gnu.org/licenses/>.
	
	Author: Jose Tejada Gomez. Twitter: @topapate
	Version: 1.0
	Date: 14-10-2018
	*/


// This implementation follows that of Alexey Khokholov (Nuke.YKT) in C language.

module jt12_pm (
	input [4:0] lfo_mod,
	input [10:0] fnum,
	input [2:0] pms,
	output reg signed [8:0] pm_offset
);


reg [7:0] pm_unsigned;
reg [7:0] pm_base;
reg [9:0] pm_shifted;

wire [2:0] index = lfo_mod[3] ? (~lfo_mod[2:0]) : lfo_mod[2:0];

reg [2:0] lfo_sh1, lfo_sh2;

function [2:0] lfo_sh1_lookup;
    input [5:0] address;
    begin
        case (address)
        6'h00: lfo_sh1_lookup = 3'd7;
        6'h01: lfo_sh1_lookup = 3'd7;
        6'h02: lfo_sh1_lookup = 3'd7;
        6'h03: lfo_sh1_lookup = 3'd7;
        6'h04: lfo_sh1_lookup = 3'd7;
        6'h05: lfo_sh1_lookup = 3'd7;
        6'h06: lfo_sh1_lookup = 3'd7;
        6'h07: lfo_sh1_lookup = 3'd7;
        6'h08: lfo_sh1_lookup = 3'd7;
        6'h09: lfo_sh1_lookup = 3'd7;
        6'h0A: lfo_sh1_lookup = 3'd7;
        6'h0B: lfo_sh1_lookup = 3'd7;
        6'h0C: lfo_sh1_lookup = 3'd7;
        6'h0D: lfo_sh1_lookup = 3'd7;
        6'h0E: lfo_sh1_lookup = 3'd7;
        6'h0F: lfo_sh1_lookup = 3'd7;
        6'h10: lfo_sh1_lookup = 3'd7;
        6'h11: lfo_sh1_lookup = 3'd7;
        6'h12: lfo_sh1_lookup = 3'd7;
        6'h13: lfo_sh1_lookup = 3'd7;
        6'h14: lfo_sh1_lookup = 3'd7;
        6'h15: lfo_sh1_lookup = 3'd7;
        6'h16: lfo_sh1_lookup = 3'd1;
        6'h17: lfo_sh1_lookup = 3'd1;
        6'h18: lfo_sh1_lookup = 3'd7;
        6'h19: lfo_sh1_lookup = 3'd7;
        6'h1A: lfo_sh1_lookup = 3'd7;
        6'h1B: lfo_sh1_lookup = 3'd7;
        6'h1C: lfo_sh1_lookup = 3'd1;
        6'h1D: lfo_sh1_lookup = 3'd1;
        6'h1E: lfo_sh1_lookup = 3'd1;
        6'h1F: lfo_sh1_lookup = 3'd1;
        6'h20: lfo_sh1_lookup = 3'd7;
        6'h21: lfo_sh1_lookup = 3'd7;
        6'h22: lfo_sh1_lookup = 3'd7;
        6'h23: lfo_sh1_lookup = 3'd1;
        6'h24: lfo_sh1_lookup = 3'd1;
        6'h25: lfo_sh1_lookup = 3'd1;
        6'h26: lfo_sh1_lookup = 3'd1;
        6'h27: lfo_sh1_lookup = 3'd0;
        6'h28: lfo_sh1_lookup = 3'd7;
        6'h29: lfo_sh1_lookup = 3'd7;
        6'h2A: lfo_sh1_lookup = 3'd1;
        6'h2B: lfo_sh1_lookup = 3'd1;
        6'h2C: lfo_sh1_lookup = 3'd0;
        6'h2D: lfo_sh1_lookup = 3'd0;
        6'h2E: lfo_sh1_lookup = 3'd0;
        6'h2F: lfo_sh1_lookup = 3'd0;
        6'h30: lfo_sh1_lookup = 3'd7;
        6'h31: lfo_sh1_lookup = 3'd7;
        6'h32: lfo_sh1_lookup = 3'd1;
        6'h33: lfo_sh1_lookup = 3'd1;
        6'h34: lfo_sh1_lookup = 3'd0;
        6'h35: lfo_sh1_lookup = 3'd0;
        6'h36: lfo_sh1_lookup = 3'd0;
        6'h37: lfo_sh1_lookup = 3'd0;
        6'h38: lfo_sh1_lookup = 3'd7;
        6'h39: lfo_sh1_lookup = 3'd7;
        6'h3A: lfo_sh1_lookup = 3'd1;
        6'h3B: lfo_sh1_lookup = 3'd1;
        6'h3C: lfo_sh1_lookup = 3'd0;
        6'h3D: lfo_sh1_lookup = 3'd0;
        6'h3E: lfo_sh1_lookup = 3'd0;
        6'h3F: lfo_sh1_lookup = 3'd0;
            default: lfo_sh1_lookup = 3'bxxx;
        endcase
    end
endfunction

function [2:0] lfo_sh2_lookup;
    input [5:0] address;
    begin
        case (address)
        6'h00: lfo_sh2_lookup = 3'd7;
        6'h01: lfo_sh2_lookup = 3'd7;
        6'h02: lfo_sh2_lookup = 3'd7;
        6'h03: lfo_sh2_lookup = 3'd7;
        6'h04: lfo_sh2_lookup = 3'd7;
        6'h05: lfo_sh2_lookup = 3'd7;
        6'h06: lfo_sh2_lookup = 3'd7;
        6'h07: lfo_sh2_lookup = 3'd7;
        6'h08: lfo_sh2_lookup = 3'd7;
        6'h09: lfo_sh2_lookup = 3'd7;
        6'h0A: lfo_sh2_lookup = 3'd7;
        6'h0B: lfo_sh2_lookup = 3'd7;
        6'h0C: lfo_sh2_lookup = 3'd2;
        6'h0D: lfo_sh2_lookup = 3'd2;
        6'h0E: lfo_sh2_lookup = 3'd2;
        6'h0F: lfo_sh2_lookup = 3'd2;
        6'h10: lfo_sh2_lookup = 3'd7;
        6'h11: lfo_sh2_lookup = 3'd7;
        6'h12: lfo_sh2_lookup = 3'd7;
        6'h13: lfo_sh2_lookup = 3'd2;
        6'h14: lfo_sh2_lookup = 3'd2;
        6'h15: lfo_sh2_lookup = 3'd2;
        6'h16: lfo_sh2_lookup = 3'd7;
        6'h17: lfo_sh2_lookup = 3'd7;
        6'h18: lfo_sh2_lookup = 3'd7;
        6'h19: lfo_sh2_lookup = 3'd7;
        6'h1A: lfo_sh2_lookup = 3'd2;
        6'h1B: lfo_sh2_lookup = 3'd2;
        6'h1C: lfo_sh2_lookup = 3'd7;
        6'h1D: lfo_sh2_lookup = 3'd7;
        6'h1E: lfo_sh2_lookup = 3'd2;
        6'h1F: lfo_sh2_lookup = 3'd2;
        6'h20: lfo_sh2_lookup = 3'd7;
        6'h21: lfo_sh2_lookup = 3'd7;
        6'h22: lfo_sh2_lookup = 3'd2;
        6'h23: lfo_sh2_lookup = 3'd7;
        6'h24: lfo_sh2_lookup = 3'd7;
        6'h25: lfo_sh2_lookup = 3'd7;
        6'h26: lfo_sh2_lookup = 3'd2;
        6'h27: lfo_sh2_lookup = 3'd7;
        6'h28: lfo_sh2_lookup = 3'd7;
        6'h29: lfo_sh2_lookup = 3'd7;
        6'h2A: lfo_sh2_lookup = 3'd7;
        6'h2B: lfo_sh2_lookup = 3'd2;
        6'h2C: lfo_sh2_lookup = 3'd7;
        6'h2D: lfo_sh2_lookup = 3'd7;
        6'h2E: lfo_sh2_lookup = 3'd2;
        6'h2F: lfo_sh2_lookup = 3'd1;
        6'h30: lfo_sh2_lookup = 3'd7;
        6'h31: lfo_sh2_lookup = 3'd7;
        6'h32: lfo_sh2_lookup = 3'd7;
        6'h33: lfo_sh2_lookup = 3'd2;
        6'h34: lfo_sh2_lookup = 3'd7;
        6'h35: lfo_sh2_lookup = 3'd7;
        6'h36: lfo_sh2_lookup = 3'd2;
        6'h37: lfo_sh2_lookup = 3'd1;
        6'h38: lfo_sh2_lookup = 3'd7;
        6'h39: lfo_sh2_lookup = 3'd7;
        6'h3A: lfo_sh2_lookup = 3'd7;
        6'h3B: lfo_sh2_lookup = 3'd2;
        6'h3C: lfo_sh2_lookup = 3'd7;
        6'h3D: lfo_sh2_lookup = 3'd7;
        6'h3E: lfo_sh2_lookup = 3'd2;
        6'h3F: lfo_sh2_lookup = 3'd1;
            default: lfo_sh2_lookup = 3'bxxx;
        endcase
    end
endfunction

always @(*) begin
	lfo_sh1 = lfo_sh1_lookup({pms,index});
	lfo_sh2 = lfo_sh2_lookup({pms,index});
	pm_base = ({1'b0,fnum[10:4]}>>lfo_sh1) + ({1'b0,fnum[10:4]}>>lfo_sh2);
	case( pms )
		default: pm_shifted = { 2'b0, pm_base };
		3'd6: pm_shifted = { 1'b0, pm_base, 1'b0 };
		3'd7: pm_shifted = {       pm_base, 2'b0 };
	endcase // pms
	pm_offset = lfo_mod[4] ? (-{1'b0,pm_shifted[9:2]}) : {1'b0,pm_shifted[9:2]};
end // always @(*)

endmodule
