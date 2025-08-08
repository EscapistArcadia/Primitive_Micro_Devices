module gshare_predictor
import rv32cpu_type::*;
#(
    parameter GHR_WIDTH
    // parameter COUNTER_WIDTH,
    // parameter PC_LSB
) (
    input   logic               clk,
    input   logic               rst,
    input   logic               flush,
    
    // ports for fetch
    input   logic   [31:0]      fetch_pc,
    input   logic               fetch_valid,
    input   logic   [2:0]       fetch_br_offset,
    output  logic   [1:0]       fetch_counter,
    output  logic               dirty,

    // ports for rob
    input   logic               br_valid,
    input   logic               br_actual,
    input   logic   [1:0]       br_counter,
    input   logic   [31:0]      br_curr_pc,

    input logic     [1:0]       spec_br,
    input logic                 spec_valid
);

    // localparam TOTAL_WIDTH = 8 * (COUNTER_WIDTH);
    localparam SETS = 1 << (GHR_WIDTH - 3);

    logic [GHR_WIDTH-1:0] ghr, ghr_f, ghr_c;
    logic [7:0] dirty_bitmap[SETS-1:0];

    logic [GHR_WIDTH-4:0] fetch_addr;
    logic [15:0] fetch_out;

    logic flush_web, csbr_f, csbw_f;
    logic [GHR_WIDTH-4:0] flush_addr;
    logic [7:0] flush_wmask;
    logic [15:0] flush_in, flush_out;

    logic [7:0] dirty_f;

    // logic invalid_counter;

    always_comb begin
        fetch_counter = 'x;
        dirty = '0;

        fetch_addr = fetch_pc[GHR_WIDTH+1:5] ^ ghr[GHR_WIDTH-1:3];

        // if (~invalid_counter) begin
        dirty = dirty_f[fetch_br_offset ^ ghr_f[2:0]];
        fetch_counter = fetch_out[2*(fetch_br_offset ^ ghr_f[2:0])+:2];
        // end
    end

    always_comb begin
        flush_web = 1'b0;
        flush_addr = (br_curr_pc[GHR_WIDTH+1:5] ^ ghr_c[GHR_WIDTH-1:3]);
        flush_wmask = '0;
        flush_in = 'x;

        if (br_valid) begin
            flush_web = 1'b1;
            flush_wmask = 8'b1 << (br_curr_pc[4:2] ^ ghr_c[2:0]);
            if (br_actual) begin
                unique case (br_counter)
                    2'b00: flush_in = 16'b01 << ((br_curr_pc[4:2] ^ ghr_c[2:0]) * 2);
                    2'b01: flush_in = 16'b10 << ((br_curr_pc[4:2] ^ ghr_c[2:0]) * 2);
                    2'b10: flush_in = 16'b11 << ((br_curr_pc[4:2] ^ ghr_c[2:0]) * 2);
                    // 2'b00: flush_in = 16'b01 << (br_curr_pc[4:2] * 2);
                    default: flush_web=1'b0;
                endcase
            end else begin
                unique case (br_counter)
                    2'b01: flush_in = 16'b00 << ((br_curr_pc[4:2] ^ ghr_c[2:0]) * 2);
                    2'b10: flush_in = 16'b01 << ((br_curr_pc[4:2] ^ ghr_c[2:0]) * 2);
                    2'b11: flush_in = 16'b10 << ((br_curr_pc[4:2] ^ ghr_c[2:0]) * 2);
                    // 2'b00: flush_in = 16'b01 << (br_curr_pc[4:2] * 2);
                    default: flush_web=1'b0;
                endcase
            end
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            dirty_bitmap <= '{default:0};
            ghr <= '0;
            ghr_c <= '0;
            ghr_f <= '0;
            dirty_f <= '0;
        end else begin
            if (br_valid) begin
                ghr_c <= {ghr_c[GHR_WIDTH-2:0], br_actual};
                if(flush_web)
                    dirty_bitmap[flush_addr][br_curr_pc[4:2] ^ ghr_c[2:0]] <= 1'b1;
            end

            if(spec_valid)
                ghr <= {ghr[GHR_WIDTH-2:0], spec_br[1]};
            
            if(br_valid & flush)
                ghr <= {ghr_c[GHR_WIDTH-2:0], br_actual};

            dirty_f <= dirty_bitmap[fetch_addr];
            ghr_f <= ghr;
        end
        csbr_f <= fetch_valid;
        csbw_f <= flush_web;
    end

    gshare_data_array data_array (
        .clk0(clk & (fetch_valid | csbr_f)),
        .csb0(~fetch_valid & ~csbr_f),
        .web0(1'b1),
        .wmask0('0),
        .addr0(fetch_addr),
        .din0('x),
        .dout0(fetch_out),

        .clk1(clk & (flush_web | csbw_f)),
        .csb1(~flush_web & ~csbw_f),
        .web1(~flush_web),
        .wmask1(flush_wmask),
        .addr1(flush_addr),
        .din1(flush_in),
        .dout1(flush_out)
    );

endmodule