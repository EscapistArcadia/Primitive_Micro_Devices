module cache_adapter (
    input   logic               clk,
    input   logic               rst,

    // cache side signals
    input   logic   [31:0]      dfp_addr,
    input   logic               dfp_read,
    input   logic               dfp_write,
    output  logic   [255:0]     dfp_rdata,
    input   logic   [255:0]     dfp_wdata,
    output  logic               dfp_resp,

    // dram side signals
    output  logic   [31:0]      cache_bmem_addr,
    output  logic               cache_bmem_read,
    output  logic               cache_bmem_write,
    output  logic   [63:0]      cache_bmem_wdata,
    input   logic               cache_bmem_ready,
    input   logic   [31:0]      cache_bmem_raddr,
    input   logic   [63:0]      cache_bmem_rdata,
    input   logic               cache_bmem_rvalid
);

            logic   [1:0]       iter, iter_next;
            logic   [63:0]      data_buf[4], data_buf_f[4];
            logic               read_f;

    always_ff @(posedge clk) begin
        if (rst) begin
            iter <= '0;
            read_f <= '1;
            data_buf_f[0] <= '0;
            data_buf_f[1] <= '0;
            data_buf_f[2] <= '0;
            data_buf_f[3] <= '0;
        end
        else if (dfp_read && cache_bmem_rvalid && cache_bmem_raddr==dfp_addr || cache_bmem_ready && dfp_write) begin
            iter <= iter+1'b1;
            data_buf_f[0] <= data_buf[0];
            data_buf_f[1] <= data_buf[1];
            data_buf_f[2] <= data_buf[2];
            data_buf_f[3] <= data_buf[3];
        end

        if(dfp_read && cache_bmem_ready) begin
            read_f <= '0;
        end
        else begin
            read_f <= '1;
        end
    end

    always_comb begin
        data_buf[0] = data_buf_f[0];
        data_buf[1] = data_buf_f[1];
        data_buf[2] = data_buf_f[2];
        data_buf[3] = data_buf_f[3];
        data_buf[iter] = cache_bmem_rdata;
        cache_bmem_read = dfp_read & read_f;
        cache_bmem_write = dfp_write;
        cache_bmem_addr = dfp_addr;
        cache_bmem_wdata = dfp_wdata[{iter, 6'b0}+:64];
        dfp_resp = iter==2'b11;
        dfp_rdata= {data_buf[3], data_buf[2], data_buf[1], data_buf[0]};
    end
    
endmodule