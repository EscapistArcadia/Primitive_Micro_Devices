module icache (
    input   logic               clk,
    input   logic               rst,

    input   logic   [31:0]      ufp_addr,
    input   logic   [3:0]       ufp_rmask,
    input   logic   [3:0]       ufp_wmask,
    output  logic   [255:0]      ufp_rdata,
    input   logic   [31:0]      ufp_wdata,
    output  logic               ufp_resp,

    output  logic   [31:0]      dfp_addr,
    output  logic               dfp_read,
    output  logic               dfp_write,
    input   logic   [255:0]     dfp_rdata,
    output  logic   [255:0]     dfp_wdata,
    input   logic               dfp_resp
);

    logic [2:0]         plru_i, plru_o;
    logic               plru_we;
    logic [1:0]         way_s, way_n;
    logic [3:0][22:0]   tag_o;
    logic [22:0]        tag_i;
    logic [3:0][255:0]  data_o;
    logic [255:0]       data_i;
    logic [31:0]        mask_i;
    logic [3:0]         valid_o;
    logic               valid_i;
    logic [3:0]         data_we, tag_we, valid_we;
    
    logic   [31:0]  ufp_addr_f;
    logic   [3:0]   ufp_rmask_f;
    logic   [3:0]   ufp_wmask_f;
    logic   [31:0]  ufp_wdata_f;

    logic   [255:0]     linebuf_data, data_buf;
    logic   [26:0]      linebuf_tag;
    logic               linebuf_v;
    
    logic               data_csb, tag_csb;
    logic               write_csb_f;

    generate for (genvar i = 0; i < 4; i++) begin : arrays
        mp_cache_data_array data_array (
            .clk0       (clk & (data_csb | write_csb_f)),
            .csb0       (~data_csb & ~write_csb_f),
            .web0       (!data_we[i]),
            .wmask0     (mask_i),
            .addr0      (ufp_addr[8:5]),
            .din0       (data_i),
            .dout0      (data_o[i])
        );
        mp_cache_tag_array tag_array (
            .clk0       (clk & (tag_csb | write_csb_f)),
            .csb0       (~tag_csb & ~write_csb_f),
            .web0       (!tag_we[i]),
            .addr0      (ufp_addr[8:5]),
            .din0       (ufp_addr[31:9]),
            .dout0      (tag_o[i])
        );
        sp_ff_array valid_array (
            .clk0       (clk),
            .rst0       (rst),
            .csb0       (1'b0),
            .web0       (!valid_we[i]),
            .addr0      (ufp_addr[8:5]),
            .din0       (valid_i),
            .dout0      (valid_o[i])
        );
    end endgenerate

    sp_ff_array #(
        .WIDTH      (3)
    ) lru_array (
        .clk0       (clk),
        .rst0       (rst),
        .csb0       (1'b0),
        .web0       (!plru_we),
        .addr0      (ufp_addr[8:5]),
        .din0       (plru_i),
        .dout0      (plru_o)
    );
    
    enum integer unsigned {
        s_idle,
        s_hit,
        s_allocate,
        s_writeback
    } state, state_next;
    
    always_comb begin
        plru_i='0;
        plru_we='0;
        way_n='0;
        tag_i='0;
        data_i='0;
        mask_i='0;
        valid_i='0;
        ufp_rdata='0;
        ufp_resp='0;
        dfp_addr='0;
        dfp_read='0;
        dfp_write='0;
        dfp_wdata='0;
        data_we='0;
        tag_we='0;
        valid_we='0;
        data_buf='0;
        state_next=s_idle;
        data_csb= '0;
        tag_csb= '0;
        
        unique case (state) 
        s_idle: begin
            ufp_rdata=linebuf_data;
            if(linebuf_tag==ufp_addr[31:5] && linebuf_v)begin
                ufp_resp = '1;
            end
            else begin
                state_next = s_hit;
                data_csb = '1;
                tag_csb = '1;
            end
        end
        s_hit: begin
            if(tag_o[0]==ufp_addr_f[31:9] & valid_o[0]) begin
                ufp_rdata=data_o[0];
                data_buf=data_o[0];
                ufp_resp = '1;
                plru_i = {2'b00, plru_o[0]};
                plru_we = '1;
            end
            else if(tag_o[1]==ufp_addr_f[31:9] & valid_o[1]) begin
                ufp_rdata=data_o[1];
                data_buf=data_o[1];
                ufp_resp = '1;
                plru_i = {2'b01, plru_o[0]};
                plru_we = '1;
            end
            else if(tag_o[2]==ufp_addr_f[31:9] & valid_o[2]) begin
                ufp_rdata=data_o[2];
                data_buf=data_o[2];
                ufp_resp = '1;
                plru_i = {1'b1, plru_o[1], 1'b0};
                plru_we = '1;
            end
            else if(tag_o[3]==ufp_addr_f[31:9] & valid_o[3]) begin
                ufp_rdata=data_o[3];
                data_buf=data_o[3];
                ufp_resp = '1;
                plru_i = {1'b1, plru_o[1], 1'b1};
                plru_we = '1;
            end
            else begin
                state_next = s_allocate;
                unique casez (plru_o)
                    3'b11?: begin
                        plru_i = {2'b00, plru_o[0]};
                        way_n = 2'd0;
                        plru_we = '1;
                    end
                    3'b10?: begin
                        plru_i = {2'b01, plru_o[0]};
                        way_n = 2'd1;
                        plru_we = '1;
                    end
                    3'b0?1: begin
                        plru_i = {1'b1, plru_o[1], 1'b0};
                        way_n = 2'd2;
                        plru_we = '1;
                    end
                    3'b0?0: begin
                        plru_i = {1'b1, plru_o[1], 1'b1};
                        way_n = 2'd3;
                        plru_we = '1;
                    end
                    default: begin
                    end
                endcase
            end
        end
        s_allocate: begin
            dfp_addr = {ufp_addr_f[31:5], 5'b0};
            dfp_read = '1;
            if(dfp_resp) begin
                data_i = dfp_rdata;
                tag_i = ufp_addr_f[31:9];
                valid_i = '1;
                mask_i = '1;
                data_we[way_s]=1'b1;
                tag_we[way_s]=1'b1;
                valid_we[way_s]=1'b1;
                state_next = s_idle;
                data_csb = '1;
                tag_csb = '1;
            end
            else begin
                state_next = s_allocate;
            end
        end
        default: begin
        end
        endcase
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            state <= s_idle;
            way_s <= '0;
            ufp_addr_f <= '0;
            ufp_rmask_f <= '0;
            ufp_wmask_f <= '0;
            ufp_wdata_f <= '0;
            linebuf_v <= '0;
            linebuf_tag <= '0;
            linebuf_data <= '0;
        end
        else begin
            state <= state_next;
            write_csb_f <= '0;
            if(state == s_idle) begin
                ufp_addr_f <= ufp_addr;
                ufp_rmask_f <= ufp_rmask;
                ufp_wmask_f <= ufp_wmask;
                ufp_wdata_f <= ufp_wdata;
            end
            if(state == s_hit) begin
                way_s <= way_n;
                if(ufp_rmask_f!='0)begin
                    linebuf_v <= '1;
                    linebuf_tag <= ufp_addr_f[31:5];
                    linebuf_data <= data_buf;
                end
                else begin
                    linebuf_v <= '0;
                end
            end
            if(state == s_allocate && dfp_resp) begin
                linebuf_v <= '1;
                linebuf_tag <= ufp_addr_f[31:5];
                linebuf_data <= dfp_rdata;
                write_csb_f <= '1;
            end
        end
    end

endmodule