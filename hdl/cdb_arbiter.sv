module cdb_arbiter
import rv32cpu_type::*;
#(
    //parameter CDB_WIDTH,
    parameter FUNC_UNITS,
    parameter INDEX_WIDTH
)
(
    input   logic               clk,
    input   logic               rst,

    input   cdb_entry_t         cdb_in[FUNC_UNITS],
    output  cdb_entry_t         cdb_out[FUNC_UNITS]
);

    // localparam QUEUE_SIZE                      = 1<<INDEX_WIDTH;
    // localparam CTR_INDEX                      = $clog2(CDB_WIDTH);
    
    // cdb_entry_t slots[QUEUE_SIZE], slots_f[QUEUE_SIZE];
    // logic   [INDEX_WIDTH:0] head, tail, head_f, tail_f;                                    
    // logic   [CTR_INDEX-1:0] out_index;
    // logic                 empty;

    // always_comb begin
    //     out_index = '1;
    //     head= head_f;
    //     tail= tail_f;
    //     for(integer i = 0; i < CDB_WIDTH; i++) begin
    //         if(tail!=head) begin
    //             cdb_out[i] = slots[head[INDEX_WIDTH-1:0]];
    //             head = head + 1'd1;
    //         end
    //         else begin
    //             cdb_out[i] = '0;
    //         end
    //     end

    //     for(integer i = 0; i < FUNC_UNITS; i++) begin
    //         if(cdb_in[i].valid) begin
    //             tail = tail + 1'd1;
    //         end
    //     end
    // end

    // always_ff @(posedge clk) begin
    //     integer c; 
    //     if (rst) begin
    //         head_f <= '0;
    //         tail_f <= '0;
    //         for (integer i = 0; i < QUEUE_SIZE; i++) begin
    //             slots[i] <= '0;
    //         end
    //     end 
    //     else begin
    //         head_f <= head;
    //         tail_f <= tail;
    //         c={'0, tail_f};
    //         for (integer i = 0; i < FUNC_UNITS; i++) begin
    //             if(cdb_in[i].valid) begin
    //                 slots[c[INDEX_WIDTH-1:0]] <= cdb_in[i];
    //                 c = c + 1'd1;
    //             end
    //         end
    //     end
    // end

    always_ff @(posedge clk) begin
        if (rst) begin
            for (integer i = 0; i < FUNC_UNITS; i++) begin
                cdb_out[i] <='0;
            end
        end 
        else begin
            for (integer i = 0; i < FUNC_UNITS; i++) begin
                cdb_out[i] <= cdb_in[i];
            end
        end
    end


endmodule