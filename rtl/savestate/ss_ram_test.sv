// Genesis_MiSTer Save-State project
// v0.4 - non-destructive round-trip test for all major RAM/state-memory ports.
//
// Test addresses:
//   68K RAM byte
//   Z80 RAM byte
//   VRAM byte
//   CRAM low byte
//   CRAM high bit
//   VSRAM0 low byte
//   VSRAM0 high 3 bits
//   VSRAM1 low byte
//   VSRAM1 high 3 bits
//
// The whole test executes under the existing save-state freeze request.
// Every changed value is restored before freeze is released.

module ss_ram_test
(
    input  wire        clk,
    input  wire        reset,
    input  wire        start,

    output reg         freeze_req,
    input  wire        freeze_ack,

    output reg  [17:0] mem_addr,
    output reg   [7:0] mem_din,
    input  wire  [7:0] mem_dout,
    output reg         mem_we,

    output reg         busy,
    output reg         pass,
    output reg         fail
);

localparam [3:0] TEST_LAST = 4'd8;

function automatic [17:0] test_addr(input [3:0] n);
begin
    case (n)
        4'd0: test_addr = 18'h01234; // 68K RAM
        4'd1: test_addr = 18'h10555; // Z80 RAM
        4'd2: test_addr = 18'h21234; // VRAM byte
        4'd3: test_addr = 18'h30020; // CRAM entry 0x10 low byte
        4'd4: test_addr = 18'h30021; // CRAM entry 0x10 high bit
        4'd5: test_addr = 18'h30110; // VSRAM0 entry 0x08 low byte
        4'd6: test_addr = 18'h30111; // VSRAM0 entry 0x08 high 3 bits
        4'd7: test_addr = 18'h30210; // VSRAM1 entry 0x08 low byte
        default: test_addr = 18'h30211; // VSRAM1 entry 0x08 high 3 bits
    endcase
end
endfunction

function automatic [7:0] test_mask(input [3:0] n);
begin
    case (n)
        4'd4: test_mask = 8'h01; // CRAM is 9-bit
        4'd6,
        4'd8: test_mask = 8'h07; // VSRAM is 11-bit
        default: test_mask = 8'hFF;
    endcase
end
endfunction

localparam [4:0]
    ST_IDLE          = 0,
    ST_WAIT_FREEZE   = 1,
    ST_SET_ADDR      = 2,
    ST_WAIT_ADDR1    = 3,
    ST_WAIT_ADDR2    = 4,
    ST_CAPTURE       = 5,
    ST_WRITE_INV     = 6,
    ST_INV_WAIT1     = 7,
    ST_INV_WAIT2     = 8,
    ST_VERIFY_INV    = 9,
    ST_WRITE_ORIG    = 10,
    ST_ORIG_WAIT1    = 11,
    ST_ORIG_WAIT2    = 12,
    ST_VERIFY_ORIG   = 13,
    ST_NEXT          = 14,
    ST_DONE          = 15;

reg [4:0] state;
reg [3:0] test_no;
reg       armed;
reg       failed;
reg [7:0] orig;
reg [7:0] expected_inv;

always @(posedge clk) begin
    if (reset) begin
        state        <= ST_IDLE;
        test_no      <= 4'd0;
        armed        <= 1'b1;
        failed       <= 1'b0;
        orig         <= 8'd0;
        expected_inv <= 8'd0;

        freeze_req   <= 1'b0;
        mem_addr     <= 18'd0;
        mem_din      <= 8'd0;
        mem_we       <= 1'b0;

        busy         <= 1'b0;
        pass         <= 1'b0;
        fail         <= 1'b0;
    end
    else begin
        mem_we <= 1'b0;

        if (!start)
            armed <= 1'b1;

        case (state)
            ST_IDLE: begin
                freeze_req <= 1'b0;
                busy       <= 1'b0;

                if (start && armed) begin
                    armed      <= 1'b0;
                    failed     <= 1'b0;
                    pass       <= 1'b0;
                    fail       <= 1'b0;
                    busy       <= 1'b1;
                    test_no    <= 4'd0;
                    freeze_req <= 1'b1;
                    state      <= ST_WAIT_FREEZE;
                end
            end

            ST_WAIT_FREEZE: begin
                if (freeze_ack) begin
                    mem_addr <= test_addr(4'd0);
                    state    <= ST_SET_ADDR;
                end
            end

            // The inferred block RAMs are synchronous. Give the selected
            // port/address time to propagate before sampling q.
            ST_SET_ADDR:   state <= ST_WAIT_ADDR1;
            ST_WAIT_ADDR1: state <= ST_WAIT_ADDR2;
            ST_WAIT_ADDR2: state <= ST_CAPTURE;

            ST_CAPTURE: begin
                orig         <= mem_dout;
                expected_inv <= (~mem_dout) & test_mask(test_no);
                mem_din      <= (~mem_dout) & test_mask(test_no);
                mem_we       <= 1'b1;
                state        <= ST_WRITE_INV;
            end

            // mem_we asserted in the previous cycle is observed by the RAM here.
            ST_WRITE_INV: begin
                mem_we <= 1'b0;
                state  <= ST_INV_WAIT1;
            end
            ST_INV_WAIT1: state <= ST_INV_WAIT2;
            ST_INV_WAIT2: state <= ST_VERIFY_INV;

            ST_VERIFY_INV: begin
                if ((mem_dout & test_mask(test_no)) != expected_inv)
                    failed <= 1'b1;

                mem_din <= orig;
                mem_we  <= 1'b1;
                state   <= ST_WRITE_ORIG;
            end

            ST_WRITE_ORIG: begin
                mem_we <= 1'b0;
                state  <= ST_ORIG_WAIT1;
            end
            ST_ORIG_WAIT1: state <= ST_ORIG_WAIT2;
            ST_ORIG_WAIT2: state <= ST_VERIFY_ORIG;

            ST_VERIFY_ORIG: begin
                if ((mem_dout & test_mask(test_no)) != (orig & test_mask(test_no)))
                    failed <= 1'b1;

                state <= ST_NEXT;
            end

            ST_NEXT: begin
                if (test_no == TEST_LAST) begin
                    freeze_req <= 1'b0;
                    busy       <= 1'b0;

                    if (failed) begin
                        pass <= 1'b0;
                        fail <= 1'b1;
                    end
                    else begin
                        pass <= 1'b1;
                        fail <= 1'b0;
                    end

                    state <= ST_DONE;
                end
                else begin
                    test_no  <= test_no + 1'b1;
                    mem_addr <= test_addr(test_no + 1'b1);
                    state    <= ST_SET_ADDR;
                end
            end

            ST_DONE: begin
                // Keep PASS/FAIL latched while the OSD switch is On.
                if (!start)
                    state <= ST_IDLE;
            end

            default: state <= ST_IDLE;
        endcase
    end
end

endmodule
