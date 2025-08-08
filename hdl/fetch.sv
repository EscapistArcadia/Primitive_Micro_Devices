module fetch
import rv32cpu_type::*;
(
    input  logic         clk,
    input  logic         rst,
    input  logic         if_stall_i,
    input  logic         if_flush_i,
    input  logic [31:0]  if_pc_i,
    input  logic         imem_resp_i,
    input  logic [255:0] imem_data_i,
    
    input  logic         bp_dirty,
    input  logic [1:0]   bp_counter,

    output instr_queue_entry_t inst_queue_entry_o[8], 
    output logic [7:0]   inst_mask,
    output logic [31:0]  imem_addr,
    output logic [3:0]   imem_rmask,
    output logic         iq_enqueue_o,
    output logic         br_en_o,

    output logic [2:0]   fetch_pc_offset_o
);
  logic [31:0] pc, pc_n, pc_c, pc_f, inst0, inst1;
  logic        flush, br_en;
  logic [2:0]  tree1[4], tree2[2];
  logic        treev1[4], treev2[2];

  logic         imem_resp;
  logic [255:0] imem_data;

  always_ff @(posedge clk) begin
    imem_resp <= imem_resp_i;
    imem_data <= imem_data_i;

    if (rst) begin
      pc <= 32'haaaaa000; // Reset initial address.
      br_en <= 1'b0;
      imem_resp <= 1'b0;
      imem_data <= 256'b0;
    end
    else if (!if_stall_i && imem_resp) begin
      if(br_en) begin
        pc <= pc_f;
        br_en <= 1'b0;
      end
      else if(if_flush_i) begin
        pc <= if_pc_i;
      end
      else if(flush)begin
        pc <= pc_n;
      end
      else begin
        pc <= (pc & 32'hffffffe0) + 32'h20;
      end
    end

    if(if_flush_i) begin
      br_en <= 1'b1;
      pc_f <= if_pc_i;
    end
  end

  always_comb begin
    inst_queue_entry_o = '{default:0};
    iq_enqueue_o = imem_resp;
    imem_rmask = 4'b1111;
    flush = 1'b0;
    pc_c = pc & 32'hffffffe0;
    pc_n = '0;
    inst_mask = 8'b11111111 << pc[4:2];
    tree1 = '{default:0};
    tree2 = '{default:0};
    treev1 = '{default:0};
    treev2 = '{default:0};
    br_en_o = '0;
    fetch_pc_offset_o = '0;

    for(integer unsigned i = 0; i < 8; i+=2) begin
      if((imem_data[i*32+:7] == op_b_jal || imem_data[i*32+:7] == op_b_br) & inst_mask[i]) begin
        tree1[i/2] = 3'(i);
        treev1[i/2] = 1'b1;
      end
      else if((imem_data[(i+1)*32+:7] == op_b_jal || imem_data[(i+1)*32+:7] == op_b_br) & inst_mask[i+1]) begin
        tree1[i/2] = 3'(i)+1'b1;
        treev1[i/2] = 1'b1;
      end
    end

    for(integer unsigned i = 0; i < 4; i+=2) begin
      if(treev1[i]) begin
        tree2[i/2] = tree1[i];
        treev2[i/2] = 1'b1;
      end
      else if(treev1[i+1'b1]) begin
        tree2[i/2] = tree1[i+1'b1];
        treev2[i/2] = 1'b1;
      end
    end

    inst0 = imem_data[tree2[0]*32+:32];
    inst1 = imem_data[tree2[1]*32+:32];

    if(treev2[1]) begin
      fetch_pc_offset_o = tree2[1];
      flush = 1'b1;
      if(imem_data[tree2[1]*32+:7] == op_b_br) begin // B-type
        br_en_o = 1'b1;
        pc_n = pc_c + {{20{inst1[31]}}, inst1[7], inst1[30:25], inst1[11:8], 1'b0} + {tree2[1], 2'b00};
        if(bp_dirty & ~bp_counter[1] || ~bp_dirty & ~inst1[31]) begin
          pc_n = pc_c + {tree2[1], 2'b00} + 3'h4;
        end
        inst_queue_entry_o[tree2[1]].br_predicted = bp_dirty ? bp_counter : {inst1[31], ~inst1[31]};
      end
      if(imem_data[tree2[1]*32+:7] == op_b_jal) begin // J-type
        br_en_o = 1'b0;
        pc_n = pc_c + {{12{inst1[31]}}, inst1[19:12], inst1[20], inst1[30:21], 1'b0} + {tree2[1], 2'b00};
      end
      inst_mask = inst_mask & ~{8'b11111110 << tree2[1]};
    end

    if(treev2[0]) begin
      fetch_pc_offset_o = tree2[0];
      flush = 1'b1;
      if(imem_data[tree2[0]*32+:7] == op_b_br) begin // B-type
        br_en_o = 1'b1;
        pc_n = pc_c + {{20{inst0[31]}}, inst0[7], inst0[30:25], inst0[11:8], 1'b0} + {tree2[0], 2'b00};
        if(bp_dirty & ~bp_counter[1] || ~bp_dirty & ~inst0[31]) begin
          pc_n = pc_c + {tree2[0], 2'b00} + 3'h4;
        end
        inst_queue_entry_o[tree2[0]].br_predicted = bp_dirty ? bp_counter : {inst0[31], ~inst0[31]};
      end
      if(imem_data[tree2[0]*32+:7] == op_b_jal) begin // J-type
        br_en_o = 1'b0;
        pc_n = pc_c + {{12{inst0[31]}}, inst0[19:12], inst0[20], inst0[30:21], 1'b0} + {tree2[0], 2'b00};
      end
      inst_mask = inst_mask & ~{8'b11111110 << tree2[0]};
    end

    for (integer unsigned i = 0; i < 8; i++) begin
      inst_queue_entry_o[i].pc = pc_c + {3'(i), 2'b00};
      inst_queue_entry_o[i].ir = imem_data[i*32+:32];
    end

    if (~imem_resp || br_en) begin
      inst_mask = 8'b00000000;
      br_en_o = 1'b0;
    end

    if (!if_stall_i && imem_resp) begin
      if(br_en) begin
        imem_addr = pc_f;
      end
      else if(if_flush_i) begin
        imem_addr = if_pc_i;
      end
      else if(flush)begin
        imem_addr = pc_n;
      end
      else begin
        imem_addr = (pc & 32'hffffffe0) + 32'h20;
      end
    end
    else begin
      imem_addr = (pc & 32'hffffffe0);
    end
  end

endmodule