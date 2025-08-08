module memory_station
import rv32cpu_type::*;
#(
    parameter INDEX_WIDTH,                                                          // index width of the queue
    parameter ROB_INDEX_WIDTH,
    parameter WRITE_PORTS_IN,                                                        // number of CDB entries broadcasted
    localparam QUEUE_SIZE = 1 << INDEX_WIDTH         
)
(
    input logic             clk,
    input logic             rst,

    // // input data from instruction dispatcher
    input logic             enqueue[2],
    input rs_load_entry_t   data_in_load[2],
    input rs_store_entry_t  data_in_store[2],

    // input data from reorder buffer broadcast
    input cdb_entry_t       broadcast[WRITE_PORTS_IN],

    //input logic             cache_busy,
    input logic             cache_ufp_resp,
    input logic             commit[2],
    input logic             flush,
    input logic  [ROB_INDEX_WIDTH-1:0] commit_rob_id,

    output logic [31:0]     cache_ufp_addr,
    output logic [3:0]      cache_ufp_rmask,
    output logic [3:0]      cache_ufp_wmask,
    output logic [31:0]     cache_ufp_wdata,
    input  logic [31:0]     cache_ufp_rdata,

    // // output data to reorder buffer
    output cdb_entry_t      data_out,

    output logic            store_full[2],
    output logic            load_full[2]
);

rs_load_entry_t         load_slots[QUEUE_SIZE];
rs_store_entry_t        store_slots[QUEUE_SIZE];
logic [31:0]            cache_addr, cache_wdata, pending_addr, store_buf_data, store_buf_data_wr;
logic [INDEX_WIDTH-1:0] vacant[2], issue, pending_store_id;
logic [INDEX_WIDTH:0]   head, tailn, tail, committed_store_pointer, tail_next, resolved_store_pointer;
logic [ROB_INDEX_WIDTH-1:0] pending_rob_id;
logic                   store_empty, load_assigned, wraparound, cmp, pending_load, cache_busy;
logic [3:0]             store_buf_mask, store_buf_mask_wr, cache_rmask, cache_wmask;
logic [2:0]             pending_funct3;
logic [31:0]            load_rdata;
logic [1:0]             mask_offset_store;
logic [31:0]            warning_eraser;

always_comb begin
    store_empty = (head == tail);                   
    load_full = '{default:1};
    vacant = '{default:0};
    load_assigned = '0;
    cmp = '0;
    store_buf_mask = '0;
    store_buf_data = '0;
    store_buf_mask_wr = '0;
    store_buf_data_wr = '0;
    data_out = '0;
    issue = '0;
    tail_next = tail;
    tailn = tail + 1'b1;

    store_full[0] = (head[INDEX_WIDTH] != tail[INDEX_WIDTH]) && (head[INDEX_WIDTH - 1:0]== tail[INDEX_WIDTH - 1:0]);
    store_full[1] = (head[INDEX_WIDTH] != tailn[INDEX_WIDTH]) && (head[INDEX_WIDTH - 1:0] == tailn[INDEX_WIDTH - 1:0]) || 
                    (head[INDEX_WIDTH] != tail[INDEX_WIDTH]) && (head[INDEX_WIDTH - 1:0] == tail[INDEX_WIDTH - 1:0]);

    for (integer unsigned i = 0; i < 2; i++) begin
        if (enqueue[i] && data_in_store[i].valid) begin
            tail_next = tail_next + 1'b1;
        end
    end
    
    for(integer unsigned i = '0; i < QUEUE_SIZE; i = i + 1'b1) begin
        warning_eraser = i;
        if (!load_slots[i].valid) begin
            load_full[1] = load_full[0];
            load_full[0] = 1'b0;
            vacant[1] = vacant[0];
            vacant[0] = warning_eraser[INDEX_WIDTH-1:0];
        end
        if(load_slots[i].valid && load_slots[i].store_resolved && ~load_slots[i].rs1_renamed) begin
            load_assigned = 1'b1;
            issue = warning_eraser[INDEX_WIDTH-1:0];
        end
    end


    for(integer unsigned i = '0; i < QUEUE_SIZE; i = i + 1'b1) begin
        warning_eraser = i;
        if(warning_eraser[INDEX_WIDTH-1:0]==head[INDEX_WIDTH-1:0]) begin
            cmp = 1'b1;
        end
        if(warning_eraser[INDEX_WIDTH-1:0]==pending_store_id) begin
            cmp = 1'b0;
        end

        if(cmp&&{store_slots[i].rs1_data[31:2], 2'b0}==cache_addr) begin
            store_buf_mask = store_buf_mask | store_slots[i].mask;
            store_buf_data = store_buf_data & ~{{8{store_slots[i].mask[3]}}, {8{store_slots[i].mask[2]}}, {8{store_slots[i].mask[1]}}, {8{store_slots[i].mask[0]}}} | 
                            store_slots[i].rs2_data & {{8{store_slots[i].mask[3]}}, {8{store_slots[i].mask[2]}}, {8{store_slots[i].mask[1]}}, {8{store_slots[i].mask[0]}}};
        end
    end

    for(integer unsigned i = '0; i < QUEUE_SIZE; i = i + 1'b1) begin
        warning_eraser = i;
        if(warning_eraser[INDEX_WIDTH-1:0]==pending_store_id) begin
            break;
        end

        if({store_slots[i].rs1_data[31:2], 2'b0}==cache_addr) begin
            store_buf_mask_wr = store_buf_mask_wr | store_slots[i].mask;
            store_buf_data_wr = store_buf_data_wr & ~{{8{store_slots[i].mask[3]}}, {8{store_slots[i].mask[2]}}, {8{store_slots[i].mask[1]}}, {8{store_slots[i].mask[0]}}} | 
                            store_slots[i].rs2_data & {{8{store_slots[i].mask[3]}}, {8{store_slots[i].mask[2]}}, {8{store_slots[i].mask[1]}}, {8{store_slots[i].mask[0]}}};
        end
    end

    if(wraparound) begin
        store_buf_mask = store_buf_mask | store_buf_mask_wr;
        store_buf_data = store_buf_data & ~{{8{store_buf_mask_wr[3]}}, {8{store_buf_mask_wr[2]}}, {8{store_buf_mask_wr[1]}}, {8{store_buf_mask_wr[0]}}} | 
                        store_buf_data_wr & {{8{store_buf_mask_wr[3]}}, {8{store_buf_mask_wr[2]}}, {8{store_buf_mask_wr[1]}}, {8{store_buf_mask_wr[0]}}};
    end

    load_rdata = cache_ufp_rdata & ~{{8{store_buf_mask[3]}}, {8{store_buf_mask[2]}}, {8{store_buf_mask[1]}}, {8{store_buf_mask[0]}}} | 
                    store_buf_data & {{8{store_buf_mask[3]}}, {8{store_buf_mask[2]}}, {8{store_buf_mask[1]}}, {8{store_buf_mask[0]}}};
    unique case (pending_funct3)
        load_f3_lb : data_out.rd_v = {{24{load_rdata[7 +8 *pending_addr[1:0]]}}, load_rdata[8 *pending_addr[1:0] +: 8 ]};
        load_f3_lbu: data_out.rd_v = {{24{1'b0}}                          , load_rdata[8 *pending_addr[1:0] +: 8 ]};
        load_f3_lh : data_out.rd_v = {{16{load_rdata[15+16*pending_addr[1]  ]}}, load_rdata[16*pending_addr[1]   +: 16]};
        load_f3_lhu: data_out.rd_v = {{16{1'b0}}                          , load_rdata[16*pending_addr[1]   +: 16]};
        load_f3_lw : data_out.rd_v = load_rdata;
        default    : data_out.rd_v = 'x;
    endcase
    data_out.rob_id = pending_rob_id;
    if(cache_ufp_resp && pending_load) begin
        data_out.valid = 1'b1;
    end
    cache_ufp_addr = cache_addr;
    cache_ufp_rmask = cache_rmask;
    cache_ufp_wmask = cache_wmask;
    cache_ufp_wdata = cache_wdata;
end

always_ff @(posedge clk) begin
    mask_offset_store = '0;
    if(rst) begin
        head <= '0;
        tail <= '0;
        for (integer unsigned i = '0; i < QUEUE_SIZE; i = i + 1'b1) begin
            load_slots[i] <= '0;
            store_slots[i] <= '0;
        end
        pending_load <= '0;
        pending_store_id <= '0;
        pending_addr <= '0;
        resolved_store_pointer <= '0;
        cache_wmask <= '0;
        cache_rmask <= '0;
        cache_wdata <= '0;
        cache_addr <= '0;
        committed_store_pointer <= '0;
        cache_busy <= '0;
    end else begin
        if(cache_ufp_resp) begin
            cache_busy <= 1'b0;
        end

        if(!cache_busy || cache_ufp_resp) begin
            if(load_assigned) begin
                cache_addr <= (load_slots[issue].rs1_data + {{21{load_slots[issue].imm[11]}}, load_slots[issue].imm[10:0]}) & ~32'b11;
                pending_addr <= load_slots[issue].rs1_data + {{21{load_slots[issue].imm[11]}}, load_slots[issue].imm[10:0]};
                wraparound <= load_slots[issue].store_id[INDEX_WIDTH] != head[INDEX_WIDTH];
                pending_store_id <= load_slots[issue].store_id[INDEX_WIDTH-1:0]+1'b1;
                cache_rmask <= '1;
                cache_wmask <= '0;
                cache_wdata <= '0;
                load_slots[issue] <= '0;
                pending_load <= '1;
                pending_rob_id <= load_slots[issue].rob_id;
                pending_funct3 <= load_slots[issue].funct3;
                cache_busy <= 1'b1;
            end
            else if(store_slots[head[INDEX_WIDTH-1:0]].committed) begin
                head <= head + 1'b1;
                store_slots[head[INDEX_WIDTH-1:0]] <= '0;
                cache_wmask <= store_slots[head[INDEX_WIDTH-1:0]].mask;
                cache_rmask <= '0;
                cache_wdata <= store_slots[head[INDEX_WIDTH-1:0]].rs2_data;
                cache_addr <= {store_slots[head[INDEX_WIDTH-1:0]].rs1_data[31:2], 2'b0};
                pending_load <= '0;
                pending_rob_id <= '0;
                pending_store_id <= '0;
                pending_addr <= '0;
                pending_funct3 <= '0;
                cache_busy <= 1'b1;
            end
            else begin
                cache_addr <= '0;
                pending_addr <= '0;
                pending_store_id <= '0;
                cache_rmask <= '0;
                cache_wmask <= '0;
                cache_wdata <= '0;
                pending_load <= '0;
                pending_rob_id <= '0;
                pending_funct3 <= '0;
            end
        end

        for (integer unsigned i = '0; i < QUEUE_SIZE; i++) begin
            if (load_slots[i].valid) begin
                for(integer unsigned j = 0; j < WRITE_PORTS_IN; j++) begin
                    if(load_slots[i].rs1_renamed && broadcast[j].valid && load_slots[i].rs1_data[4:0] == broadcast[j].rob_id) begin
                        load_slots[i].rs1_data <= broadcast[j].rd_v;
                        load_slots[i].rs1_renamed <= 1'b0;
                    end
                end
            end

            if(store_slots[i].valid) begin
                for(integer unsigned j = 0; j < WRITE_PORTS_IN; j++) begin
                    if(store_slots[i].rs1_renamed && broadcast[j].valid && store_slots[i].rs1_data[4:0] == broadcast[j].rob_id) begin
                        store_slots[i].rs1_data <= broadcast[j].rd_v;
                        store_slots[i].rs1_renamed <= 1'b0;
                    end
                    if(store_slots[i].rs2_renamed && broadcast[j].valid && store_slots[i].rs2_data[4:0] == broadcast[j].rob_id) begin
                        store_slots[i].rs2_data <= broadcast[j].rd_v;
                        store_slots[i].rs2_renamed <= 1'b0;
                    end
                end
            end
        end

        if(store_slots[resolved_store_pointer[INDEX_WIDTH-1:0]].valid && ~store_slots[resolved_store_pointer[INDEX_WIDTH-1:0]].rs1_renamed && ~store_slots[resolved_store_pointer[INDEX_WIDTH-1:0]].rs2_renamed && ~store_slots[resolved_store_pointer[INDEX_WIDTH-1:0]].resolved) begin
            store_slots[resolved_store_pointer[INDEX_WIDTH-1:0]].resolved <= 1'b1;
            store_slots[resolved_store_pointer[INDEX_WIDTH-1:0]].rs1_data <= store_slots[resolved_store_pointer[INDEX_WIDTH-1:0]].rs1_data + {{21{store_slots[resolved_store_pointer[INDEX_WIDTH-1:0]].imm[11]}}, store_slots[resolved_store_pointer[INDEX_WIDTH-1:0]].imm[10:0]};
            resolved_store_pointer <= resolved_store_pointer + 1'b1;
            mask_offset_store = store_slots[resolved_store_pointer[INDEX_WIDTH-1:0]].rs1_data[1:0] + store_slots[resolved_store_pointer[INDEX_WIDTH-1:0]].imm[1:0];
            unique case (store_slots[resolved_store_pointer[INDEX_WIDTH-1:0]].funct3)
                store_f3_sb: store_slots[resolved_store_pointer[INDEX_WIDTH-1:0]].mask <= 4'b0001 << mask_offset_store[1:0];
                store_f3_sh: store_slots[resolved_store_pointer[INDEX_WIDTH-1:0]].mask <= 4'b0011 << mask_offset_store[1:0];
                store_f3_sw: store_slots[resolved_store_pointer[INDEX_WIDTH-1:0]].mask <= 4'b1111;
                default    : store_slots[resolved_store_pointer[INDEX_WIDTH-1:0]].mask <= 'x;
            endcase

            unique case (store_slots[resolved_store_pointer[INDEX_WIDTH-1:0]].funct3)
                store_f3_sb: store_slots[resolved_store_pointer[INDEX_WIDTH-1:0]].rs2_data[8 * mask_offset_store[1:0] +: 8 ] <= store_slots[resolved_store_pointer[INDEX_WIDTH-1:0]].rs2_data[7 :0];
                store_f3_sh: store_slots[resolved_store_pointer[INDEX_WIDTH-1:0]].rs2_data[16* mask_offset_store[1]   +: 16] <= store_slots[resolved_store_pointer[INDEX_WIDTH-1:0]].rs2_data[15:0];
                default: store_slots[resolved_store_pointer[INDEX_WIDTH-1:0]].rs2_data <= store_slots[resolved_store_pointer[INDEX_WIDTH-1:0]].rs2_data;
            endcase

            for(integer unsigned i = '0; i < QUEUE_SIZE; i = i + 1'b1) begin
                if(load_slots[i].store_id[INDEX_WIDTH-1:0] == resolved_store_pointer[INDEX_WIDTH-1:0]) begin
                    load_slots[i].store_resolved <= 1'b1;
                end
            end
        end

        if(store_slots[resolved_store_pointer[INDEX_WIDTH-1:0]].resolved && resolved_store_pointer != tail) begin
            resolved_store_pointer <= resolved_store_pointer + 1'b1;
        end

        if(enqueue[0]) begin
            if(data_in_load[0].valid) begin
                load_slots[vacant[0]] <= data_in_load[0];
                load_slots[vacant[0]].store_id <= tail - 1'b1;
                if(store_slots[resolved_store_pointer[INDEX_WIDTH-1:0]].valid && ~store_slots[resolved_store_pointer[INDEX_WIDTH-1:0]].rs1_renamed && ~store_slots[resolved_store_pointer[INDEX_WIDTH-1:0]].rs2_renamed && ~store_slots[resolved_store_pointer[INDEX_WIDTH-1:0]].resolved) begin
                    load_slots[vacant[0]].store_resolved <= tail[INDEX_WIDTH-1:0] == resolved_store_pointer[INDEX_WIDTH-1:0] + 1'b1;
                end
                else begin
                    load_slots[vacant[0]].store_resolved <= tail[INDEX_WIDTH-1:0] == resolved_store_pointer[INDEX_WIDTH-1:0] || store_slots[tail[INDEX_WIDTH-1:0]].resolved;
                end
            end
            if(data_in_store[0].valid) begin
                store_slots[tail[INDEX_WIDTH-1:0]] <= data_in_store[0];
            end
        end

        if(enqueue[1]) begin
            if(data_in_load[1].valid) begin
                load_slots[vacant[1]] <= data_in_load[1];
                if(store_slots[resolved_store_pointer[INDEX_WIDTH-1:0]].valid && ~store_slots[resolved_store_pointer[INDEX_WIDTH-1:0]].rs1_renamed && ~store_slots[resolved_store_pointer[INDEX_WIDTH-1:0]].rs2_renamed && ~store_slots[resolved_store_pointer[INDEX_WIDTH-1:0]].resolved) begin
                    load_slots[vacant[1]].store_resolved <= tail[INDEX_WIDTH-1:0] == resolved_store_pointer[INDEX_WIDTH-1:0] + 1'b1;
                end
                else begin
                    load_slots[vacant[1]].store_resolved <= tail[INDEX_WIDTH-1:0] == resolved_store_pointer[INDEX_WIDTH-1:0] || store_slots[tail[INDEX_WIDTH-1:0]].resolved;
                end

                if(data_in_store[0].valid) begin
                    load_slots[vacant[1]].store_id <= tail;
                    load_slots[vacant[1]].store_resolved <= '0;
                end
                else begin
                    load_slots[vacant[1]].store_id <= tail - 1'b1;
                end
            end
            if(data_in_store[1].valid) begin
                store_slots[tail_next[INDEX_WIDTH-1:0] -1'b1] <= data_in_store[1];
            end
        end

        tail <= tail_next;

        if(flush)begin
            tail <= committed_store_pointer;
            if(~store_slots[resolved_store_pointer[INDEX_WIDTH-1:0]].committed || resolved_store_pointer == tail) begin
                resolved_store_pointer <= committed_store_pointer;
            end
            pending_load <= '0;
            pending_store_id <= '0;
            pending_addr <= '0;
            for (integer unsigned i = '0; i < QUEUE_SIZE; i = i + 1'b1) begin
                load_slots[i] <= '0;
                if(~store_slots[i].committed && ~(commit[0] && store_slots[i].valid && commit_rob_id == store_slots[i].rob_id)) begin
                    store_slots[i] <= '0;
                end
            end
        end

        if(commit[0] && store_slots[committed_store_pointer[INDEX_WIDTH-1:0]].valid && ~store_slots[committed_store_pointer[INDEX_WIDTH-1:0]].committed && commit_rob_id == store_slots[committed_store_pointer[INDEX_WIDTH-1:0]].rob_id) begin
            store_slots[committed_store_pointer[INDEX_WIDTH-1:0]].committed <= 1'b1;
            committed_store_pointer <= committed_store_pointer + 1'b1;
            if (flush)begin
                tail <= committed_store_pointer + 1'b1;
                if(~store_slots[resolved_store_pointer[INDEX_WIDTH-1:0]].committed || resolved_store_pointer == tail) begin
                    resolved_store_pointer <= committed_store_pointer + 1'b1;
                end
            end
            if(commit[1] && store_slots[committed_store_pointer[INDEX_WIDTH-1:0] + 1'b1].valid && commit_rob_id + 1'b1 == store_slots[committed_store_pointer[INDEX_WIDTH-1:0] + 1'b1].rob_id) begin
                store_slots[committed_store_pointer[INDEX_WIDTH-1:0] + 1'b1].committed <= 1'b1;
                committed_store_pointer <= committed_store_pointer + 2'h2;
            end
        end
        else if(commit[1] && store_slots[committed_store_pointer[INDEX_WIDTH-1:0]].valid && ~store_slots[committed_store_pointer[INDEX_WIDTH-1:0]].committed && commit_rob_id + 1'b1 == store_slots[committed_store_pointer[INDEX_WIDTH-1:0]].rob_id) begin
            store_slots[committed_store_pointer[INDEX_WIDTH-1:0]].committed <= 1'b1;
            committed_store_pointer <= committed_store_pointer + 1'b1;
        end
    end
end 


endmodule