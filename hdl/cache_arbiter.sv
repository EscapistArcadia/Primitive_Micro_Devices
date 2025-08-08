module cache_arbiter (
    // input  logic        clk,
    // input  logic        rst,

    input   logic   [31:0]      icache_bmem_addr,
    input   logic               icache_bmem_read,
    input   logic               icache_bmem_write,
    input   logic   [63:0]      icache_bmem_wdata,
    output  logic               icache_bmem_ready,
    output  logic   [31:0]      icache_bmem_raddr,
    output  logic   [63:0]      icache_bmem_rdata,
    output  logic               icache_bmem_rvalid,

    input   logic   [31:0]      dcache_bmem_addr,
    input   logic               dcache_bmem_read,
    input   logic               dcache_bmem_write,
    input   logic   [63:0]      dcache_bmem_wdata,
    output  logic               dcache_bmem_ready,
    output  logic   [31:0]      dcache_bmem_raddr,
    output  logic   [63:0]      dcache_bmem_rdata,
    output  logic               dcache_bmem_rvalid,

    output  logic   [31:0]      arbiter_bmem_addr,
    output  logic               arbiter_bmem_read,
    output  logic               arbiter_bmem_write,
    output  logic   [63:0]      arbiter_bmem_wdata,
    input   logic               arbiter_bmem_ready,
    input   logic   [31:0]      arbiter_bmem_raddr,
    input   logic   [63:0]      arbiter_bmem_rdata,
    input   logic               arbiter_bmem_rvalid
);

always_comb begin
    icache_bmem_raddr = arbiter_bmem_raddr;
    dcache_bmem_raddr = arbiter_bmem_raddr;
    icache_bmem_rdata = arbiter_bmem_rdata;
    dcache_bmem_rdata = arbiter_bmem_rdata;
    icache_bmem_rvalid = arbiter_bmem_rvalid;
    dcache_bmem_rvalid = arbiter_bmem_rvalid;

    if(dcache_bmem_read || dcache_bmem_write) begin
        arbiter_bmem_addr = dcache_bmem_addr;
        arbiter_bmem_read = dcache_bmem_read;
        arbiter_bmem_write = dcache_bmem_write;
        arbiter_bmem_wdata = dcache_bmem_wdata;
        icache_bmem_ready = 1'b0;
        dcache_bmem_ready = arbiter_bmem_ready;
    end
    else begin
        arbiter_bmem_addr = icache_bmem_addr;
        arbiter_bmem_read = icache_bmem_read;
        arbiter_bmem_write = icache_bmem_write;
        arbiter_bmem_wdata = icache_bmem_wdata;
        icache_bmem_ready = arbiter_bmem_ready;
        dcache_bmem_ready = arbiter_bmem_ready;
    end
end

endmodule