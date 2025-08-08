package rv32cpu_type;
    
    typedef struct packed {
        logic   [31:0]      pc;
        logic   [31:0]      ir;
        logic   [1:0]       br_predicted;
    } instr_queue_entry_t;

    typedef struct packed {
        logic               valid;
        logic               rd_valid;
        logic               regf_we;
        logic   [4:0]       rd_s;
        logic   [31:0]      rd_v;
        logic   [31:0]      pc;
        logic               br;
        logic   [1:0]       br_predicted;
        logic               br_actual;
    } rob_entry_t;

    typedef struct packed {
        logic               valid;
        logic   [31:0]      rd_v;
        logic   [4:0]       rob_id;
    } cdb_entry_t;

    typedef struct packed {
        logic               valid;
        logic               br_en;
        logic               jalr;
        logic   [31:0]      pc_jalr;
        logic   [4:0]       rob_id;
    } br_entry_t;

    typedef struct packed {
        logic   [31:0]          inst;
        logic                   valid; // high when inst != '0
        logic   [31:0]          pc;
        logic   [4:0]           ard_s; //achitecture register addr
        logic   [2:0]           funct3;
        logic   [31:0]          imm;
        logic   [2:0]           funct; // diff functionality
        logic   [6:0]           funct7;
        logic   [4:0]           ars1_s;
        logic   [4:0]           ars2_s;
        logic   [31:0]          rs1_val;
        logic   [31:0]          rs2_val;
        logic                   regf_we;
    } decode_t;

    typedef struct packed {
        logic         valid;
        logic [2:0]   funct3;
        logic         funct7;
        logic         rs1_renamed; 
        logic [31:0]  rs1_data;
        logic         rs2_renamed; 
        logic [31:0]  rs2_data;
        logic   [4:0] rob_id;
    } rs_entry_t;

    typedef struct packed {
        logic         valid;
        logic         committed;
        logic         resolved;
        logic [2:0]   funct3;
        logic [3:0]   mask;
        logic         rs1_renamed; 
        logic [31:0]  rs1_data;
        logic         rs2_renamed; 
        logic [31:0]  rs2_data;
        logic [11:0]  imm;
        logic   [4:0] rob_id;
    } rs_store_entry_t;
    
    typedef struct packed {
        logic         valid;
        logic [2:0]   funct3;
        logic         rs1_renamed; 
        logic [31:0]  rs1_data;
        logic [11:0]  imm;
        logic         store_resolved;
        logic [3:0]   store_id;
        logic   [4:0] rob_id;
    } rs_load_entry_t;

    // typedef struct packed {
    //     logic valid;
    //     logic op_a_valid;
    //     logic [31:0] op_a_value;
    //     logic op_b_valid;
    //     logic [31:0] op_b_value;
    //     logic [2:0] op_funct3;
    //     logic       op_funct7;
    //     logic [5:0] rob_index;
    // } arith_entry_t;
    
    typedef struct packed {
        logic           valid;
        logic   [63:0]  order;
        logic   [31:0]  inst;
        logic   [4:0]   rs1_addr;
        logic   [4:0]   rs2_addr;
        logic           rs1_renamed;
        logic           rs2_renamed;
        logic   [31:0]  rs1_rdata;
        logic   [31:0]  rs2_rdata;
        logic           regf_we;
        logic   [4:0]   rd_addr;
        logic   [31:0]  rd_v;
        logic   [31:0]  pc_rdata;
        logic   [31:0]  pc_wdata;
        logic   [31:0]  mem_addr;
        logic   [3:0]   mem_rmask;
        logic   [3:0]   mem_wmask;
        logic   [31:0]  mem_rdata;
        logic   [31:0]  mem_wdata;
    } monitor_t;

    
    typedef enum logic [2:0] {
        op_f_alu     =3'b000,
        op_f_mult    =3'b001,
        op_f_div     =3'b010,
        op_f_br      =3'b011,
        op_f_load    =3'b100,
        op_f_store   =3'b101
    } funct_t;

    typedef enum logic [6:0] {
        op_b_lui       = 7'b0110111, // load upper immediate (U type)
        op_b_auipc     = 7'b0010111, // add upper immediate PC (U type)
        op_b_jal       = 7'b1101111, // jump and link (J type)
        op_b_jalr      = 7'b1100111, // jump and link register (I type)
        op_b_br        = 7'b1100011, // branch (B type)
        op_b_load      = 7'b0000011, // load (I type)
        op_b_store     = 7'b0100011, // store (S type)
        op_b_imm       = 7'b0010011, // arith ops with register/immediate operands (I type)
        op_b_reg       = 7'b0110011  // arith ops with register operands (R type)
    } rv32i_opcode;

    typedef enum logic [2:0] {
        arith_f3_add   = 3'b000, // check logic 30 for sub if op_reg op
        arith_f3_sll   = 3'b001,
        arith_f3_slt   = 3'b010,
        arith_f3_sltu  = 3'b011,
        arith_f3_xor   = 3'b100,
        arith_f3_sr    = 3'b101, // check logic 30 for logical/arithmetic
        arith_f3_or    = 3'b110,
        arith_f3_and   = 3'b111
    } arith_f3_t;

    typedef enum logic [2:0]{
        mul_f3_mul     = 3'b000,
        mul_f3_mulh    = 3'b001, // multiply high signed
        mul_f3_mulhsu  = 3'b010, // multiply high signed-unsigned
        mul_f3_mulhu   = 3'b011, // multiply high unsigned
        mul_f3_div     = 3'b100,
        mul_f3_divu    = 3'b101,
        mul_f3_rem     = 3'b110, // remainder
        mul_f3_remu    = 3'b111  // remainder unsigned
    } mul_div_f3_t;

    typedef enum logic [6:0] {
        base           = 7'b0000000,
        multiply       = 7'b0000001,
        variant        = 7'b0100000
    } funct7_t;

    typedef enum logic [2:0] {
        load_f3_lb     = 3'b000,
        load_f3_lh     = 3'b001,
        load_f3_lw     = 3'b010,
        load_f3_lbu    = 3'b100,
        load_f3_lhu    = 3'b101
    } load_f3_t;

    typedef enum logic [2:0] {
        store_f3_sb    = 3'b000,
        store_f3_sh    = 3'b001,
        store_f3_sw    = 3'b010
    } store_f3_t;

    typedef enum logic [2:0] {
        branch_f3_beq  = 3'b000,
        branch_f3_bne  = 3'b001,
        branch_f3_blt  = 3'b100,
        branch_f3_bge  = 3'b101,
        branch_f3_bltu = 3'b110,
        branch_f3_bgeu = 3'b111
    } branch_f3_t;

    typedef enum logic [2:0] {
        alu_op_add     = 3'b000,
        alu_op_sll     = 3'b001,
        alu_op_sra     = 3'b010,
        alu_op_sub     = 3'b011,
        alu_op_xor     = 3'b100,
        alu_op_srl     = 3'b101,
        alu_op_or      = 3'b110,
        alu_op_and     = 3'b111
    } alu_ops;

    typedef union packed {
        logic [31:0] word;

        struct packed {
            logic [11:0] i_imm;
            logic [4:0]  rs1;
            logic [2:0]  funct3;
            logic [4:0]  rd;
            rv32i_opcode opcode;
        } i_type;

        struct packed {
            logic [6:0]  funct7;
            logic [4:0]  rs2;
            logic [4:0]  rs1;
            logic [2:0]  funct3;
            logic [4:0]  rd;
            rv32i_opcode opcode;
        } r_type;

        struct packed {
            logic [11:5] imm_s_top;
            logic [4:0]  rs2;
            logic [4:0]  rs1;
            logic [2:0]  funct3;
            logic [4:0]  imm_s_bot;
            rv32i_opcode opcode;
        } s_type;

        struct packed {
            logic [31:25] imm_b_top;
            logic [4:0] rs2;
            logic [4:0] rs1;
            logic [2:0] funct3;
            logic [11:7] imm_b_bot;
            rv32i_opcode opcode;
        } b_type;

        struct packed {
            logic [31:12] imm;
            logic [4:0]   rd;
            rv32i_opcode  opcode;
        } j_type;

        struct packed {
            logic [31:12] imm;
            logic [4:0]   rd;
            rv32i_opcode  opcode;
        } u_type;               //lui and auipc

    } instr_t;

endpackage