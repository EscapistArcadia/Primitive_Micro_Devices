covergroup instr_cg with function sample(instr_t instr);
    // Easy covergroup to see that we're at least exercising
    // every opcode. Since opcode is an enum, this makes bins
    // for all its members.
    all_opcodes : coverpoint instr.i_type.opcode;


    // Some simple coverpoints on various instruction fields.
    // Recognize that these coverpoints are inherently less useful
    // because they really make sense in the context of the opcode itself.
    all_funct7 : coverpoint funct7_t'(instr.r_type.funct7);

    // TODO: Write the following coverpoints:

    // Check that funct3 takes on all possible values.
    all_funct3 : coverpoint instr.r_type.funct3;

    // Check that the rs1 and rs2 fields across instructions take on
    // all possible values (each register is touched).
    all_regs_rs1 : coverpoint instr.r_type.rs1;
    all_regs_rs2 : coverpoint instr.r_type.rs2;

    // Now, cross coverage takes in the opcode context to correctly
    // figure out the /actual/ coverage.
    funct3_cross : cross instr.i_type.opcode, instr.i_type.funct3 {

        // We want to ignore the cases where funct3 isn't relevant.

        // For example, for JAL, funct3 doesn't exist. Put it in an ignore_bins.
        ignore_bins JAL_FUNCT3 = funct3_cross with (instr.i_type.opcode == op_b_jal);

        // TODO:    What other opcodes does funct3 not exist for? Put those in
        // ignore_bins.
        ignore_bins LUI_FUNCT3 = funct3_cross with (instr.i_type.opcode == op_b_lui);
        ignore_bins AUIPC_FUNCT3 = funct3_cross with (instr.i_type.opcode == op_b_auipc);

        // Branch instructions use funct3, but only 6 of the 8 possible values
        // are valid. Ignore the other two -- don't add them into the coverage
        // report. In fact, if they're generated, that's an illegal instruction.
        illegal_bins BR_FUNCT3 = funct3_cross with
        (instr.i_type.opcode == op_b_br
        && !(instr.i_type.funct3 inside {branch_f3_beq, branch_f3_bne, branch_f3_blt, branch_f3_bge, branch_f3_bltu, branch_f3_bgeu}));

        // TODO: You'll also have to ignore some funct3 cases in JALR, LOAD, and
        // STORE. Write the illegal_bins/ignore_bins for those cases.
        //JALR
        illegal_bins JALR_FUNCT3 = funct3_cross with
        (instr.i_type.opcode == op_b_jalr
        && !(instr.i_type.funct3 == 0));

        //LOAD
        illegal_bins LOAD_FUNCT3 = funct3_cross with
        (instr.i_type.opcode == op_b_load
        && !(instr.i_type.funct3 inside {load_f3_lb,load_f3_lh,load_f3_lw,load_f3_lbu,load_f3_lhu}));

        //STORE
        illegal_bins STORE_FUNCT3 = funct3_cross with
        (instr.i_type.opcode == op_b_store
        && !(instr.i_type.funct3 inside {store_f3_sb,store_f3_sh,store_f3_sw}));

        illegal_bins CP3 = funct3_cross with
        (instr.i_type.opcode inside {op_b_jalr, op_b_load, op_b_store});
    }

    // Coverpoint to make separate bins for funct7.
    coverpoint instr.r_type.funct7 {
        bins range[] = {[0:$]};
        ignore_bins not_in_spec = {[1:31], [33:127]};
    }

    // Cross coverage for funct7.
    funct7_cross : cross instr.r_type.opcode, instr.r_type.funct3, instr.r_type.funct7 {

        // No opcodes except op_b_reg and op_b_imm use funct7, so ignore the rest.
        ignore_bins OTHER_INSTS = funct7_cross with
        (!(instr.r_type.opcode inside {op_b_reg, op_b_imm}));

        // TODO: Get rid of all the other cases where funct7 isn't necessary, or cannot
        // take on certain values.

        // op_b_imm (I-type) funct7 is relevant only for shifts, 
        // ignore any immediate instruction with a non-shift funct3
        ignore_bins IMM_NON_SHIFT = funct7_cross with
        ((instr.r_type.opcode == op_b_imm) && !(instr.r_type.funct3 inside {arith_f3_sll, arith_f3_sr}));
        
        // I-type SHIFT instructions only funct7 = 0000000 or 0100000 is valid (logical vs. arithmetic shift)
        illegal_bins IMM_SHIFT_INVALID_FUNCT7 = funct7_cross with
        (instr.r_type.opcode == op_b_imm && instr.r_type.funct3 inside {arith_f3_sll, arith_f3_sr}
         && !(instr.r_type.funct7 inside {base, variant}));

        // SLLI with variant funct7 is not a valid encoding
        illegal_bins SLL_FUNCT7 = funct7_cross with 
        (instr.r_type.opcode == op_b_imm && instr.r_type.funct3 == arith_f3_sll && instr.r_type.funct7 == variant);

        // R-type only certain combinations of funct3/funct7 are valid (ADD/SUB, SLL, SRL/SRA, SLT, SLTU, XOR, OR, AND
        illegal_bins REG_FUNCT7 = funct7_cross with
        (instr.r_type.opcode == op_b_reg && ! (instr.r_type.funct7 inside {base, multiply, variant}));

        // certain funct3 values are valid (SUB, SRA)
        illegal_bins REG_FUNCT7_BASE = funct7_cross with
        (instr.r_type.opcode == op_b_reg  && !(instr.r_type.funct7 == base)  && !(instr.r_type.funct3 inside {arith_f3_add, arith_f3_sr}));

        ignore_bins IMM_MULDIV_FUNCT7 = funct7_cross with
        (instr.r_type.opcode==op_b_imm && instr.r_type.funct7==multiply);
    }

endgroup : instr_cg
