module instruction_queue
import rv32cpu_type::*;
#(
    parameter QUEUE_SIZE
) (
    input   logic               clk,
    input   logic               rst,
    input   logic               flush,

    input   logic               enqueue,                                            // a new instruction wants to join
    input   logic [7:0]         inst_mask,                                      // the instruction is valid
    input   instr_queue_entry_t data_in[8],
    input   logic               dequeue[2],                                            // an instruction is ready to execute
    output  instr_queue_entry_t data_out[2],

    output  logic               full,                                               // the queue is full, more useful
    output  logic               empty[2]
);

    // suppose QUEUE_SIZE is power of two
    localparam INDEX_WIDTH                      = $clog2(QUEUE_SIZE);
    
            instr_queue_entry_t slots[QUEUE_SIZE-1:0];
            logic   [INDEX_WIDTH:0] head, tail, diff, tail_next, tail_ptr;                                     // Rubin pointed this out, he is the god.
            logic   [31:0] ones;
            // logic empty_f, full_f;

    always_comb begin
        empty[0]                             = (head == tail);                   // same round, same counter
        empty[1]                             = (head == tail) || (head + 1'b1 == tail);
        ones                                 = $unsigned($countones(inst_mask));
        tail_next                            = tail + ones[3:0];
        diff = tail - head;
        full = diff[4] | diff[3];
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            head                                <= '0;
            tail                                <= '0;
            for (integer i = 0; i < QUEUE_SIZE; i++) begin
                slots[i] <= '0;
            end
        end else begin
            // if(empty && enqueue && dequeue)begin
            //     slots[tail[INDEX_WIDTH-1:0]]        <= data_in;
            //     data_out <= data_in;
            //     tail <= tail + 1'd1;
            //     head <= head + 1'd1;
            // end
            // else begin
            if (flush) begin
                tail <= head;
                data_out <= '{default:0};
                for (integer i = 0; i < QUEUE_SIZE; i++) begin
                    slots[i] <= '0;
                end
            end else begin
                if (enqueue & (~full)) begin
                    tail <= tail_next;
                    tail_ptr = tail;
                    for (integer unsigned i = 0; i < 8; i++) begin
                        if(inst_mask[i]) begin
                            slots[tail_ptr[INDEX_WIDTH-1:0]] <= data_in[i];
                            tail_ptr = tail_ptr + 1'd1;
                        end
                    end
                end
                    
                data_out[0] <= slots[head[INDEX_WIDTH-1:0]];
                data_out[1] <= slots[head[INDEX_WIDTH-1:0]+1'h1];
                if(dequeue[0] & ~empty[0]) begin
                    // data_out                        <= '0;
                    slots[head[INDEX_WIDTH-1:0]]    <= '0;
                    head                            <= head + 1'h1;
                    data_out[0] <= slots[head[INDEX_WIDTH-1:0]+1'h1];
                    data_out[1] <= slots[head[INDEX_WIDTH-1:0]+2'h2];
                end
                if(dequeue[1] & ~empty[1]) begin
                    // data_out                        <= '0;
                    slots[head[INDEX_WIDTH-1:0]+1'b1]    <= '0;
                    head                                 <= head + 2'h2;
                    data_out[0] <= slots[head[INDEX_WIDTH-1:0]+2'h2];
                    data_out[1] <= slots[head[INDEX_WIDTH-1:0]+2'h3];
                end
            end
        end
    end

endmodule