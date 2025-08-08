module reorder
import rv32cpu_type::*;
#(
    parameter INDEX_WIDTH,
    parameter WRITE_PORTS,
    parameter DISPATCH_WIDTH
) 
(
    input   logic               clk,
    input   logic               rst,

    input   logic               enqueue[2],                                           // a new instruction wants to join
    input   rob_entry_t         data_in[2],
    input   monitor_t           monitor_entry_i[2],
    output  logic               commit[2],                                            // an instruction is ready to execute
    output  rob_entry_t         data_out[2],
    output  logic   [INDEX_WIDTH-1: 0]  rob_tail,                                    
    output  logic   [INDEX_WIDTH-1: 0]  rob_head,                                    

    input   cdb_entry_t         cdb_in[WRITE_PORTS],
    input   br_entry_t          br_in,

    input   logic   [INDEX_WIDTH-1: 0]      rob1_s[2], rob2_s[2],                                      // the instruction that is dispatched
    output  logic   [31:0]                  rob1_v[2], rob2_v[2],
    output  logic                           rob1_r[2], rob2_r[2],                                          // the instruction that is dispatched

    // output  monitor_t               monitor_entry_o[0],                                     // the instruction that is dispatched

    output  logic               flush_valid,
    output  logic               br_actual,
    output  logic               flush,
    output  logic   [31:0]      pc_curr,
    output  logic   [31:0]      pc_flush,
    output  logic   [1:0]       flush_counter,

    output  logic               full[2]                                               // the queue is full, more useful
);

    localparam QUEUE_SIZE                      = 1<<INDEX_WIDTH;
    rob_entry_t slots[QUEUE_SIZE];
    monitor_t slots_c[QUEUE_SIZE];
    logic   [INDEX_WIDTH:0] head, headn, tail, tailn, head_next, tail_next;
    logic   [63:0] order;
    logic   [31:0] i_imm, s_imm, branches, flushes;
    logic   [1:0]  mask_offset;
    monitor_t monitor_entry_o[2];

    assign full[0]                                = (head[INDEX_WIDTH] != tail[INDEX_WIDTH]) // checks if we have gone around
                                                  && (head[INDEX_WIDTH - 1:0]== tail[INDEX_WIDTH - 1:0]);
    assign full[1]                                = (head[INDEX_WIDTH] != tail[INDEX_WIDTH]) // checks if we have gone around
                                                  && (head[INDEX_WIDTH - 1:0]== tail[INDEX_WIDTH - 1:0])
                                                  ||(head[INDEX_WIDTH] != tailn[INDEX_WIDTH])
                                                  && (head[INDEX_WIDTH - 1:0]== tailn[INDEX_WIDTH - 1:0]);

    always_ff @(posedge clk) begin
        if (rst) begin
            head                                <= '0;
            tail                                <= '0;
            order                               <= '0;
            branches                           <= '0;
            flushes                            <= '0;
            
            for (integer i = 0; i < QUEUE_SIZE; i++) begin
                slots[i] <= '0;
                slots_c[i] <= '0;
            end
        end else begin
            if (flush) begin
                head                            <= head_next;
                tail                            <= head_next;
                for (integer i = 0; i < QUEUE_SIZE; i++) begin
                    slots[i].valid <= '0;
                    slots[i].rd_valid <= '0;
                    slots_c[i].valid <= '0;
                end
            end else begin
                head                                <= head_next;
                if(slots[head[INDEX_WIDTH-1:0]].valid) begin
                    slots[head[INDEX_WIDTH-1:0]]    <= '0;
                    slots_c[head[INDEX_WIDTH-1:0]]  <= '0;
                    if(slots[headn[INDEX_WIDTH-1:0]].valid) begin
                        slots[headn[INDEX_WIDTH-1:0]]    <= '0;
                        slots_c[headn[INDEX_WIDTH-1:0]]  <= '0;
                    end
                end
                for (integer i = 0; i < WRITE_PORTS; i++) begin
                    if(cdb_in[i].valid) begin
                        slots[cdb_in[i].rob_id].valid <= '1;
                        slots[cdb_in[i].rob_id].rd_valid  <= '1;
                        slots[cdb_in[i].rob_id].rd_v  <= cdb_in[i].rd_v;
                    end
                end
                if (br_in.valid) begin
                    slots[br_in.rob_id].valid <= '1;
                    slots[br_in.rob_id].br_actual <= br_in.br_en;
                    if (br_in.jalr) begin
                        slots[br_in.rob_id].pc <= br_in.pc_jalr;
                    end
                end


                for (integer i = 0; i < WRITE_PORTS; i++) begin
                    if(cdb_in[i].valid) begin
                        slots_c[cdb_in[i].rob_id].valid <= '1;
                        slots_c[cdb_in[i].rob_id].rd_v  <= cdb_in[i].rd_v;
                        for (integer j = 0; j < QUEUE_SIZE; j++) begin
                            if(slots_c[j].rs1_renamed&&slots_c[j].rs1_rdata[INDEX_WIDTH-1:0]==cdb_in[i].rob_id) begin
                                slots_c[j].rs1_renamed <= '0;
                                slots_c[j].rs1_rdata <= cdb_in[i].rd_v;
                            end
                            if(slots_c[j].rs2_renamed&&slots_c[j].rs2_rdata[INDEX_WIDTH-1:0]==cdb_in[i].rob_id) begin
                                slots_c[j].rs2_renamed <= '0;
                                slots_c[j].rs2_rdata <= cdb_in[i].rd_v;
                            end
                        end
                    end
                end
            end
            
            if (enqueue[0] & ~flush) begin
                tail                            <= tail + 1'd1;

                slots[tail[INDEX_WIDTH-1:0]]    <= data_in[0];
                slots_c[tail[INDEX_WIDTH-1:0]]  <= monitor_entry_i[0];
            end

            if(enqueue[1] & ~flush) begin
                tail                            <= tail + 2'd2;

                slots[tailn[INDEX_WIDTH-1:0]]    <= data_in[1];
                slots_c[tailn[INDEX_WIDTH-1:0]]  <= monitor_entry_i[1];
            end

            if(commit[0]) begin
                order                              <= order + 1'd1;
                // if(slots_c[head[INDEX_WIDTH-1:0]].inst[6:0] == op_b_br) begin
                //     branches <= branches + 1'd1;
                //     if (flush) begin
                //         flushes <= flushes + 1'd1;
                //     end
                // end
            end
            if (commit[1]) begin
                order                              <= order + 2'd2;
                // if(slots_c[headn[INDEX_WIDTH-1:0]].inst[6:0] == op_b_br) begin
                //     branches <= branches + 1'd1;
                //     if (flush) begin
                //         flushes <= flushes + 1'd1;
                //     end
                // end
            end
        end
    end

    always_comb begin
        commit                          = '{default: '0};
        data_out                        = '{default: '0};

        flush                           = '0;
        pc_flush                        = 'x;
        headn                           = head + 1'd1;
        tailn                           = tail + 1'd1;
        head_next                      = head;
        tail_next                      = tail;
        rob_head                             = head[INDEX_WIDTH-1:0];
        rob_tail                             = tail[INDEX_WIDTH-1:0];
        flush_valid = 1'b0;
        br_actual = 1'b0;
        pc_curr = 32'b0;
        flush_counter = 2'b0;
        for (integer i = 0; i < 2; i++) begin
            rob1_v[i] = slots[rob1_s[i]].rd_v;
            rob2_v[i] = slots[rob2_s[i]].rd_v;
            rob1_r[i] = slots[rob1_s[i]].rd_valid;
            rob2_r[i] = slots[rob2_s[i]].rd_valid;
        end
        if(slots[head[INDEX_WIDTH-1:0]].valid) begin
            commit[0]                          = '1;
            data_out[0]                        = slots[head[INDEX_WIDTH-1:0]];
            flush                           = slots[head[INDEX_WIDTH-1:0]].br_actual != slots[head[INDEX_WIDTH-1:0]].br_predicted[1];
            pc_flush                        = slots[head[INDEX_WIDTH-1:0]].br_actual ? slots[head[INDEX_WIDTH-1:0]].pc : slots[head[INDEX_WIDTH-1:0]].rd_v;
            head_next                       = head + 1'h1;
            if (slots[head[INDEX_WIDTH-1:0]].br) begin
                flush_valid = 1'b1;
                br_actual = slots[head[INDEX_WIDTH-1:0]].br_actual;
                pc_curr = slots[head[INDEX_WIDTH-1:0]].rd_v - 32'd4;
                flush_counter = slots[head[INDEX_WIDTH-1:0]].br_predicted;
            end
            if(slots[headn[INDEX_WIDTH-1:0]].valid && ~flush) begin
                commit[1]                      = '1;
                data_out[1]                    = slots[headn[INDEX_WIDTH-1:0]];
                flush                          = slots[headn[INDEX_WIDTH-1:0]].br_actual != slots[headn[INDEX_WIDTH-1:0]].br_predicted[1];
                pc_flush                       = slots[headn[INDEX_WIDTH-1:0]].br_actual ? slots[headn[INDEX_WIDTH-1:0]].pc : slots[headn[INDEX_WIDTH-1:0]].rd_v;
                head_next                       = head + 2'h2;
                if (slots[headn[INDEX_WIDTH-1:0]].br) begin
                    flush_valid = 1'b1;
                    br_actual = slots[headn[INDEX_WIDTH-1:0]].br_actual;
                    pc_curr = slots[headn[INDEX_WIDTH-1:0]].rd_v - 32'd4;
                    flush_counter = slots[headn[INDEX_WIDTH-1:0]].br_predicted;
                end
            end
        end



        monitor_entry_o[0] = '0;
        monitor_entry_o[0].valid = commit[0];
        monitor_entry_o[0].order = order;
        monitor_entry_o[0].inst  = slots_c[head[INDEX_WIDTH-1:0]].inst;
        monitor_entry_o[0].rs1_addr = slots_c[head[INDEX_WIDTH-1:0]].rs1_addr;
        monitor_entry_o[0].rs2_addr = slots_c[head[INDEX_WIDTH-1:0]].rs2_addr;
        monitor_entry_o[0].rs1_rdata = slots_c[head[INDEX_WIDTH-1:0]].rs1_rdata;
        monitor_entry_o[0].rs2_rdata = slots_c[head[INDEX_WIDTH-1:0]].rs2_rdata;
        monitor_entry_o[0].regf_we = slots_c[head[INDEX_WIDTH-1:0]].regf_we;
        monitor_entry_o[0].rd_addr = slots_c[head[INDEX_WIDTH-1:0]].rd_addr;
        monitor_entry_o[0].rd_v = slots_c[head[INDEX_WIDTH-1:0]].rd_v;
        monitor_entry_o[0].pc_rdata = slots_c[head[INDEX_WIDTH-1:0]].pc_rdata;
        monitor_entry_o[0].pc_wdata = slots[head[INDEX_WIDTH-1:0]].br_actual != slots[head[INDEX_WIDTH-1:0]].br_predicted[1] ? pc_flush : slots_c[head[INDEX_WIDTH-1:0]].pc_wdata;
        
        i_imm = {{21{slots_c[head[INDEX_WIDTH-1:0]].inst[31]}}, slots_c[head[INDEX_WIDTH-1:0]].inst[30:20]};
        s_imm = {{21{slots_c[head[INDEX_WIDTH-1:0]].inst[31]}}, slots_c[head[INDEX_WIDTH-1:0]].inst[30:25], slots_c[head[INDEX_WIDTH-1:0]].inst[11:7]};

        unique case(slots_c[head[INDEX_WIDTH-1:0]].inst[6:0]) 
            op_b_load: begin
                monitor_entry_o[0].mem_addr = (slots_c[head[INDEX_WIDTH-1:0]].rs1_rdata + i_imm)&~32'h3;
                mask_offset = slots_c[head[INDEX_WIDTH-1:0]].rs1_rdata[1:0] + i_imm[1:0];
                unique case (slots_c[head[INDEX_WIDTH-1:0]].inst[14:12])
                    load_f3_lb, load_f3_lbu : monitor_entry_o[0].mem_rmask = 4'b0001 << mask_offset;
                    load_f3_lh, load_f3_lhu : monitor_entry_o[0].mem_rmask = 4'b0011 << mask_offset;
                    load_f3_lw              : monitor_entry_o[0].mem_rmask = 4'b1111;
                    default                 : monitor_entry_o[0].mem_rmask = 'x;
                endcase
                monitor_entry_o[0].mem_wmask = '0;
                monitor_entry_o[0].mem_rdata = slots_c[head[INDEX_WIDTH-1:0]].rd_v;
                unique case (slots_c[head[INDEX_WIDTH-1:0]].inst[14:12])
                    load_f3_lb  : monitor_entry_o[0].mem_rdata = (slots_c[head[INDEX_WIDTH-1:0]].rd_v & {32'b00000000000000000000000011111111}) << (((slots_c[head[INDEX_WIDTH-1:0]].rs1_rdata + i_imm)&32'h3)<<3);
                    load_f3_lbu : monitor_entry_o[0].mem_rdata = (slots_c[head[INDEX_WIDTH-1:0]].rd_v & {32'b00000000000000000000000011111111}) << (((slots_c[head[INDEX_WIDTH-1:0]].rs1_rdata + i_imm)&32'h3)<<3);
                    load_f3_lh  : monitor_entry_o[0].mem_rdata = (slots_c[head[INDEX_WIDTH-1:0]].rd_v & {32'b00000000000000001111111111111111}) << (((slots_c[head[INDEX_WIDTH-1:0]].rs1_rdata + i_imm)&32'h3)<<3);
                    load_f3_lhu : monitor_entry_o[0].mem_rdata = (slots_c[head[INDEX_WIDTH-1:0]].rd_v & {32'b00000000000000001111111111111111}) << (((slots_c[head[INDEX_WIDTH-1:0]].rs1_rdata + i_imm)&32'h3)<<3);
                    load_f3_lw  : monitor_entry_o[0].mem_rdata = slots_c[head[INDEX_WIDTH-1:0]].rd_v;
                    default     : monitor_entry_o[0].mem_rdata = 'x;
                endcase
                monitor_entry_o[0].mem_wdata = '0;
            end
            op_b_store: begin
                monitor_entry_o[0].mem_addr = (slots_c[head[INDEX_WIDTH-1:0]].rs1_rdata + s_imm)&~32'h3;
                monitor_entry_o[0].mem_rmask = '0;
                mask_offset = slots_c[head[INDEX_WIDTH-1:0]].rs1_rdata[1:0] + s_imm[1:0];
                unique case (slots_c[head[INDEX_WIDTH-1:0]].inst[14:12])
                    store_f3_sb: monitor_entry_o[0].mem_wmask = 4'b0001 << mask_offset;
                    store_f3_sh: monitor_entry_o[0].mem_wmask = 4'b0011 << mask_offset;
                    store_f3_sw: monitor_entry_o[0].mem_wmask = 4'b1111;
                    default    : monitor_entry_o[0].mem_wmask = 'x;
                endcase
                monitor_entry_o[0].mem_rdata = '0;
                unique case (slots_c[head[INDEX_WIDTH-1:0]].inst[14:12])
                    store_f3_sb: monitor_entry_o[0].mem_wdata[8 *mask_offset +: 8 ] = slots_c[head[INDEX_WIDTH-1:0]].rs2_rdata[7 :0];
                    store_f3_sh: monitor_entry_o[0].mem_wdata[16*mask_offset[1]   +: 16] = slots_c[head[INDEX_WIDTH-1:0]].rs2_rdata[15:0];
                    store_f3_sw: monitor_entry_o[0].mem_wdata = slots_c[head[INDEX_WIDTH-1:0]].rs2_rdata;
                    default    : monitor_entry_o[0].mem_wdata = 'x;
                endcase
            end
            default: begin
                monitor_entry_o[0].mem_addr = '0;
                monitor_entry_o[0].mem_rmask = '0;
                monitor_entry_o[0].mem_wmask = '0;
                monitor_entry_o[0].mem_rdata = '0;
                monitor_entry_o[0].mem_wdata = '0;
            end
        endcase


        monitor_entry_o[1] = '0;
        monitor_entry_o[1].valid = commit[1];
        monitor_entry_o[1].order = order+1'h1;
        monitor_entry_o[1].inst  = slots_c[headn[INDEX_WIDTH-1:0]].inst;
        monitor_entry_o[1].rs1_addr = slots_c[headn[INDEX_WIDTH-1:0]].rs1_addr;
        monitor_entry_o[1].rs2_addr = slots_c[headn[INDEX_WIDTH-1:0]].rs2_addr;
        monitor_entry_o[1].rs1_rdata = slots_c[headn[INDEX_WIDTH-1:0]].rs1_rdata;
        monitor_entry_o[1].rs2_rdata = slots_c[headn[INDEX_WIDTH-1:0]].rs2_rdata;
        monitor_entry_o[1].regf_we = slots_c[headn[INDEX_WIDTH-1:0]].regf_we;
        monitor_entry_o[1].rd_addr = slots_c[headn[INDEX_WIDTH-1:0]].rd_addr;
        monitor_entry_o[1].rd_v = slots_c[headn[INDEX_WIDTH-1:0]].rd_v;
        monitor_entry_o[1].pc_rdata = slots_c[headn[INDEX_WIDTH-1:0]].pc_rdata;
        monitor_entry_o[1].pc_wdata = slots[headn[INDEX_WIDTH-1:0]].br_actual != slots[headn[INDEX_WIDTH-1:0]].br_predicted[1] ? pc_flush : slots_c[headn[INDEX_WIDTH-1:0]].pc_wdata;
        
        i_imm = {{21{slots_c[headn[INDEX_WIDTH-1:0]].inst[31]}}, slots_c[headn[INDEX_WIDTH-1:0]].inst[30:20]};
        s_imm = {{21{slots_c[headn[INDEX_WIDTH-1:0]].inst[31]}}, slots_c[headn[INDEX_WIDTH-1:0]].inst[30:25], slots_c[headn[INDEX_WIDTH-1:0]].inst[11:7]};

        unique case(slots_c[headn[INDEX_WIDTH-1:0]].inst[6:0]) 
            op_b_load: begin
                monitor_entry_o[1].mem_addr = (slots_c[headn[INDEX_WIDTH-1:0]].rs1_rdata + i_imm)&~32'h3;
                mask_offset = slots_c[headn[INDEX_WIDTH-1:0]].rs1_rdata[1:0] + i_imm[1:0];
                unique case (slots_c[headn[INDEX_WIDTH-1:0]].inst[14:12])
                    load_f3_lb, load_f3_lbu : monitor_entry_o[1].mem_rmask = 4'b0001 << mask_offset;
                    load_f3_lh, load_f3_lhu : monitor_entry_o[1].mem_rmask = 4'b0011 << mask_offset;
                    load_f3_lw              : monitor_entry_o[1].mem_rmask = 4'b1111;
                    default                 : monitor_entry_o[1].mem_rmask = 'x;
                endcase
                monitor_entry_o[1].mem_wmask = '0;
                monitor_entry_o[1].mem_rdata = slots_c[headn[INDEX_WIDTH-1:0]].rd_v;
                unique case (slots_c[headn[INDEX_WIDTH-1:0]].inst[14:12])
                    load_f3_lb  : monitor_entry_o[1].mem_rdata = (slots_c[headn[INDEX_WIDTH-1:0]].rd_v & {32'b00000000000000000000000011111111}) << (((slots_c[headn[INDEX_WIDTH-1:0]].rs1_rdata + i_imm)&32'h3)<<3);
                    load_f3_lbu : monitor_entry_o[1].mem_rdata = (slots_c[headn[INDEX_WIDTH-1:0]].rd_v & {32'b00000000000000000000000011111111}) << (((slots_c[headn[INDEX_WIDTH-1:0]].rs1_rdata + i_imm)&32'h3)<<3);
                    load_f3_lh  : monitor_entry_o[1].mem_rdata = (slots_c[headn[INDEX_WIDTH-1:0]].rd_v & {32'b00000000000000001111111111111111}) << (((slots_c[headn[INDEX_WIDTH-1:0]].rs1_rdata + i_imm)&32'h3)<<3);
                    load_f3_lhu : monitor_entry_o[1].mem_rdata = (slots_c[headn[INDEX_WIDTH-1:0]].rd_v & {32'b00000000000000001111111111111111}) << (((slots_c[headn[INDEX_WIDTH-1:0]].rs1_rdata + i_imm)&32'h3)<<3);
                    load_f3_lw  : monitor_entry_o[1].mem_rdata = slots_c[headn[INDEX_WIDTH-1:0]].rd_v;
                    default     : monitor_entry_o[1].mem_rdata = 'x;
                endcase
                monitor_entry_o[1].mem_wdata = '0;
            end
            op_b_store: begin
                monitor_entry_o[1].mem_addr = (slots_c[headn[INDEX_WIDTH-1:0]].rs1_rdata + s_imm)&~32'h3;
                monitor_entry_o[1].mem_rmask = '0;
                mask_offset = slots_c[headn[INDEX_WIDTH-1:0]].rs1_rdata[1:0] + s_imm[1:0];
                unique case (slots_c[headn[INDEX_WIDTH-1:0]].inst[14:12])
                    store_f3_sb: monitor_entry_o[1].mem_wmask = 4'b0001 << mask_offset;
                    store_f3_sh: monitor_entry_o[1].mem_wmask = 4'b0011 << mask_offset;
                    store_f3_sw: monitor_entry_o[1].mem_wmask = 4'b1111;
                    default    : monitor_entry_o[1].mem_wmask = 'x;
                endcase
                monitor_entry_o[1].mem_rdata = '0;
                unique case (slots_c[headn[INDEX_WIDTH-1:0]].inst[14:12])
                    store_f3_sb: monitor_entry_o[1].mem_wdata[8 *mask_offset +: 8 ] = slots_c[headn[INDEX_WIDTH-1:0]].rs2_rdata[7 :0];
                    store_f3_sh: monitor_entry_o[1].mem_wdata[16*mask_offset[1]   +: 16] = slots_c[headn[INDEX_WIDTH-1:0]].rs2_rdata[15:0];
                    store_f3_sw: monitor_entry_o[1].mem_wdata = slots_c[headn[INDEX_WIDTH-1:0]].rs2_rdata;
                    default    : monitor_entry_o[1].mem_wdata = 'x;
                endcase
            end
            default: begin
                monitor_entry_o[1].mem_addr = '0;
                monitor_entry_o[1].mem_rmask = '0;
                monitor_entry_o[1].mem_wmask = '0;
                monitor_entry_o[1].mem_rdata = '0;
                monitor_entry_o[1].mem_wdata = '0;
            end
        endcase
    end

    logic           rvfi_valid     [2];
    logic   [63:0]  rvfi_order     [2];
    logic   [31:0]  rvfi_inst      [2];
    logic   [4:0]   rvfi_rs1_addr  [2];
    logic   [4:0]   rvfi_rs2_addr  [2];
    logic   [31:0]  rvfi_rs1_rdata [2];
    logic   [31:0]  rvfi_rs2_rdata [2];
    logic   [4:0]   rvfi_rd_addr   [2];
    logic   [31:0]  rvfi_rd_v      [2];
    logic   [31:0]  rvfi_pc_rdata  [2];
    logic   [31:0]  rvfi_pc_wdata  [2];
    logic   [31:0]  rvfi_mem_addr  [2];
    logic   [3:0]   rvfi_mem_rmask [2];
    logic   [3:0]   rvfi_mem_wmask [2];
    logic   [31:0]  rvfi_mem_rdata [2];
    logic   [31:0]  rvfi_mem_wdata [2];

    always_comb begin
    // drive both RVFI sets
    for (integer i = 0; i < 2; i++) begin
        rvfi_valid     [i] = monitor_entry_o[i].valid;
        rvfi_order     [i] = monitor_entry_o[i].order;
        rvfi_inst      [i] = monitor_entry_o[i].inst;
        rvfi_rs1_addr  [i] = monitor_entry_o[i].rs1_addr;
        rvfi_rs2_addr  [i] = monitor_entry_o[i].rs2_addr;
        rvfi_rs1_rdata [i] = monitor_entry_o[i].rs1_rdata;
        rvfi_rs2_rdata [i] = monitor_entry_o[i].rs2_rdata;
        rvfi_rd_addr   [i] = monitor_entry_o[i].rd_addr;
        rvfi_rd_v      [i] = monitor_entry_o[i].rd_v;
        rvfi_pc_rdata  [i] = monitor_entry_o[i].pc_rdata;
        rvfi_pc_wdata  [i] = monitor_entry_o[i].pc_wdata;
        rvfi_mem_addr  [i] = monitor_entry_o[i].mem_addr;
        rvfi_mem_rmask [i] = monitor_entry_o[i].mem_rmask;
        rvfi_mem_wmask [i] = monitor_entry_o[i].mem_wmask;
        rvfi_mem_rdata [i] = monitor_entry_o[i].mem_rdata;
        rvfi_mem_wdata [i] = monitor_entry_o[i].mem_wdata;
    end
    end

endmodule