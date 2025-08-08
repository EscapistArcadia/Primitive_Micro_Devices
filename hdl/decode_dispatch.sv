module decode_dispatch
import rv32cpu_type::*;
#(
    parameter INDEX_WIDTH
)
(
    input  logic [31:0] in,
    input  logic [31:0] pc,
    input  logic [1:0]  br_predicted,
    input  logic        inst_empty,

    input  logic                   rob_full,
    input  logic [INDEX_WIDTH-1:0] rob_tail,
    input  logic                   rs_alu_full,
    input  logic                   rs_mul_div_full,
    input  logic                   rs_load_full,
    input  logic                   rs_store_full,
    input  logic                   rs_br_full,

    input  logic                   rs1_renamed,
    input  logic                   rs2_renamed,
    input  logic [31:0]            rs1_v,
    input  logic [31:0]            rs2_v,

    output rs_entry_t      rs_entry_o,
    output rs_load_entry_t rs_load_entry_o,
    output rs_store_entry_t rs_store_entry_o,
    output rob_entry_t     rob_entry_o,
    output monitor_t       monitor_entry_o,
    output logic         rob_enqueue_o,
    output logic         rs_alu_enqueue_o,
    output logic         rs_mul_div_enqueue_o,
    output logic         rs_mem_enqueue_o,
    output logic         rs_br_enqueue_o,

    output logic [4:0]           rs1_s,
    output logic [4:0]           rs2_s,
    output logic                 reg_r,
    output logic [4:0]           rd_r,
    output logic [INDEX_WIDTH-1:0] rob_r,

    output logic                 inst_dequeue
);

    logic [6:0]   opcode;
    logic [2:0]   funct3;
    logic [6:0]   funct7;
    logic [4:0]   rs1_dec, rs2_dec, rd_dec;
    logic [31:0]  i_imm, s_imm, b_imm, u_imm, j_imm;
    logic [31:0]    imm;

    assign opcode = in[6:0];
    assign funct3 = in[14:12];
    assign funct7 = in[31:25];
    assign rs1_dec  = in[19:15];
    assign rs2_dec  = in[24:20];
    assign rd_dec   = in[11:7];

    assign i_imm  = {{21{in[31]}}, in[30:20]};
    assign s_imm  = {{21{in[31]}}, in[30:25], in[11:7]};
    assign b_imm  = {{20{in[31]}}, in[7], in[30:25], in[11:8], 1'b0};
    assign u_imm  = {in[31:12], 12'h000};
    assign j_imm  = {{12{in[31]}}, in[19:12], in[20], in[30:21], 1'b0};

    logic         rs1_renamed_temp, rs2_renamed_temp;
    logic [31:0]  rs1_data_temp, rs2_data_temp;

    always_comb begin
        rs_entry_o       = '0;
        rs_load_entry_o  = '0;
        rs_store_entry_o = '0;
        rob_entry_o      = '0;
        monitor_entry_o  = '0;
        rob_enqueue_o    = 1'b0;
        rs_alu_enqueue_o = 1'b0;
        rs_mul_div_enqueue_o = 1'b0;
        rs_mem_enqueue_o = 1'b0;
        rs_br_enqueue_o  = 1'b0;
        inst_dequeue     = 1'b1;
        rs1_s            = in[19:15];
        rs2_s            = in[24:20];
        reg_r            = 1'b0;
        rd_r             = 5'd0;
        rob_r            = rob_tail;

        rs1_renamed_temp = 1'b0;
        rs2_renamed_temp = 1'b0;
        rs1_data_temp    = 32'd0;
        rs2_data_temp    = 32'd0;

        rob_entry_o.pc     = pc + b_imm;

        if(!inst_empty) begin
            unique case (opcode)
                op_b_lui: begin
                    rob_entry_o.valid     = 1'b1;
                    rob_entry_o.rd_valid  = 1'b1;
                    rob_entry_o.rd_v      = u_imm;
                    monitor_entry_o.rd_v = u_imm;//do not go to rs

                    rd_r  = rd_dec;
                    rob_entry_o.regf_we = 1'b1;
                    rob_entry_o.rd_s = rd_r;

                    monitor_entry_o.valid = 1'b1;
                    monitor_entry_o.inst  = in;
                    monitor_entry_o.rs1_addr = '0;
                    monitor_entry_o.rs2_addr = '0;
                    monitor_entry_o.rd_addr = rd_r;
                    monitor_entry_o.rs1_renamed = rs1_renamed_temp;
                    monitor_entry_o.rs1_rdata = rs1_data_temp;
                    monitor_entry_o.rs2_renamed = rs2_renamed_temp;
                    monitor_entry_o.rs2_rdata = rs2_data_temp;
                    monitor_entry_o.regf_we = 1'b1;
                    monitor_entry_o.pc_rdata = pc;
                    monitor_entry_o.pc_wdata = pc + 32'h4;
                    

                    if (!rob_full) begin
                        rob_enqueue_o         = 1'b1;
                        if (rd_dec != 5'd0) begin
                            reg_r = 1'b1;
                        end
                    end
                    else begin
                        inst_dequeue = 1'b0;
                    end
                end

                op_b_auipc: begin
                    rob_entry_o.valid  = 1'b1;
                    rob_entry_o.rd_valid  = 1'b1;
                    rob_entry_o.rd_v   = pc + u_imm;
                    rd_r  = rd_dec;
                    rob_entry_o.regf_we = 1'b1;
                    rob_entry_o.rd_s = rd_r;

                    monitor_entry_o.rd_v = pc + u_imm; //do not go to rs

                    monitor_entry_o.valid = 1'b1;
                    monitor_entry_o.inst  = in;
                    monitor_entry_o.rs1_addr = '0;
                    monitor_entry_o.rs2_addr = '0;
                    monitor_entry_o.rd_addr = rd_r;
                    monitor_entry_o.rs1_renamed = rs1_renamed_temp;
                    monitor_entry_o.rs1_rdata = rs1_data_temp;
                    monitor_entry_o.rs2_renamed = rs2_renamed_temp;
                    monitor_entry_o.rs2_rdata = rs2_data_temp;
                    monitor_entry_o.regf_we = 1'b1;
                    monitor_entry_o.pc_rdata = pc;
                    monitor_entry_o.pc_wdata = pc + 32'h4;

                    if (!rob_full) begin
                        rob_enqueue_o      = 1'b1;
                        if (rd_dec != 5'd0) begin
                            reg_r = 1'b1;
                        end
                    end
                    else begin
                        inst_dequeue = 1'b0;
                    end
                end

                op_b_jal: begin
                    rob_entry_o.valid     = 1'b1;
                    rob_entry_o.rd_valid  = 1'b1;
                    rob_entry_o.rd_v      = pc + 32'd4;
                    rd_r  = rd_dec;
                    rob_entry_o.regf_we = 1'b1;
                    rob_entry_o.rd_s = rd_r;

                    monitor_entry_o.rd_v = pc + 32'd4;//do not go to rs

                    monitor_entry_o.valid = 1'b1;
                    monitor_entry_o.inst  = in;
                    monitor_entry_o.rs1_addr = '0;
                    monitor_entry_o.rs2_addr = '0;
                    monitor_entry_o.rd_addr = rd_r;
                    monitor_entry_o.rs1_renamed = rs1_renamed_temp;
                    monitor_entry_o.rs1_rdata = rs1_data_temp;
                    monitor_entry_o.rs2_renamed = rs2_renamed_temp;
                    monitor_entry_o.rs2_rdata = rs2_data_temp;
                    monitor_entry_o.regf_we = 1'b1;
                    monitor_entry_o.pc_rdata = pc;
                    monitor_entry_o.pc_wdata = pc + j_imm;
                    if (!rob_full && ~inst_empty) begin
                        rob_enqueue_o         = 1'b1;
                        if (rd_dec != 5'd0) begin
                            reg_r = 1'b1;
                        end
                    end else begin
                        inst_dequeue = 1'b0;
                    end
                end


                op_b_jalr: begin
                    rs_entry_o.valid      = 1'b1;
                    rs_entry_o.funct7     = 1'b1; // branch does not have funct7, we use this to indicate jalr
                    if (rs1_dec == 5'd0) begin
                       rs1_renamed_temp = '0;
                       rs1_data_temp    = '0;
                    end else begin
                       rs1_renamed_temp = rs1_renamed;
                       rs1_data_temp    = rs1_v;
                    end

                    rd_r  = rd_dec;
                    rob_entry_o.regf_we = 1'b1;
                    rob_entry_o.rd_s = rd_r;

                    rs_entry_o.rs1_renamed = rs1_renamed_temp;
                    rs_entry_o.rs1_data    = rs1_data_temp;
                    rs_entry_o.rs2_renamed = '0; //no rs2, used as imm
                    rs_entry_o.rs2_data    = i_imm;
                    rs_entry_o.rob_id      = rob_tail;

                    // rob_entry_o.pc     = pc + 32'd4;
                    // rob_entry_o.rd_v   = pc + 32'd4;
                    rob_entry_o.valid = 1'b0;
                    rob_entry_o.rd_valid  = 1'b1;
                    rob_entry_o.rd_v = pc + 32'd4;
                    rob_entry_o.br_predicted = 2'b0;
                    // rob_entry_o.br_actual = 1'b1;

                    monitor_entry_o.rd_v = pc + 32'd4;//do not go to rs

                    monitor_entry_o.valid = 1'b0;
                    monitor_entry_o.inst  = in;
                    monitor_entry_o.rs1_addr = rs1_s;
                    monitor_entry_o.rs2_addr = '0;
                    monitor_entry_o.rd_addr = rd_r;
                    monitor_entry_o.rs1_renamed = rs1_renamed_temp;
                    monitor_entry_o.rs1_rdata = rs1_data_temp;
                    monitor_entry_o.rs2_renamed = rs2_renamed_temp;
                    monitor_entry_o.rs2_rdata = rs2_data_temp;
                    monitor_entry_o.regf_we = 1'b1;
                    monitor_entry_o.pc_rdata = pc;
                    monitor_entry_o.pc_wdata = pc + 32'd4;

                    if (!rob_full && ~rs_br_full && ~inst_empty) begin
                        rs_br_enqueue_o = 1'b1;
                        rob_enqueue_o      = 1'b1;
                        if (rd_dec != 5'd0) begin
                            reg_r = 1'b1;
                        end
                    end else begin
                        inst_dequeue = 1'b0;
                    end
                end

                op_b_br: begin

                    rs_entry_o.valid      = 1'b1;
                    rs_entry_o.funct3     = funct3;
                    if (rs1_dec == 5'd0) begin
                        rs1_renamed_temp = '0;
                        rs1_data_temp    = '0;
                    end else begin
                        rs1_renamed_temp = rs1_renamed;
                        rs1_data_temp    = rs1_v;
                    end
                    if (rs2_dec == 5'd0) begin
                        rs2_renamed_temp = '0;
                        rs2_data_temp    = '0;
                    end else begin
                        rs2_renamed_temp = rs2_renamed;
                        rs2_data_temp    = rs2_v;
                    end

                    rs_entry_o.rs1_renamed = rs1_renamed_temp;
                    rs_entry_o.rs1_data    = rs1_data_temp;
                    rs_entry_o.rs2_renamed = rs2_renamed_temp;
                    rs_entry_o.rs2_data    = rs2_data_temp;
                    rs_entry_o.rob_id      = rob_tail;

                    rob_entry_o.rd_v   = pc + 32'd4;
                    rob_entry_o.valid  = 1'b0;
                    rob_entry_o.rd_valid  = 1'b1;
                    rob_entry_o.br_predicted = br_predicted;
                    rob_entry_o.br     = 1'b1;

                    monitor_entry_o.valid = 1'b0;
                    monitor_entry_o.inst  = in;
                    monitor_entry_o.rs1_addr = rs1_s;
                    monitor_entry_o.rs2_addr = rs2_s;
                    // monitor_entry_o.rd_addr = rd_r;
                    monitor_entry_o.rs1_renamed = rs1_renamed_temp;
                    monitor_entry_o.rs1_rdata = rs1_data_temp;
                    monitor_entry_o.rs2_renamed = rs2_renamed_temp;
                    monitor_entry_o.rs2_rdata = rs2_data_temp;
                    monitor_entry_o.regf_we = 1'b0;
                    monitor_entry_o.pc_rdata = pc;
                    monitor_entry_o.pc_wdata = br_predicted[1] ? pc + b_imm : pc + 32'd4;

                    if (!rob_full && ~rs_br_full && ~inst_empty) begin
                        rs_br_enqueue_o = 1'b1;
                        rob_enqueue_o      = 1'b1;
                    end else begin
                        inst_dequeue = 1'b0;
                    end
                end
                
                op_b_load: begin
                    rs_load_entry_o.valid      = 1'b1;
                    rs_load_entry_o.funct3     = funct3;
                    if (rs1_dec == 5'd0) begin
                        rs1_renamed_temp = 1'b0;
                        rs1_data_temp    = 32'd0;
                    end else begin
                        rs1_renamed_temp = rs1_renamed;
                        rs1_data_temp    = rs1_v;
                    end
                    rs_load_entry_o.rs1_renamed = rs1_renamed_temp;
                    rs_load_entry_o.rs1_data    = rs1_data_temp;
                    rs_load_entry_o.imm         = i_imm[11:0];
                    rs_load_entry_o.rob_id      = rob_tail;

                    rob_entry_o.valid  = 1'b0;

                    rd_r  = rd_dec;
                    rob_entry_o.regf_we = 1'b1;
                    rob_entry_o.rd_s = rd_r;

                    monitor_entry_o.inst       = in;
                    monitor_entry_o.rs1_addr   = rs1_dec;
                    monitor_entry_o.rs2_addr   = '0;
                    monitor_entry_o.rs1_renamed = rs1_renamed_temp;
                    monitor_entry_o.rs1_rdata = rs1_data_temp;
                    monitor_entry_o.rs2_renamed = '0;
                    monitor_entry_o.rs2_rdata = '0;
                    monitor_entry_o.rd_addr    = rd_dec;
                    monitor_entry_o.regf_we    = 1'b1;
                    monitor_entry_o.pc_rdata   = pc;
                    monitor_entry_o.pc_wdata   = pc + 32'd4;
                    
                    if (!rob_full && ~rs_load_full) begin
                        rs_mem_enqueue_o = 1'b1;
                        rob_enqueue_o      = 1'b1;
                        if (rd_dec != 5'd0) begin
                            reg_r = 1'b1;
                        end
                    end
                    else begin
                        inst_dequeue = 1'b0;
                    end
                end

                op_b_store: begin
                    rs_store_entry_o.valid      = 1'b1;
                    rs_store_entry_o.funct3     = funct3;
                    if (rs1_dec == 5'd0) begin
                        rs1_renamed_temp = 1'b0;
                        rs1_data_temp    = 32'd0;
                    end else begin
                        rs1_renamed_temp = rs1_renamed;
                        rs1_data_temp    = rs1_v;
                    end
                    if (rs2_dec == 5'd0) begin
                        rs2_renamed_temp = 1'b0;
                        rs2_data_temp    = 32'd0;
                    end else begin
                        rs2_renamed_temp = rs2_renamed;
                        rs2_data_temp    = rs2_v;
                    end
                    rs_store_entry_o.rs1_renamed = rs1_renamed_temp;
                    rs_store_entry_o.rs1_data    = rs1_data_temp;
                    rs_store_entry_o.rs2_renamed = rs2_renamed_temp;
                    rs_store_entry_o.rs2_data    = rs2_data_temp;
                    rs_store_entry_o.imm         = s_imm[11:0];
                    rs_store_entry_o.rob_id      = rob_tail;

                    rob_entry_o.valid  = 1'b1;

                    monitor_entry_o.valid       = 1'b1;
                    monitor_entry_o.inst       = in;
                    monitor_entry_o.rs1_addr   = rs1_dec;
                    monitor_entry_o.rs2_addr   = rs2_dec;
                    monitor_entry_o.rs1_renamed = rs1_renamed_temp;
                    monitor_entry_o.rs1_rdata = rs1_data_temp;
                    monitor_entry_o.rs2_renamed = rs2_renamed_temp;
                    monitor_entry_o.rs2_rdata = rs2_data_temp;
                    monitor_entry_o.rd_addr    = '0;
                    monitor_entry_o.regf_we    = '0;
                    monitor_entry_o.pc_rdata   = pc;
                    monitor_entry_o.pc_wdata   = pc + 32'd4;
                    if (!rob_full && ~rs_store_full) begin
                        rs_mem_enqueue_o = 1'b1;
                        rob_enqueue_o      = 1'b1;
                    end
                    else begin
                        inst_dequeue = 1'b0;
                    end
                end


                op_b_imm: begin
                    rs_entry_o.valid      = 1'b1;
                    rs_entry_o.funct3     = funct3;
                    rs_entry_o.funct7     = funct3 == arith_f3_sr ? funct7[5] : '0;
                    // rs_entry_o.funct7     = funct7[5];

                    if (rs1_dec == 5'd0) begin
                       rs1_renamed_temp = '0;
                       rs1_data_temp    = '0;
                    end else begin
                       rs1_renamed_temp = rs1_renamed;
                       rs1_data_temp    = rs1_v;
                    end
                    
                    rs_entry_o.rs1_renamed = rs1_renamed_temp;
                    rs_entry_o.rs1_data    = rs1_data_temp;
                    rs_entry_o.rs2_renamed = '0; //no rs2, used as imm
                    rs_entry_o.rs2_data    = i_imm;
                    rs_entry_o.rob_id      = rob_tail;

                    
                    rd_r  = rd_dec;
                    rob_entry_o.regf_we = 1'b1;
                    rob_entry_o.rd_s = rd_r;

                    rob_entry_o.valid  = 1'b0;

                    monitor_entry_o.valid = 1'b0;
                    monitor_entry_o.inst  = in;
                    monitor_entry_o.rs1_addr = rs1_s;
                    monitor_entry_o.rs2_addr = '0;
                    monitor_entry_o.rd_addr = rd_r;
                    monitor_entry_o.rs1_renamed = rs1_renamed_temp;
                    monitor_entry_o.rs1_rdata = rs1_data_temp;
                    monitor_entry_o.rs2_renamed = rs2_renamed_temp;
                    monitor_entry_o.rs2_rdata = rs2_data_temp;
                    monitor_entry_o.regf_we = 1'b1;
                    monitor_entry_o.pc_rdata = pc;
                    monitor_entry_o.pc_wdata = pc + 32'h4;
                    if (!rob_full && ~rs_alu_full) begin
                        rs_alu_enqueue_o = 1'b1;
                        rob_enqueue_o      = 1'b1;
                        if (rd_dec != 5'd0) begin
                           reg_r = 1'b1;
                        end
                    end
                    else begin
                        inst_dequeue = 1'b0;
                    end
                end

                op_b_reg: begin
                    if (funct7[0] == 1'b0) begin
                        rs_entry_o.valid      = 1'b1;
                        rs_entry_o.funct3     = funct3;
                        rs_entry_o.funct7     = funct7[5];

                        if (rs1_dec == 5'd0) begin
                            rs1_renamed_temp = '0;
                            rs1_data_temp    = '0;
                        end else begin
                            rs1_renamed_temp = rs1_renamed;
                            rs1_data_temp    = rs1_v;
                        end
                        if (rs2_dec == 5'd0) begin
                            rs2_renamed_temp = '0;
                            rs2_data_temp    = '0;
                        end else begin
                            rs2_renamed_temp = rs2_renamed;
                            rs2_data_temp    = rs2_v;
                        end
                        rs_entry_o.rs1_renamed = rs1_renamed_temp;
                        rs_entry_o.rs1_data    = rs1_data_temp;
                        rs_entry_o.rs2_renamed = rs2_renamed_temp;
                        rs_entry_o.rs2_data    = rs2_data_temp;
                        rs_entry_o.rob_id      = rob_tail;

                        rob_entry_o.valid  = 1'b0;
                        
                        rd_r  = rd_dec;
                        rob_entry_o.regf_we = 1'b1;
                        rob_entry_o.rd_s = rd_r;

                        monitor_entry_o.valid = 1'b0;
                        monitor_entry_o.inst  = in;
                        monitor_entry_o.rs1_addr = rs1_s;
                        monitor_entry_o.rs2_addr = rs2_s;
                        monitor_entry_o.rd_addr = rd_r;
                        monitor_entry_o.rs1_renamed = rs1_renamed_temp;
                        monitor_entry_o.rs1_rdata = rs1_data_temp;
                        monitor_entry_o.rs2_renamed = rs2_renamed_temp;
                        monitor_entry_o.rs2_rdata = rs2_data_temp;
                        monitor_entry_o.regf_we = 1'b1;
                        monitor_entry_o.pc_rdata = pc;
                        monitor_entry_o.pc_wdata = pc + 32'h4;

                        if (!rob_full && ~rs_alu_full) begin
                            rs_alu_enqueue_o = 1'b1;
                            rob_enqueue_o      = 1'b1;
                            if (rd_dec != 5'd0) begin
                                reg_r = 1'b1;
                            end
                        end
                        else begin
                            inst_dequeue = 1'b0;
                        end
                    end
                    else begin
                        rs_entry_o.valid      = 1'b1;
                        rs_entry_o.funct3     = funct3;
                        
                        if (rs1_dec == 5'd0) begin
                            rs1_renamed_temp = '0;
                            rs1_data_temp    = '0;
                        end else begin
                            rs1_renamed_temp = rs1_renamed;
                            rs1_data_temp    = rs1_v;
                        end
                        if (rs2_dec == 5'd0) begin
                            rs2_renamed_temp = '0;
                            rs2_data_temp    = '0;
                        end else begin
                            rs2_renamed_temp = rs2_renamed;
                            rs2_data_temp    = rs2_v;
                        end
                        rs_entry_o.rs1_renamed = rs1_renamed_temp;
                        rs_entry_o.rs1_data    = rs1_data_temp;
                        rs_entry_o.rs2_renamed = rs2_renamed_temp;
                        rs_entry_o.rs2_data    = rs2_data_temp;
                        rs_entry_o.rob_id      = rob_tail;

                        rob_entry_o.valid  = '0;
                        rd_r  = rd_dec;
                        rob_entry_o.regf_we = 1'b1;
                        rob_entry_o.rd_s = rd_r;

                        monitor_entry_o.valid = 1'b0;
                        monitor_entry_o.inst  = in;
                        monitor_entry_o.rs1_addr = rs1_s;
                        monitor_entry_o.rs2_addr = rs2_s;
                        monitor_entry_o.rd_addr = rd_r;
                        monitor_entry_o.rs1_renamed = rs1_renamed_temp;
                        monitor_entry_o.rs1_rdata = rs1_data_temp;
                        monitor_entry_o.rs2_renamed = rs2_renamed_temp;
                        monitor_entry_o.rs2_rdata = rs2_data_temp;
                        monitor_entry_o.regf_we = 1'b1;
                        monitor_entry_o.pc_rdata = pc;
                        monitor_entry_o.pc_wdata = pc + 32'h4;
                        if (!rob_full && ~rs_mul_div_full) begin
                            rs_mul_div_enqueue_o  = 1'b1;
                            rob_enqueue_o      = '1;
                            if (rd_dec != 5'd0) begin
                                reg_r = '1;
                            end
                        end
                        else begin
                            inst_dequeue = 1'b0;
                        end
                    end
                    // else begin
                    //     if (!rob_full && ~rs_div_full) begin
                    //         rs_div_enqueue_o = 1'b1;
                    //         rs_entry_o.valid      = 1'b1;
                    //         rs_entry_o.funct3     = funct3;

                    //         rs1_s = rs1_dec;
                    //         rs2_s = rs2_dec;

                    //         if (rs1_dec == 5'd0) begin
                    //             rs1_renamed_temp = 1'b0;
                    //             rs1_data_temp    = 32'd0;
                    //         end else begin
                    //             rs1_renamed_temp = rs1_renamed;
                    //             rs1_data_temp    = rs1_v;
                    //         end
                    //         if (rs2_dec == 5'd0) begin
                    //             rs2_renamed_temp = '0;
                    //             rs2_data_temp    = '0;
                    //         end else begin
                    //             rs2_renamed_temp = rs2_renamed;
                    //             rs2_data_temp    = rs2_v;
                    //         end
                    //         rs_entry_o.rs1_renamed = rs1_renamed_temp;
                    //         rs_entry_o.rs1_data    = rs1_data_temp;
                    //         rs_entry_o.rs2_renamed = rs2_renamed_temp;
                    //         rs_entry_o.rs2_data    = rs2_data_temp;
                    //         rs_entry_o.rob_id      = rob_tail;

                    //         rob_entry_o.pc     = pc;
                    //         rob_entry_o.valid  = 1'b0;
                    //         rob_enqueue_o      = 1'b1;
                    //         if (rd_dec != 5'd0) begin
                    //             reg_r = 1'b1;
                    //             rd_r  = rd_dec;
                    //             rob_r = rob_tail;
                    //             rob_entry_o.regf_we = 1'b1;
                    //             rob_entry_o.rd_s = rd_r;
                    //         end

                    //         monitor_entry_o.valid = 1'b0;
                    //         monitor_entry_o.inst  = in;
                    //         monitor_entry_o.rs1_addr = rs1_s;
                    //         monitor_entry_o.rs2_addr = rs2_s;
                    //         monitor_entry_o.rd_addr = rd_r;
                    //         monitor_entry_o.rs1_renamed = rs1_renamed_temp;
                    //         monitor_entry_o.rs1_rdata = rs1_data_temp;
                    //         monitor_entry_o.rs2_renamed = rs2_renamed_temp;
                    //         monitor_entry_o.rs2_rdata = rs2_data_temp;
                    //         monitor_entry_o.regf_we = 1'b1;
                    //         monitor_entry_o.pc_rdata = pc;
                    //         monitor_entry_o.pc_wdata = pc + 32'h4;
                    //     end
                    //     else begin
                    //         inst_dequeue = 1'b0;
                    //     end
                    // end
                end

                default: begin
                    inst_dequeue = 1'b0;
                end
            endcase
        end
    end

endmodule