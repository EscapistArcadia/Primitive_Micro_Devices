module regfile
import rv32cpu_type::*;
#(
    parameter INDEX_WIDTH,
    parameter COMMIT_PORTS,
    parameter WRITE_PORTS
) 
(
    input   logic           clk,
    input   logic           rst,
    input   logic           flush,
    input   logic           reg_r[2],
    input   logic   [4:0]   rd_r[2],
    input   logic   [INDEX_WIDTH-1:0]  rob_w, rob_r[2],
    input   logic   [4:0]   rs1_s[2], rs2_s[2],
    input   logic   [31:0]  rob1_v[2], rob2_v[2], fwd_data,
    input   logic           rob1_r[2], rob2_r[2],
    input   cdb_entry_t     cdb_in[WRITE_PORTS],
    input   rob_entry_t     rob_in[COMMIT_PORTS],
    input   logic           fwd_valid,

    output  logic   [INDEX_WIDTH-1:0]   rob1_s[2], rob2_s[2],
    output  logic   [31:0]  rs1_v[2], rs2_v[2],
    output  logic           rs1_renamed[2], rs2_renamed[2]
);

            logic   [31:0]          data [32];
            logic                   renamed[32];
            logic   [INDEX_WIDTH-1:0]  rob_id[32];
            logic                   cdb1_valid[2], cdb2_valid[2];
            logic                   rob1_valid[2], rob2_valid[2];
            logic   [31:0]          cdb1_d[2], cdb2_d[2];
            logic   [31:0]          rob1_d[2], rob2_d[2];
            logic                   regf_we[COMMIT_PORTS];
            logic   [4:0]           rd_s[COMMIT_PORTS];
            logic   [31:0]          rd_v[COMMIT_PORTS];

    always_ff @(posedge clk) begin
        if (rst) begin
            for (integer i = 0; i < 32; i++) begin
                data[i] <= '0;
                renamed[i] <= '0;
                rob_id[i] <= '0;
            end
        end else begin
            if (flush) begin
                for (integer i = 0; i < 32; i++) begin
                    renamed[i] <= '0;
                    rob_id[i] <= '0;
                end
                for (integer i = 0; i < COMMIT_PORTS; i++) begin
                    if (regf_we[i] && (rd_s[i] != '0)) begin
                        data[rd_s[i]] <= rd_v[i];
                    end
                end
            end else begin
                if (regf_we[0] && (rd_s[0] != '0)) begin
                    data[rd_s[0]] <= rd_v[0];
                    if(renamed[rd_s[0]]&&rob_id[rd_s[0]]==rob_w) begin
                        renamed[rd_s[0]] <= '0;
                    end
                end
                if (regf_we[1] && (rd_s[1] != '0)) begin
                    data[rd_s[1]] <= rd_v[1];
                    if(renamed[rd_s[1]]&&rob_id[rd_s[1]]==rob_w+1'b1) begin
                        renamed[rd_s[1]] <= '0;
                    end
                end
                if(reg_r[0] && (rd_r[0] != '0)) begin
                    renamed[rd_r[0]] <= '1;
                    rob_id[rd_r[0]] <= rob_r[0];
                end
                if(reg_r[1] && (rd_r[1] != '0)) begin
                    renamed[rd_r[1]] <= '1;
                    rob_id[rd_r[1]] <= rob_r[1];
                end
            end
        end
    end

    always_comb begin
        cdb1_valid = '{default:0};
        cdb2_valid = '{default:0};
        rob1_valid = '{default:0};
        rob2_valid = '{default:0};
        cdb1_d = '{default:0};
        cdb2_d = '{default:0};
        rob1_d = '{default:0};
        rob2_d = '{default:0};
        rob1_s = '{default:0};
        rob2_s = '{default:0};
        rs1_v = '{default:0};
        rs2_v = '{default:0};

        for(integer i = 0; i < COMMIT_PORTS; i++) begin
            regf_we[i] = rob_in[i].regf_we;
            rd_s[i] = rob_in[i].rd_s;
            rd_v[i] = rob_in[i].rd_v;
        end

        for(integer i = 0; i < 2; i++) begin
            if (rs1_s[i] == '0) begin
                rs1_v[i] = 32'b0;
                rs1_renamed[i] = 1'b0;
            end 
            else if(renamed[rs1_s[i]]) begin
                rob1_s[i] = rob_id[rs1_s[i]];
                for (integer j = 0; j < WRITE_PORTS; j++) begin
                    if(cdb_in[j].valid&&cdb_in[j].rob_id == rob_id[rs1_s[i]]) begin
                        cdb1_d[i] = cdb_in[j].rd_v;
                        cdb1_valid[i] = 1'b1;
                    end
                end
                if(rob1_r[i]) begin
                    rob1_d[i] = rob1_v[i];
                    rob1_valid[i] = 1'b1;
                end else begin
                    rob1_d[i] = data[rs1_s[i]];
                    rob1_valid[i] = 1'b0;
                end

                rs1_renamed[i] = ~(cdb1_valid[i]||rob1_valid[i]);

                if(cdb1_valid[i]) begin
                    rs1_v[i] = cdb1_d[i];
                end else if(rob1_valid[i]) begin
                    rs1_v[i] = rob1_d[i];
                end else begin
                    rs1_v[i] = {{(32 - INDEX_WIDTH){1'b0}}, rob_id[rs1_s[i]]};
                end
            end
            else begin
                rs1_renamed[i] = 1'b0;
                rs1_v[i] = data[rs1_s[i]];
            end

            if (rs2_s[i] == '0) begin
                rs2_v[i] = 32'b0;
                rs2_renamed[i] = 1'b0;
            end 
            else if(renamed[rs2_s[i]]) begin
                rob2_s[i] = rob_id[rs2_s[i]];
                for (integer j = 0; j < WRITE_PORTS; j++) begin
                    if(cdb_in[j].valid&&cdb_in[j].rob_id == rob_id[rs2_s[i]]) begin
                        cdb2_d[i] = cdb_in[j].rd_v;
                        cdb2_valid[i] = 1'b1;
                    end
                end
                if(rob2_r[i]) begin
                    rob2_d[i] = rob2_v[i];
                    rob2_valid[i] = 1'b1;
                end else begin
                    rob2_d[i] = data[rs2_s[i]];
                    rob2_valid[i] = 1'b0;
                end

                rs2_renamed[i] = ~(cdb2_valid[i]||rob2_valid[i]);

                if(cdb2_valid[i]) begin
                    rs2_v[i] = cdb2_d[i];
                end else if(rob2_valid[i]) begin
                    rs2_v[i] = rob2_d[i];
                end else begin
                    rs2_v[i] = {{(32 - INDEX_WIDTH){1'b0}}, rob_id[rs2_s[i]]};
                end
            end
            else begin
                rs2_renamed[i] = 1'b0;
                rs2_v[i] = data[rs2_s[i]];
            end
        end

        if(reg_r[0] && (rd_r[0] != '0)) begin
            if(rs1_s[1] == rd_r[0]) begin
                if(fwd_valid) begin
                    rs1_renamed[1] = 1'b0;
                    rs1_v[1] = fwd_data;
                end else begin
                    rs1_renamed[1] = 1'b1;
                    rs1_v[1] = {{(32 - INDEX_WIDTH){1'b0}}, rob_r[0]};
                end
            end
            if(rs2_s[1] == rd_r[0]) begin
                if(fwd_valid) begin
                    rs2_renamed[1] = 1'b0;
                    rs2_v[1] = fwd_data;
                end else begin
                    rs2_renamed[1] = 1'b1;
                    rs2_v[1] = {{(32 - INDEX_WIDTH){1'b0}}, rob_r[0]};
                end
            end
        end

    end

endmodule : regfile