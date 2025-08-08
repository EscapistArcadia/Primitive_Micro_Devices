module branch_station
import rv32cpu_type::*;
# (
    parameter INDEX_WIDTH,
    parameter WRITE_PORTS_IN,
    localparam QUEUE_SIZE = 1 << INDEX_WIDTH
) (
    input logic clk,
    input logic rst,

    input logic enqueue[2],
    input rs_entry_t data_in[2],
    
    input cdb_entry_t broadcast[WRITE_PORTS_IN],

    // output cdb_entry_t data_out,
    output br_entry_t br_out,

    output logic full[2]
);

    rs_entry_t slots[QUEUE_SIZE];
    logic [INDEX_WIDTH-1:0] vacant[2];
    logic                   assigned[2];
    // logic                   br_en;

    logic [31:0] warning_eliminator;
    br_entry_t br;

    always_comb begin
        vacant = '{default:0};
        assigned = '{default:1};
        warning_eliminator = '0;
        // br_en = 'x;
        br = '0;

        for (integer unsigned i = QUEUE_SIZE - 1'b1; i!='1; i--) begin
            if (slots[i].valid && ~slots[i].rs1_renamed && ~slots[i].rs2_renamed) begin
                br.valid = 1'b1;
                br.rob_id = slots[i].rob_id;
                if (slots[i].funct7 == 1'b1) begin
                    br.br_en = 1'b1;
                    br.jalr = 1'b1;
                    br.pc_jalr = (slots[i].rs1_data + slots[i].rs2_data) & 32'hFFFFFFFE;
                end else begin
                    br.jalr = 1'b0;
                    unique case (slots[i].funct3)
                        branch_f3_beq : br.br_en = (slots[i].rs1_data == slots[i].rs2_data);
                        branch_f3_bne : br.br_en = (slots[i].rs1_data != slots[i].rs2_data);
                        branch_f3_blt : br.br_en = (signed'(slots[i].rs1_data) <  signed'(slots[i].rs2_data));
                        branch_f3_bge : br.br_en = (signed'(slots[i].rs1_data) >= signed'(slots[i].rs2_data));
                        branch_f3_bltu: br.br_en = (unsigned'(slots[i].rs1_data) < unsigned'(slots[i].rs2_data));
                        branch_f3_bgeu: br.br_en = (unsigned'(slots[i].rs1_data) >= unsigned'(slots[i].rs2_data));
                        // 3'b011: begin
                        //     br_en = 1'b1;
                        //     br_out.jalr = 1'b1;
                        //     br_out.new_pc = slots[i].rs1_data + slots[i].rs2_data;
                        // end
                        default: br.br_en = 'x;
                    endcase
                end
                break;
            end
        end

        for(integer unsigned i = 0; i < QUEUE_SIZE; i++) begin
            if (~slots[i].valid) begin
                assigned[1] = assigned[0];
                assigned[0] = '0;
                warning_eliminator = i;
                vacant[1] = vacant[0];
                vacant[0] = warning_eliminator[INDEX_WIDTH-1:0];
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
            br_out <= '0;
        end else begin
            br_out <= br;
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
                end
            end
            
            for (integer unsigned i = QUEUE_SIZE - 1'b1; i!='1; i--) begin
                if(slots[i].valid && ~slots[i].rs1_renamed && ~slots[i].rs2_renamed) begin
                    slots[i] <= '0;
                    break;
                end
            end
            if(enqueue[0])
                slots[vacant[0]] <= data_in[0];
            if(enqueue[1])
                slots[vacant[1]] <= data_in[1];
        end
    end

endmodule