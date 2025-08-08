module multiply_divide_station
import rv32cpu_type::*;
#(
    parameter INDEX_WIDTH,                                                          // index width of the queue
    parameter WRITE_PORTS_IN,                                                       // number of CDB entries broadcasted
    parameter STAGE_COUNT,
    localparam QUEUE_SIZE = 1 << INDEX_WIDTH,                                        // size of the queue
    localparam STAGE_WIDTH                      = $clog2(STAGE_COUNT)
)
(
    input   logic               clk,
    input   logic               rst,

    // input data from instruction dispatcher
    input   logic               enqueue[2],
    input   rs_entry_t          data_in[2],

    // input data from reorder buffer broadcast
    input   cdb_entry_t         broadcast[WRITE_PORTS_IN],

    // output data to reorder buffer
    output  cdb_entry_t         data_out,

    output  logic               full[2]
);

            // reservation station storage
            rs_entry_t          slots[QUEUE_SIZE], mult_out, data_out_pp[STAGE_COUNT - 1], to_be_pp;
            logic [INDEX_WIDTH-1:0] vacant[2];
            logic               assigned[2];
            logic [STAGE_WIDTH-1:0] head;

            // multiplication data
            logic               mult_en, mult_tc, mult_complete, mult_start;
            logic   [32:0]      mult_a, mult_b;
            logic   [65:0]      mult_product;
            logic   [31:0]      warning_eliminator;

            // division data
            logic               div_en, div_by_zero;
            logic   [32:0]      div_dividend, div_divisor, div_quotient, div_remainder;
            // logic   [31:0]      warning_eliminator;
    
    DW_mult_seq #(
        .a_width(33),
        .b_width(33),
        .tc_mode(1),
        .num_cyc(3),
        .rst_mode(1),
        .input_mode(1),
        .output_mode(0),
        .early_start(0)
    ) multiplier (
        .clk(clk),
        .rst_n(~rst),
        .hold (1'b0),
        .start(mult_start & ~mult_out.rs1_renamed),
        .a(mult_a),
        .b(mult_b),
        .complete(mult_complete),
        .product(mult_product)
    );

    DW_div_pipe #(
        .a_width(33),
        .b_width(33),
        .tc_mode(1),
        .rem_mode(1),
        .num_stages(STAGE_COUNT),
        .stall_mode(0),
        .rst_mode(0),
        .op_iso_mode(0)
    ) divider (
        .clk(clk),
        .rst_n('x),
        .en('x),
        .a(div_dividend),
        .b(div_divisor),
        .quotient(div_quotient),
        .remainder(div_remainder),
        .divide_by_0(div_by_zero)
    );

    always_comb begin
        data_out.valid = mult_complete & mult_out.valid | data_out_pp[head].valid;

        if(data_out_pp[head].valid) begin
            data_out.rob_id                         = data_out_pp[head].rob_id;
            unique case (data_out_pp[head].funct3)
                mul_f3_div:     data_out.rd_v       = div_by_zero ? 32'hFFFFFFFF  /* edge case */ : div_quotient[31:0];
                mul_f3_divu:    data_out.rd_v       = div_by_zero ? 32'hFFFFFFFF                  : div_quotient[31:0];
                mul_f3_rem:     data_out.rd_v       = div_by_zero ? data_out_pp[head].rs1_data       : div_remainder[31:0];
                mul_f3_remu:    data_out.rd_v       = div_by_zero ? data_out_pp[head].rs1_data       : div_remainder[31:0];
                default:        data_out.rd_v       = 'x;
            endcase
        end
        else begin
            data_out.rob_id = mult_out.rob_id;
            unique case (mult_out.funct3)
                mul_f3_mul:     data_out.rd_v       = mult_product[31:0];
                mul_f3_mulh:    data_out.rd_v       = mult_product[63:32];
                mul_f3_mulhsu:  data_out.rd_v       = mult_product[63:32];
                mul_f3_mulhu:   data_out.rd_v       = mult_product[63:32];
                default:        data_out.rd_v       = 'x;
            endcase
        end
    end

    always_comb begin
        vacant = '{default:0};
        assigned = '{default:1};
        warning_eliminator = 'x;

        mult_tc = 'x;
        mult_a = '0;
        mult_b = '0;

        div_dividend = '0;
        div_divisor = '0;
        mult_start = 1'b0;        
        to_be_pp = 'x;
        to_be_pp.valid = 1'b0;

        for (integer unsigned i = QUEUE_SIZE - 1'b1; i != '1; i--) begin
            if (slots[i].valid && ~slots[i].rs1_renamed && ~slots[i].rs2_renamed) begin

                unique case (slots[i].funct3)
                    mul_f3_mul: begin
                        mult_a = {slots[i].rs1_data[31], slots[i].rs1_data[31:0]};
                        mult_b = {slots[i].rs2_data[31], slots[i].rs2_data[31:0]};
                        mult_tc = 1'b0;
                    end
                    mul_f3_mulh: begin
                        mult_a = {slots[i].rs1_data[31], slots[i].rs1_data[31:0]};
                        mult_b = {slots[i].rs2_data[31], slots[i].rs2_data[31:0]};
                        mult_tc = 1'b1;
                    end
                    mul_f3_mulhsu: begin
                        mult_a = {slots[i].rs1_data[31], slots[i].rs1_data[31:0]};
                        mult_b = {                 1'b0, slots[i].rs2_data[31:0]};
                        mult_tc = 1'b1;
                    end
                    mul_f3_mulhu: begin
                        mult_a = {                 1'b0, slots[i].rs1_data[31:0]};
                        mult_b = {                 1'b0, slots[i].rs2_data[31:0]};
                        mult_tc = 1'b1;
                    end
                    default:;
                endcase

                if(~slots[i].funct3[2]) begin
                    mult_start = 1'b1;
                    break;
                end
            end 
        end

        for (integer unsigned i = QUEUE_SIZE - 1'b1; i != '1; i--) begin
            if (slots[i].valid && ~slots[i].rs1_renamed && ~slots[i].rs2_renamed) begin

                unique case (slots[i].funct3)
                    mul_f3_div: begin
                        to_be_pp = slots[i];
                        div_dividend = {slots[i].rs1_data[31], slots[i].rs1_data[31:0]};
                        div_divisor  = {slots[i].rs2_data[31], slots[i].rs2_data[31:0]};
                    end
                    mul_f3_divu: begin
                        to_be_pp = slots[i];
                        div_dividend = {                 1'b0, slots[i].rs1_data[31:0]};
                        div_divisor  = {                 1'b0, slots[i].rs2_data[31:0]};
                    end
                    mul_f3_rem: begin
                        to_be_pp = slots[i];
                        div_dividend = {slots[i].rs1_data[31], slots[i].rs1_data[31:0]};
                        div_divisor  = {slots[i].rs2_data[31], slots[i].rs2_data[31:0]};
                    end
                    mul_f3_remu: begin
                        to_be_pp = slots[i];
                        div_dividend = {                 1'b0, slots[i].rs1_data[31:0]};
                        div_divisor  = {                 1'b0, slots[i].rs2_data[31:0]};
                    end
                    default:;
                endcase

                if(slots[i].funct3[2]) begin
                    break;
                end
            end
        end

        for (integer unsigned i = 0; i < QUEUE_SIZE; i++) begin
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
            for (integer i = 0; i < STAGE_COUNT - 1; i++) begin
                data_out_pp[i].valid <= '0;
            end
            mult_out <= '0;
            head <= '0;
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
                end
            end
            
            for (integer unsigned i = QUEUE_SIZE - 1'b1; i != '1; i--) begin
                if(slots[i].valid && ~slots[i].rs1_renamed && ~slots[i].rs2_renamed && ~slots[i].funct3[2] && ~mult_out.rs1_renamed) begin
                    slots[i] <= '0;
                    mult_out <= slots[i];
                    mult_out.rs1_renamed <= 1'b1;
                    break;
                end
            end
            for (integer unsigned i = QUEUE_SIZE - 1'b1; i != '1; i--) begin
                if(slots[i].valid && ~slots[i].rs1_renamed && ~slots[i].rs2_renamed && slots[i].funct3[2]) begin
                    slots[i] <= '0;
                    break;
                end
            end
            
            if(mult_complete && ~data_out_pp[head].valid)
                mult_out <= '0;
            data_out_pp[head] <= to_be_pp;
            if (head == STAGE_COUNT[STAGE_WIDTH-1:0] - 2'h2) begin
                head <= '0;
            end else begin
                head <= head + 1'b1;
            end

            if(enqueue[0])
                slots[vacant[0]] <= data_in[0];
            if(enqueue[1])
                slots[vacant[1]] <= data_in[1];
        end
    end
endmodule