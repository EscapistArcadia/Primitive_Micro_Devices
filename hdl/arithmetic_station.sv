module arithmetic_station
import rv32cpu_type::*;
#(
    parameter INDEX_WIDTH,                                                          // index width of the queue
    // parameter FUNC_UNITS,                                                           // number of functional units
    parameter WRITE_PORTS_IN,                                                        // number of CDB entries broadcasted
    // parameter WRITE_PORTS_OUT                                                       // number of CDB entries to be written to ROB each cycle
    parameter FUNC_UNITS,

    localparam QUEUE_SIZE = 1 << INDEX_WIDTH         
)
(
    input logic clk,
    input logic rst,

    // // input data from instruction dispatcher
    input logic enqueue[2],
    input rs_entry_t data_in[2],

    // input data from reorder buffer broadcast
    input cdb_entry_t broadcast[WRITE_PORTS_IN],

    // // output data to reorder buffer
    output cdb_entry_t data_out[FUNC_UNITS],

    output logic full[2]
);                                   // size of the queue
    localparam FUNC_INDEX                      = $clog2(FUNC_UNITS);

    rs_entry_t slots[QUEUE_SIZE], alu_slots[FUNC_UNITS];
    logic [INDEX_WIDTH-1:0] vacant[2], tree2[4], tree3[2], trees2[4], trees3[2];
    logic [31:0] tree1[8], trees1[8];
    logic                   assigned[2], treev1[8], treev2[4], treev3[2], treesv1[8], treesv2[4], treesv3[2];
    logic [31:0]            alu_out[FUNC_UNITS], temp_i;
    logic                   invalidate[QUEUE_SIZE];
    

    generate for (genvar i = 0; i < FUNC_UNITS; i++) begin : ALU_ARRAY
        alu32 alu_array(
            .a(alu_slots[i].rs1_data),
            .b(alu_slots[i].rs2_data),
            .op_funct3(alu_slots[i].funct3),
            .op_funct7(alu_slots[i].funct7),
            
            .out(alu_out[i])
        );
    end endgenerate

    always_comb begin
        vacant = '{default:0};
        assigned = '{default:1};
        invalidate = '{default:0};
        data_out = '{default:0};
        alu_slots = '{default:0};
        tree1 = '{default:0};
        tree2 = '{default:0};
        tree3 = '{default:0};
        trees1 = '{default:0};
        trees2 = '{default:0};
        trees3 = '{default:0}; 
        treev1 = '{default:0};
        treev2 = '{default:0};
        treev3 = '{default:0};
        treesv1 = '{default:0};
        treesv2 = '{default:0};
        treesv3 = '{default:0};
        for (integer unsigned i = 0; i < 16; i+=2) begin
            if(slots[i].valid && ~slots[i].rs1_renamed && ~slots[i].rs2_renamed) begin
                tree1[i/2] = i;
                treev1[i/2] = 1'b1;
            end
            else if(slots[i+1'b1].valid && ~slots[i+1'b1].rs1_renamed && ~slots[i+1'b1].rs2_renamed) begin
                tree1[i/2] = i+1'b1;
                treev1[i/2] = 1'b1;
            end
            else begin
                tree1[i/2] = '0;
                treev1[i/2] = 1'b0;
            end

            if(slots[i+1'b1].valid && ~slots[i+1'b1].rs1_renamed && ~slots[i+1'b1].rs2_renamed) begin
                trees1[i/2] = i+1'b1;
                treesv1[i/2] = 1'b1;
            end
            else if(slots[i].valid && ~slots[i].rs1_renamed && ~slots[i].rs2_renamed) begin
                trees1[i/2] = i;
                treesv1[i/2] = 1'b1;
            end
            else begin
                trees1[i/2] = '0;
                treesv1[i/2] = 1'b0;
            end
        end

        for(integer unsigned i = 0; i < 8; i+=2) begin
            if(treev1[i]) begin
                tree2[i/2] = tree1[i][INDEX_WIDTH-1:0];
                treev2[i/2] = 1'b1;
            end
            else if(treev1[i+1'b1]) begin
                tree2[i/2] = tree1[i+1'b1][INDEX_WIDTH-1:0];
                treev2[i/2] = 1'b1;
            end
            else begin
                tree2[i/2] = '0;
                treev2[i/2] = 1'b0;
            end

            if(treesv1[i+1'b1]) begin
                trees2[i/2] = trees1[i+1'b1][INDEX_WIDTH-1:0];
                treesv2[i/2] = 1'b1;
            end
            else if(treesv1[i]) begin
                trees2[i/2] = trees1[i][INDEX_WIDTH-1:0];
                treesv2[i/2] = 1'b1;
            end
            else begin
                trees2[i/2] = '0;
                treesv2[i/2] = 1'b0;
            end
        end

        for(integer unsigned i = 0; i < 4; i+=2) begin
            if(treev2[i]) begin
                tree3[i/2] = tree2[i];
                treev3[i/2] = 1'b1;
            end
            else if(treev2[i+1'b1]) begin
                tree3[i/2] = tree2[i+1'b1];
                treev3[i/2] = 1'b1;
            end
            else begin
                tree3[i/2] = '0;
                treev3[i/2] = 1'b0;
            end

            if(treesv2[i+1'b1]) begin
                trees3[i/2] = trees2[i+1'b1];
                treesv3[i/2] = 1'b1;
            end
            else if(treesv2[i]) begin
                trees3[i/2] = trees2[i];
                treesv3[i/2] = 1'b1;
            end
            else begin
                trees3[i/2] = '0;
                treesv3[i/2] = 1'b0;
            end
        end

        if(treev3[0]) begin
            alu_slots[0] = slots[tree3[0]];
            data_out[0].valid = 1'b1;
            data_out[0].rob_id = slots[tree3[0]].rob_id;
            data_out[0].rd_v = alu_out[0];
            invalidate[tree3[0]] = 1'b1;
        end
        else if(treev3[1]) begin
            alu_slots[0] = slots[tree3[1]];
            data_out[0].valid = 1'b1;
            data_out[0].rob_id = slots[tree3[1]].rob_id;
            data_out[0].rd_v = alu_out[0];
            invalidate[tree3[1]] = 1'b1;
        end

        if(treesv3[1]) begin
            alu_slots[1] = slots[trees3[1]];
            data_out[1].valid = 1'b1;
            data_out[1].rob_id = slots[trees3[1]].rob_id;
            data_out[1].rd_v = alu_out[1];
            invalidate[trees3[1]] = 1'b1;
        end
        else if(treesv3[0]) begin
            alu_slots[1] = slots[trees3[0]];
            data_out[1].valid = 1'b1;
            data_out[1].rob_id = slots[trees3[0]].rob_id;
            data_out[1].rd_v = alu_out[1];
            invalidate[trees3[0]] = 1'b1;
        end
        
        // for (integer unsigned i = 0; i < QUEUE_SIZE; i++) begin
        //     if (slots[i].valid&&~slots[i].rs1_renamed&&~slots[i].rs2_renamed) begin
        //         alu_slots[c] = slots[i];
        //         data_out[c].valid = 1'b1;
        //         data_out[c].rob_id = slots[i].rob_id;
        //         data_out[c].rd_v = alu_out[c];
        //         invalidate[i] = 1'b1;
        //         c= c + 1'b1;
        //         if(c==FUNC_UNITS[FUNC_INDEX:0])
        //             break;
        //     end
        // end

        for (integer unsigned i = 0; i < QUEUE_SIZE; i++) begin
            if (~slots[i].valid) begin
                assigned[1] = assigned[0];
                assigned[0] = '0;
                temp_i = i;
                vacant[1] = vacant[0];
                vacant[0] = temp_i[INDEX_WIDTH-1:0];
            end
        end
        full[0] = assigned[0];
        full[1] = assigned[1];
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            for (integer i = 0; i < QUEUE_SIZE; i++) begin
                slots[i] <= '0;
            end
        end else begin
            for (integer i = 0; i < QUEUE_SIZE; i++) begin
                if (slots[i].valid) begin
                    for(integer j = 0; j < WRITE_PORTS_IN; j++) begin
                        if(slots[i].rs1_renamed && broadcast[j].valid && slots[i].rs1_data[4:0] == broadcast[j].rob_id) begin
                            slots[i].rs1_data <= broadcast[j].rd_v;
                            slots[i].rs1_renamed <= 1'b0;
                        end
                        if(slots[i].rs2_renamed && broadcast[j].valid && slots[i].rs2_data[4:0] == broadcast[j].rob_id) begin
                            slots[i].rs2_data <= broadcast[j].rd_v;
                            slots[i].rs2_renamed <= 1'b0;
                        end
                    end
                    for(integer j = 0; j < FUNC_UNITS; j++) begin
                        if(slots[i].rs1_renamed && data_out[j].valid && slots[i].rs1_data[4:0] == data_out[j].rob_id) begin
                            slots[i].rs1_data <= data_out[j].rd_v;
                            slots[i].rs1_renamed <= 1'b0;
                        end
                        if(slots[i].rs2_renamed && data_out[j].valid && slots[i].rs2_data[4:0] == data_out[j].rob_id) begin
                            slots[i].rs2_data <= data_out[j].rd_v;
                            slots[i].rs2_renamed <= 1'b0;
                        end
                    end
                end
                if(invalidate[i]) begin
                    slots[i] <= '0;
                end
            end
            if(enqueue[0])
                slots[vacant[0]] <= data_in[0];
            if(enqueue[1])
                slots[vacant[1]] <= data_in[1];
        end
    end
endmodule