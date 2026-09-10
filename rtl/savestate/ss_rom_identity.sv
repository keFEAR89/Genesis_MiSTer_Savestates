// ROM identity for persistent states. Process one byte per clock to bound CRC depth.
// hps_io WIDE=1 produces isolated word strobes; reject overlapping/nonlinear input.
module ss_rom_identity (
    input wire clk, download, wr,
    input wire [24:0] addr,
    input wire [15:0] data,
    output wire [63:0] identity,
    output reg ready = 0
);
reg old_download = 0, pending = 0, invalid = 0;
reg [7:0] high_byte = 0;
reg [31:0] crc = 32'hFFFFFFFF;
reg [25:0] length = 0;
function automatic [31:0] crc_byte(input [31:0] c_in, input [7:0] b);
    reg [31:0] c;
    integer i;
    begin
        c = c_in ^ {24'd0,b};
        for (i=0;i<8;i=i+1) c = c[0] ? (c>>1)^32'hEDB88320 : c>>1;
        crc_byte = c;
    end
endfunction
assign identity = {6'd0,length,~crc};
always @(posedge clk) begin
    old_download <= download;
    if (download && !old_download) begin
        ready <= 0; invalid <= 0; crc <= 32'hFFFFFFFF; length <= 0; pending <= 0;
    end
    if (pending) begin crc <= crc_byte(crc,high_byte); pending <= 0; end
    if (download && wr) begin
        if (pending || (old_download && {1'b0,addr} != length) || (!old_download && addr != 0)) invalid <= 1;
        crc <= crc_byte(old_download ? crc : 32'hFFFFFFFF,data[7:0]);
        high_byte <= data[15:8]; pending <= 1;
        length <= {1'b0,addr} + 26'd2;
    end
    if (!download && !pending && length != 0 && !invalid) ready <= 1;
end
endmodule
