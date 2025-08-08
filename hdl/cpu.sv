module cpu
import rv32cpu_type::*;
(
    input   logic               clk,
    input   logic               rst,

    output  logic   [31:0]      bmem_addr,                                          // memory address to access
    output  logic               bmem_read,                                          // read operation
    output  logic               bmem_write,                                         // write operation
    output  logic   [63:0]      bmem_wdata,                                         // data to write, output serially
    input   logic               bmem_ready,                                         // TODO: default 1?

    input   logic   [31:0]      bmem_raddr,                                         // memory address finished reading
    input   logic   [63:0]      bmem_rdata,                                         // data finished reading
    input   logic               bmem_rvalid                                          // read response,
);
    logic full, empty[2];

    localparam INDEX_WIDTH = 5;
    localparam ROB_SIZE = 1<<INDEX_WIDTH;
    localparam CDB_WIDTH = 4;

    logic   [31:0]      fetch_pc, fetch_pc_curr;                            // PC we currently access from memory
    logic   [255:0]     fetch_ir;                                           // for debug only
    
    logic               iq_enqueue;
    logic               flush_actual;
    logic   [31:0]      pc_predicted, pc_actual;                            // predicted PC

    logic   [31:0]      icache_dfp_addr, dcache_dfp_addr, dcache_ufp_addr, dcache_ufp_rdata, dcache_ufp_wdata;                                  // IMEM cache dfp
    logic               icache_dfp_read, icache_dfp_write, dcache_dfp_read, dcache_dfp_write;
    logic   [255:0]     icache_dfp_rdata, icache_dfp_wdata, dcache_dfp_rdata, dcache_dfp_wdata;
    logic               icache_dfp_resp, icache_ufp_resp, icache_busy, dcache_dfp_resp, dcache_ufp_resp, dcache_busy;
    logic   [3:0]       imem_rmask, dmem_rmask, dmem_wmask;                                      // read mask for IMEM and DMEM

    logic [31:0] icache_bmem_addr, dcache_bmem_addr;
    logic        icache_bmem_read, icache_bmem_write, dcache_bmem_read, dcache_bmem_write;
    logic [63:0] icache_bmem_wdata, dcache_bmem_wdata;
    logic        icache_bmem_ready, dcache_bmem_ready;
    logic [31:0] icache_bmem_raddr, dcache_bmem_raddr;
    logic [63:0] icache_bmem_rdata, dcache_bmem_rdata;
    logic        icache_bmem_rvalid, dcache_bmem_rvalid;
    logic        icache_bmem_resp, dcache_bmem_resp;
    logic        icache_bmem_resp_valid, dcache_bmem_resp_valid;

    logic [4:0] rs1_s[2], rs2_s[2];
    logic [31:0] rs1_v[2], rs2_v[2];
    logic rs1_renamed[2], rs2_renamed[2];
    logic reg_r[2], reg_r1;
    logic [4:0] rd_r[2];
    logic [INDEX_WIDTH-1:0] rob_r[2];
    logic [INDEX_WIDTH-1:0] rob_tail, rob_head;
    logic rob_full[2];
    logic rob_enqueue_o[2], rob_enqueue_o1;
    rs_entry_t      rs_entry[2];
    rs_load_entry_t  rs_load_entry[2];
    rs_store_entry_t rs_store_entry[2];
    br_entry_t      br_entry;
    logic rs_mul_div_enqueue_o[2], rs_alu_enqueue_o[2], rs_mem_enqueue_o[2], rs_br_enqueue_o[2], rs_mul_div_enqueue_o1, rs_alu_enqueue_o1, rs_mem_enqueue_o1, rs_br_enqueue_o1;
    rob_entry_t     rob_entry_o[2];
    decode_t decode_o;

    cdb_entry_t             cdb_out[CDB_WIDTH], cdb_in[CDB_WIDTH], alu_out[2], mul_div_out, mem_out;
    logic [31:0]            rob1_v[2], rob2_v[2];
    logic [INDEX_WIDTH-1:0] rob1_s[2], rob2_s[2], rob_w[2];
    logic                   rob1_r[2], rob2_r[2];
    rob_entry_t             data_out[2];
    logic                   commit[2];

    logic                   dequeue[2], dequeue1;

    logic [4:0] rd_s[1];
    logic [31:0] rd_v[1];

    logic [7:0] inst_mask;

    logic rs_alu_full[2], rs_mul_div_full[2], rs_load_full[2], rs_store_full[2], rs_br_full[2];


    instr_queue_entry_t in[8], out[2];

    monitor_t monitor_entry_i[2];

    assign cdb_in[0] = alu_out[0];
    assign cdb_in[1] = alu_out[1];
    
    assign cdb_in[2] = mul_div_out;

    assign cdb_in[3] = mem_out;

    assign reg_r[1] = reg_r1 & rob_enqueue_o[0];
    assign rs_mul_div_enqueue_o[1] = rs_mul_div_enqueue_o1 & rob_enqueue_o[0];
    assign rs_alu_enqueue_o[1] = rs_alu_enqueue_o1 & rob_enqueue_o[0];
    assign rs_mem_enqueue_o[1] = rs_mem_enqueue_o1 & rob_enqueue_o[0];
    assign rs_br_enqueue_o[1] = rs_br_enqueue_o1 & rob_enqueue_o[0];
    assign rob_enqueue_o[1] = rob_enqueue_o1 & rob_enqueue_o[0];
    assign dequeue[1] = dequeue1 & rob_enqueue_o[0];

    cache_adapter icache_adapter (                                                   // pack and unpack data between cache and memory
        .clk,
        .rst,

        .dfp_addr(icache_dfp_addr),
        .dfp_read(icache_dfp_read),
        .dfp_write(icache_dfp_write),
        .dfp_rdata(icache_dfp_rdata),
        .dfp_wdata(icache_dfp_wdata),
        .dfp_resp(icache_dfp_resp),

        .cache_bmem_addr (icache_bmem_addr),
        .cache_bmem_read (icache_bmem_read),
        .cache_bmem_write(icache_bmem_write),
        .cache_bmem_wdata(icache_bmem_wdata),
        .cache_bmem_ready(icache_bmem_ready),
        .cache_bmem_raddr(icache_bmem_raddr),
        .cache_bmem_rdata(icache_bmem_rdata),
        .cache_bmem_rvalid(icache_bmem_rvalid)
    );

    cache_adapter dcache_adapter (                                                   // pack and unpack data between cache and memory
        .clk,
        .rst,

        .dfp_addr(dcache_dfp_addr),
        .dfp_read(dcache_dfp_read),
        .dfp_write(dcache_dfp_write),
        .dfp_rdata(dcache_dfp_rdata),
        .dfp_wdata(dcache_dfp_wdata),
        .dfp_resp(dcache_dfp_resp),

        .cache_bmem_addr (dcache_bmem_addr),
        .cache_bmem_read (dcache_bmem_read),
        .cache_bmem_write(dcache_bmem_write),
        .cache_bmem_wdata(dcache_bmem_wdata),
        .cache_bmem_ready(dcache_bmem_ready),
        .cache_bmem_raddr(dcache_bmem_raddr),
        .cache_bmem_rdata(dcache_bmem_rdata),
        .cache_bmem_rvalid(dcache_bmem_rvalid)
    );

    cache_arbiter cache_arbiter(
        // .clk,
        // .rst,

        .icache_bmem_addr   (icache_bmem_addr),
        .icache_bmem_read   (icache_bmem_read),
        .icache_bmem_write  (icache_bmem_write),
        .icache_bmem_wdata  (icache_bmem_wdata),
        .icache_bmem_ready  (icache_bmem_ready),
        .icache_bmem_raddr  (icache_bmem_raddr),
        .icache_bmem_rdata  (icache_bmem_rdata),
        .icache_bmem_rvalid (icache_bmem_rvalid),

        .dcache_bmem_addr   (dcache_bmem_addr),
        .dcache_bmem_read   (dcache_bmem_read),
        .dcache_bmem_write  (dcache_bmem_write),
        .dcache_bmem_wdata  (dcache_bmem_wdata),
        .dcache_bmem_ready  (dcache_bmem_ready),
        .dcache_bmem_raddr  (dcache_bmem_raddr),
        .dcache_bmem_rdata  (dcache_bmem_rdata),
        .dcache_bmem_rvalid (dcache_bmem_rvalid),

        .arbiter_bmem_addr          (bmem_addr),
        .arbiter_bmem_read          (bmem_read),
        .arbiter_bmem_write         (bmem_write),
        .arbiter_bmem_wdata         (bmem_wdata),
        .arbiter_bmem_ready         (bmem_ready),
        .arbiter_bmem_raddr         (bmem_raddr),
        .arbiter_bmem_rdata         (bmem_rdata),
        .arbiter_bmem_rvalid        (bmem_rvalid)
    );

    icache icache (
        .clk,
        .rst,

        .ufp_addr                               (fetch_pc),
        .ufp_rmask                              (imem_rmask),
        .ufp_wmask                              ('0),
        .ufp_rdata                              (fetch_ir),
        .ufp_wdata                              ('0),
        .ufp_resp                               (icache_ufp_resp),

        .dfp_addr                               (icache_dfp_addr),
        .dfp_read                               (icache_dfp_read),
        .dfp_write                              (icache_dfp_write),
        .dfp_rdata                              (icache_dfp_rdata),
        .dfp_wdata                              (icache_dfp_wdata),
        .dfp_resp                               (icache_dfp_resp)
    );

    dcache dcache (
        .clk,
        .rst,

        .ufp_addr                               (dcache_ufp_addr),
        .ufp_rmask                              (dmem_rmask),
        .ufp_wmask                              (dmem_wmask),
        .ufp_rdata                              (dcache_ufp_rdata),
        .ufp_wdata                              (dcache_ufp_wdata),
        .ufp_resp                               (dcache_ufp_resp),

        .dfp_addr                               (dcache_dfp_addr),
        .dfp_read                               (dcache_dfp_read),
        .dfp_write                              (dcache_dfp_write),
        .dfp_rdata                              (dcache_dfp_rdata),
        .dfp_wdata                              (dcache_dfp_wdata),
        .dfp_resp                               (dcache_dfp_resp)
    );

    logic fetch_valid, dirty;
    logic [2:0] fetch_pc_offset;
    logic [1:0] fetch_counter;

    logic br_valid, br_en_o, br_actual;
    logic [1:0] br_counter;
    logic [31:0] br_pc_curr;
    
    fetch fetch(
        .clk,
        .rst,
        .if_stall_i                             (full),
        .if_flush_i                             (flush_actual),
        .if_pc_i                                (pc_actual), // only effective if either flush is 1
        .imem_resp_i                            (icache_ufp_resp),
        .imem_data_i                            (fetch_ir),

        .bp_dirty                               (dirty),
        .bp_counter                             (fetch_counter),

        .inst_queue_entry_o                     (in),
        .inst_mask                              (inst_mask),
        .imem_addr                              (fetch_pc),
        .imem_rmask                             (imem_rmask),
        .iq_enqueue_o                           (iq_enqueue),
        .br_en_o                                (br_en_o),

        .fetch_pc_offset_o                      (fetch_pc_offset)
    );

    gshare_predictor #(
        .GHR_WIDTH(9)
    ) branch_predictor (
        .clk(clk),
        .rst(rst),
        .flush(flush_actual),
        
        .fetch_pc(fetch_pc),
        .fetch_valid('1),
        .fetch_br_offset(fetch_pc_offset),
        .fetch_counter(fetch_counter),
        .dirty(dirty),

        .spec_br(in[fetch_pc_offset].br_predicted),
        .spec_valid(iq_enqueue & ~full & br_en_o),

        .br_valid(br_valid),
        .br_actual(br_actual),
        .br_counter(br_counter),
        .br_curr_pc(br_pc_curr)
    );

    instruction_queue #(
        .QUEUE_SIZE(16)
    ) instruction_queue (
        .clk,
        .rst,
        .flush                                  (flush_actual),

        .inst_mask                              (inst_mask),
        .enqueue                                (iq_enqueue),
        .data_in                                (in),
        .dequeue                                (dequeue),
        .data_out                               (out),

        .full,
        .empty
    );

    reorder #(
        .INDEX_WIDTH(INDEX_WIDTH),
        .DISPATCH_WIDTH(2),
        .WRITE_PORTS(CDB_WIDTH)
    ) reorder_buffer (
        .clk,
        .rst,

        .enqueue                                (rob_enqueue_o),
        .data_in                                (rob_entry_o),
        .commit                                 (commit),
        .data_out                               (data_out),

        .rob_head                               (rob_head),
        .rob_tail                               (rob_tail),

        .cdb_in                                 (cdb_out),
        .br_in                                  (br_entry),

        .rob1_s                                  (rob1_s),
        .rob2_s                                  (rob2_s),
        .rob1_v                                  (rob1_v),
        .rob2_v                                  (rob2_v),
        .rob1_r                                  (rob1_r),
        .rob2_r                                  (rob2_r),

        .monitor_entry_i                         (monitor_entry_i),
        // .monitor_entry_o                         (monitor_entry_o),

        .flush_valid                            (br_valid),
        .br_actual                              (br_actual),
        .flush                                  (flush_actual),
        .pc_flush                               (pc_actual),
        .pc_curr                                (br_pc_curr),
        .flush_counter                          (br_counter),

        .full                                   (rob_full)
    );


    regfile #(
        .INDEX_WIDTH(INDEX_WIDTH),
        .COMMIT_PORTS(2),
        .WRITE_PORTS(CDB_WIDTH)
    ) regfile (
        .clk,
        .rst,
        .flush                                  (flush_actual),

        .rs1_s                                  (rs1_s),
        .rs2_s                                  (rs2_s),
        .rs1_v                                  (rs1_v),
        .rs2_v                                  (rs2_v),
        .rd_r                                   (rd_r),
        .rob_w                                  (rob_head),
        .rob_r                                  (rob_r),
        .rob1_v                                 (rob1_v),
        .rob2_v                                 (rob2_v),
        .rob1_r                                 (rob1_r),
        .rob2_r                                 (rob2_r),
        .cdb_in                                 (cdb_out),
        .rob1_s                                 (rob1_s),
        .rob2_s                                 (rob2_s),
        .rob_in                                 (data_out),
        .reg_r                                  (reg_r),
        .rs1_renamed                            (rs1_renamed),
        .rs2_renamed                            (rs2_renamed),
        .fwd_data                               (rob_entry_o[0].rd_v),
        .fwd_valid                              (rob_entry_o[0].rd_valid)
    );

    cdb_arbiter #(
        //.CDB_WIDTH(CDB_WIDTH),
        .FUNC_UNITS(CDB_WIDTH),
        .INDEX_WIDTH(INDEX_WIDTH)
    ) cdb_arbiter (
        .clk,
        .rst                                    (rst | flush_actual),

        .cdb_in                                 (cdb_in),
        .cdb_out                                (cdb_out)
    );

    decode_dispatch #(
        .INDEX_WIDTH(INDEX_WIDTH)
    ) decode_dispatch_i1 (
        .in              (out[0].ir),
        .pc              (out[0].pc),
        .br_predicted    (out[0].br_predicted),
        .inst_empty      (empty[0]),
        .rob_full        (rob_full[0]),
        .rob_tail        (rob_tail),
        .rs_alu_full     (rs_alu_full[0]),
        .rs_mul_div_full (rs_mul_div_full[0]),
        .rs_load_full    (rs_load_full[0]),
        .rs_store_full   (rs_store_full[0]),
        .rs_br_full      (rs_br_full[0]),
        .rs1_renamed     (rs1_renamed[0]),
        .rs2_renamed     (rs2_renamed[0]),
        .rs1_v           (rs1_v[0]),
        .rs2_v           (rs2_v[0]),
        .rs_entry_o      (rs_entry[0]),
        .rs_load_entry_o (rs_load_entry[0]),
        .rs_store_entry_o(rs_store_entry[0]),
        .rob_entry_o     (rob_entry_o[0]),
        .monitor_entry_o (monitor_entry_i[0]),
        .rob_enqueue_o   (rob_enqueue_o[0]),
        .rs_alu_enqueue_o(rs_alu_enqueue_o[0]),
        .rs_mul_div_enqueue_o(rs_mul_div_enqueue_o[0]),
        .rs_mem_enqueue_o(rs_mem_enqueue_o[0]),
        .rs_br_enqueue_o (rs_br_enqueue_o[0]),
        .rs1_s           (rs1_s[0]),
        .rs2_s           (rs2_s[0]),
        .reg_r           (reg_r[0]),
        .rd_r            (rd_r[0]),
        .rob_r           (rob_r[0]),
        .inst_dequeue    (dequeue[0])
    );
    
    decode_dispatch #(
        .INDEX_WIDTH(INDEX_WIDTH)
    ) decode_dispatch_i2 (
        .in              (out[1].ir),
        .pc              (out[1].pc),
        .br_predicted    (out[1].br_predicted),
        .inst_empty      (empty[1]),
        .rob_full        (rob_full[1]),
        .rob_tail        (rob_tail + 1'b1),
        .rs_alu_full     (rs_alu_full[1]),
        .rs_mul_div_full (rs_mul_div_full[1]),
        .rs_load_full    (rs_load_full[1]),
        .rs_store_full   (rs_store_full[1]),
        .rs_br_full      (rs_br_full[1]),
        .rs1_renamed     (rs1_renamed[1]),
        .rs2_renamed     (rs2_renamed[1]),
        .rs1_v           (rs1_v[1]),
        .rs2_v           (rs2_v[1]),
        .rs_entry_o      (rs_entry[1]),
        .rs_load_entry_o (rs_load_entry[1]),
        .rs_store_entry_o(rs_store_entry[1]),
        .rob_entry_o     (rob_entry_o[1]),
        .monitor_entry_o (monitor_entry_i[1]),
        .rob_enqueue_o   (rob_enqueue_o1),
        .rs_alu_enqueue_o(rs_alu_enqueue_o1),
        .rs_mul_div_enqueue_o(rs_mul_div_enqueue_o1),
        .rs_mem_enqueue_o(rs_mem_enqueue_o1),
        .rs_br_enqueue_o (rs_br_enqueue_o1),
        .rs1_s           (rs1_s[1]),
        .rs2_s           (rs2_s[1]),
        .reg_r           (reg_r1),
        .rd_r            (rd_r[1]),
        .rob_r           (rob_r[1]),
        .inst_dequeue    (dequeue1)
    );
    
    arithmetic_station #(
        .INDEX_WIDTH(4),
        .WRITE_PORTS_IN(CDB_WIDTH),
        .FUNC_UNITS(2)
    ) arithmetic_station (
        .clk,
        .rst(rst | flush_actual),

        .enqueue(rs_alu_enqueue_o),
        .data_in(rs_entry),

        .broadcast(cdb_out),

        .data_out(alu_out),

        .full(rs_alu_full)
    );

    multiply_divide_station #(
        .INDEX_WIDTH(3),
        .STAGE_COUNT(10),
        .WRITE_PORTS_IN(CDB_WIDTH)
    ) mul_div_station (
        .clk,
        .rst(rst | flush_actual),

        .enqueue(rs_mul_div_enqueue_o),
        .data_in(rs_entry),

        .broadcast(cdb_out),

        .data_out(mul_div_out),

        .full(rs_mul_div_full)
    );

    memory_station #(
        .INDEX_WIDTH(3),
        .ROB_INDEX_WIDTH(INDEX_WIDTH),
        .WRITE_PORTS_IN(CDB_WIDTH)
    ) memory_station (
        .clk,
        .rst,
        .enqueue            (rs_mem_enqueue_o),
        .data_in_load       (rs_load_entry),
        .data_in_store      (rs_store_entry),
        .broadcast          (cdb_out),
        //.cache_busy         (dcache_busy),
        .cache_ufp_resp     (dcache_ufp_resp),
        .commit             (commit),
        .flush              (flush_actual),
        .commit_rob_id      (rob_head),
        .cache_ufp_addr     (dcache_ufp_addr),
        .cache_ufp_rmask    (dmem_rmask),
        .cache_ufp_wmask    (dmem_wmask),
        .cache_ufp_wdata    (dcache_ufp_wdata),
        .cache_ufp_rdata    (dcache_ufp_rdata),
        .data_out           (mem_out),
        .store_full         (rs_store_full),
        .load_full          (rs_load_full)
    );

    branch_station #(
        .INDEX_WIDTH(3),
        .WRITE_PORTS_IN(CDB_WIDTH)
    ) branch_station (
        .clk,
        .rst(rst | flush_actual),

        .enqueue            (rs_br_enqueue_o),
        .data_in            (rs_entry),
        .broadcast          (cdb_out),

        .br_out             (br_entry),

        .full               (rs_br_full)
    );

    // commit rvfi_commit(
    //     // .clk,
    //     // .rst,

    //     .data_out(data_out[0]),
    //     .inst(monitor_entry_o.inst),
    //     .valid(),
    //     .order(),
    //     .pc_o(),
    //     .regf_we(regf_we[0]),
    //     .rd_s(rd_s[0]),
    //     .rd_v(rd_v[0])
    // );

    // logic           rvfi_valid;
    // logic   [63:0]  rvfi_order;
    // logic   [31:0]  rvfi_inst;
    // logic   [4:0]   rvfi_rs1_addr;
    // logic   [4:0]   rvfi_rs2_addr;
    // logic   [31:0]  rvfi_rs1_rdata;
    // logic   [31:0]  rvfi_rs2_rdata;
    // logic   [4:0]   rvfi_rd_addr;
    // logic   [31:0]  rvfi_rd_v;
    // logic   [31:0]  rvfi_pc_rdata;
    // logic   [31:0]  rvfi_pc_wdata;
    // logic   [31:0]  rvfi_mem_addr;
    // logic   [3:0]   rvfi_mem_rmask;
    // logic   [3:0]   rvfi_mem_wmask;
    // logic   [31:0]  rvfi_mem_rdata;
    // logic   [31:0]  rvfi_mem_wdata;

    // always_comb begin
    //     rvfi_valid = monitor_entry_o.valid;
    //     rvfi_order = monitor_entry_o.order;
    //     rvfi_inst  = monitor_entry_o.inst;
    //     rvfi_rs1_addr = monitor_entry_o.rs1_addr;
    //     rvfi_rs2_addr = monitor_entry_o.rs2_addr;
    //     rvfi_rs1_rdata = monitor_entry_o.rs1_rdata;
    //     rvfi_rs2_rdata = monitor_entry_o.rs2_rdata;
    //     rvfi_rd_addr = monitor_entry_o.rd_addr;
    //     rvfi_rd_v = monitor_entry_o.rd_v;
    //     rvfi_pc_rdata = monitor_entry_o.pc_rdata;
    //     rvfi_pc_wdata = monitor_entry_o.pc_wdata;
    //     rvfi_mem_addr = monitor_entry_o.mem_addr;
    //     rvfi_mem_rmask = monitor_entry_o.mem_rmask;
    //     rvfi_mem_wmask = monitor_entry_o.mem_wmask;
    //     rvfi_mem_rdata = monitor_entry_o.mem_rdata;
    //     rvfi_mem_wdata = monitor_entry_o.mem_wdata;
    // end

endmodule : cpu