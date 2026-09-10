// Genesis_MiSTer Save-State project
// R55 corrected r5 - external DDR transport isolation diagnostic.
//
// IMPORTANT: this checkpoint intentionally does NOT run the full v1.5
// snapshot/orchestrator pipeline. Previous r3/r4 hardware tests could hang
// while the CPUs were held, which made it impossible to distinguish a raw
// DDR transport failure from a long-hold/orchestrator interaction.
//
// r5 therefore performs 256 write -> read -> compare transactions through
// the exact same private DDR channel while the game keeps running. If this
// passes repeatedly, it validates only the exercised address and load.
// It cannot exclude transport faults during a full export.
//
// DDR location used by this diagnostic:
//   physical 0x3E000000, first reserved 64-bit word.
// No SS... CONF_STR is exposed.

module ss_persistent_export
(
    input  wire         clk,
    input  wire         reset,
    input  wire         start,

    output reg          orch_start,
    output wire         orch_persistent_enable,
    input  wire         orch_persistent_ready,
    output reg          orch_persistent_done,
    output reg          orch_persistent_failed,
    input  wire         orch_busy,
    input  wire         orch_pass,
    input  wire         orch_fail,

    output wire         mem_active,
    output reg  [17:0]  mem_addr,
    input  wire [7:0]   mem_dout,

    output reg          ddr_req = 1'b0,
    output reg          ddr_rnw = 1'b0,
    output reg  [21:0]  ddr_addr = 22'd0,
    output reg  [63:0]  ddr_din = 64'd0,
    output reg  [7:0]   ddr_be = 8'hFF,
    input  wire [63:0]  ddr_dout,
    input  wire         ddr_ack,

    output reg          busy,
    output reg          pass,
    output reg          fail,
    output reg  [31:0]  source_crc,
    output reg  [31:0]  ddr_crc
);

localparam [2:0]
    ST_IDLE       = 3'd0,
    ST_WRITE_WAIT = 3'd1,
    ST_READ_WAIT  = 3'd2,
    ST_DONE       = 3'd3,
    ST_DRAIN      = 3'd4;

// A normal private DDR transaction should finish orders of magnitude sooner.
// At ~53.7 MHz this is ~312 ms, deliberately generous so a timeout indicates
// a real lost/stalled handshake rather than ordinary DDR arbitration latency.
localparam [23:0] WAIT_TIMEOUT = 24'hFFFFFF;
localparam [7:0]  LAST_PING    = 8'hFF;

reg [2:0]  state = ST_IDLE;
reg        armed = 1'b0;
reg [7:0]  ping_index;
reg [23:0] wait_count;
reg [63:0] expected_word;

reg ddr_ack_meta = 1'b0;
reg ddr_ack_sync = 1'b0;
always @(posedge clk) begin
    ddr_ack_meta <= ddr_ack;
    ddr_ack_sync <= ddr_ack_meta;
end

// r5 isolation checkpoint: the proven v1.5 orchestrator and SS memory port
// are deliberately kept completely out of the transaction.
assign orch_persistent_enable = 1'b0;
assign mem_active             = 1'b0;

function automatic [63:0] ping_pattern(input [7:0] n);
begin
    // "SSDDR5" marker plus index and complement makes stuck/lane errors easy
    // to distinguish from a successful round trip in simulation/debug probes.
    ping_pattern = {48'h535344445235, n, ~n};
end
endfunction

always @(posedge clk) begin
    orch_start             <= 1'b0;
    orch_persistent_done   <= 1'b0;
    orch_persistent_failed <= 1'b0;

    if (reset) begin
        state         <= ST_DRAIN;
        armed         <= 1'b0;
        ping_index    <= 8'd0;
        wait_count    <= 24'd0;
        expected_word <= 64'd0;
        mem_addr      <= 18'd0;
        busy          <= (ddr_req != ddr_ack_sync);
        pass          <= 1'b0;
        fail          <= 1'b0;
        source_crc    <= 32'd0;
        ddr_crc       <= 32'd0;
    end
    else begin
        if (!start)
            armed <= 1'b1;

        case (state)
            ST_IDLE: begin
                busy       <= 1'b0;
                wait_count <= 24'd0;
                // Reset and timeout drain the existing toggle; never realign it.

                if (start && armed && (ddr_req == ddr_ack_sync)) begin
                    armed         <= 1'b0;
                    busy          <= 1'b1;
                    pass          <= 1'b0;
                    fail          <= 1'b0;
                    ping_index    <= 8'd0;
                    expected_word <= ping_pattern(8'd0);
                    source_crc    <= {16'h5235, 8'h00, 8'hFF};
                    ddr_crc       <= 32'd0;

                    ddr_rnw  <= 1'b0;
                    ddr_addr <= 22'd0; // physical 0x3E000000, reserved header
                    ddr_din  <= ping_pattern(8'd0);
                    ddr_be   <= 8'hFF;
                    ddr_req  <= ~ddr_req;
                    state    <= ST_WRITE_WAIT;
                end
            end

            ST_WRITE_WAIT: begin
                if (ddr_ack_sync == ddr_req) begin
                    wait_count <= 24'd0;
                    ddr_rnw    <= 1'b1;
                    ddr_addr   <= 22'd0;
                    ddr_be     <= 8'hFF;
                    ddr_req    <= ~ddr_req;
                    state      <= ST_READ_WAIT;
                end
                else if (wait_count == WAIT_TIMEOUT) begin
                    busy  <= 1'b1;
                    pass  <= 1'b0;
                    fail  <= 1'b1;
                    state <= ST_DRAIN;
                end
                else begin
                    wait_count <= wait_count + 1'b1;
                end
            end

            ST_READ_WAIT: begin
                if (ddr_ack_sync == ddr_req) begin
                    wait_count <= 24'd0;
                    ddr_crc    <= ddr_dout[31:0];

                    if (ddr_dout != expected_word) begin
                        busy  <= 1'b0;
                        pass  <= 1'b0;
                        fail  <= 1'b1;
                        state <= ST_DONE;
                    end
                    else if (ping_index == LAST_PING) begin
                        busy  <= 1'b0;
                        pass  <= 1'b1;
                        fail  <= 1'b0;
                        state <= ST_DONE;
                    end
                    else begin
                        ping_index    <= ping_index + 1'b1;
                        expected_word <= ping_pattern(ping_index + 1'b1);
                        source_crc    <= {16'h5235, (ping_index + 8'd1), ~(ping_index + 8'd1)};
                        ddr_rnw       <= 1'b0;
                        ddr_addr      <= 22'd0;
                        ddr_din       <= ping_pattern(ping_index + 1'b1);
                        ddr_be        <= 8'hFF;
                        ddr_req       <= ~ddr_req;
                        state         <= ST_WRITE_WAIT;
                    end
                end
                else if (wait_count == WAIT_TIMEOUT) begin
                    busy  <= 1'b1;
                    pass  <= 1'b0;
                    fail  <= 1'b1;
                    state <= ST_DRAIN;
                end
                else begin
                    wait_count <= wait_count + 1'b1;
                end
            end

            // Timeout/reset never cancel a request or change its bundled payload.
            // Keep draining even if the user toggles the menu or resets the game.
            ST_DRAIN: begin
                busy <= (ddr_req != ddr_ack_sync);
                if (ddr_req == ddr_ack_sync)
                    state <= ST_DONE;
            end

            ST_DONE: begin
                busy <= 1'b0;
                if (!start) begin
                    pass <= 1'b0;
                    state <= ST_IDLE;
                end
            end

            default: begin
                busy  <= (ddr_req != ddr_ack_sync);
                pass  <= 1'b0;
                fail  <= 1'b1;
                state <= ST_DRAIN;
            end
        endcase
    end
end

endmodule
