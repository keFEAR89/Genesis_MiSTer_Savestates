// Genesis_MiSTer Save-State project
// v0.5 - Z80 state round-trip diagnostic.
//
// The T80 snapshot is captured on the exact clean opcode-fetch boundary
// accepted by the global freeze controller. After freeze ACK:
//   restore captured state -> verify full 230-bit image
//   mutate A[0], WZ[0], Alternate, Halt -> verify
//   restore captured state -> verify
//   release freeze
//
// The CPU never executes while the mutated state is installed.

module ss_z80_state_test
(
    input  wire         clk,
    input  wire         reset,
    input  wire         start,

    output reg          freeze_req,
    input  wire         freeze_capture,
    input  wire         freeze_ack,

    input  wire [229:0] z80_reg,
    output reg  [229:0] z80_dir,
    output reg          z80_set,

    output reg          busy,
    output reg          pass,
    output reg          fail
);

localparam [3:0]
    ST_IDLE          = 4'd0,
    ST_WAIT_CAPTURE  = 4'd1,
    ST_WAIT_ACK      = 4'd2,
    ST_SET_ORIG      = 4'd3,
    ST_ORIG_WAIT1    = 4'd4,
    ST_ORIG_WAIT2    = 4'd5,
    ST_VERIFY_ORIG1  = 4'd6,
    ST_SET_MUT       = 4'd7,
    ST_MUT_WAIT1     = 4'd8,
    ST_MUT_WAIT2     = 4'd9,
    ST_VERIFY_MUT    = 4'd10,
    ST_RESTORE       = 4'd11,
    ST_RESTORE_WAIT1 = 4'd12,
    ST_RESTORE_WAIT2 = 4'd13,
    ST_VERIFY_FINAL  = 4'd14,
    ST_DONE          = 4'd15;

reg [3:0] state;
reg       armed;
reg       failed;
reg [229:0] snap;

function automatic [229:0] mutate_state(input [229:0] v);
begin
    mutate_state = v;

    // Exercise one ordinary architectural register bit.
    mutate_state[0]   = ~v[0];    // A bit 0

    // Exercise all state added by the modern 230-bit T80 SS interface.
    mutate_state[212] = ~v[212];  // WZ bit 0
    mutate_state[228] = ~v[228];  // Alternate
    mutate_state[229] = ~v[229];  // Halt_FF
end
endfunction

always @(posedge clk) begin
    if (reset) begin
        state       <= ST_IDLE;
        armed       <= 1'b1;
        failed      <= 1'b0;
        snap        <= 230'd0;
        freeze_req  <= 1'b0;
        z80_dir     <= 230'd0;
        z80_set     <= 1'b0;
        busy        <= 1'b0;
        pass        <= 1'b0;
        fail        <= 1'b0;
    end
    else begin
        z80_set <= 1'b0;

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
                    freeze_req <= 1'b1;
                    state      <= ST_WAIT_CAPTURE;
                end
            end

            // Capture the PRE-TICK Z80 image on the same clk edge on which
            // the clean opcode-fetch boundary is accepted.
            ST_WAIT_CAPTURE: begin
                if (freeze_capture) begin
                    snap  <= z80_reg;
                    state <= ST_WAIT_ACK;
                end
            end

            // ss_hold is now active. No future Z80 CE pulse can execute.
            ST_WAIT_ACK: begin
                if (freeze_ack) begin
                    z80_dir <= snap;
                    z80_set <= 1'b1;
                    state   <= ST_SET_ORIG;
                end
            end

            ST_SET_ORIG: begin
                z80_set <= 1'b0;
                state   <= ST_ORIG_WAIT1;
            end
            ST_ORIG_WAIT1: state <= ST_ORIG_WAIT2;
            ST_ORIG_WAIT2: state <= ST_VERIFY_ORIG1;

            ST_VERIFY_ORIG1: begin
                if (z80_reg != snap)
                    failed <= 1'b1;

                z80_dir <= mutate_state(snap);
                z80_set <= 1'b1;
                state   <= ST_SET_MUT;
            end

            ST_SET_MUT: begin
                z80_set <= 1'b0;
                state   <= ST_MUT_WAIT1;
            end
            ST_MUT_WAIT1: state <= ST_MUT_WAIT2;
            ST_MUT_WAIT2: state <= ST_VERIFY_MUT;

            ST_VERIFY_MUT: begin
                if (z80_reg != mutate_state(snap))
                    failed <= 1'b1;

                z80_dir <= snap;
                z80_set <= 1'b1;
                state   <= ST_RESTORE;
            end

            ST_RESTORE: begin
                z80_set <= 1'b0;
                state   <= ST_RESTORE_WAIT1;
            end
            ST_RESTORE_WAIT1: state <= ST_RESTORE_WAIT2;
            ST_RESTORE_WAIT2: state <= ST_VERIFY_FINAL;

            ST_VERIFY_FINAL: begin
                freeze_req <= 1'b0;
                busy       <= 1'b0;

                if ((z80_reg != snap) || failed) begin
                    pass <= 1'b0;
                    fail <= 1'b1;
                end
                else begin
                    pass <= 1'b1;
                    fail <= 1'b0;
                end

                state <= ST_DONE;
            end

            ST_DONE: begin
                // Keep result latched until OSD option goes Off.
                if (!start)
                    state <= ST_IDLE;
            end

            default: state <= ST_IDLE;
        endcase
    end
end

endmodule
