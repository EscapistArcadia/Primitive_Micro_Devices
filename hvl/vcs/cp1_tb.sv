//  module top_tb;
//      //---------------------------------------------------------------------------------
//      // Waveform generation.
//      //---------------------------------------------------------------------------------
//      initial begin
//          $fsdbDumpfile("dump.fsdb");
//          $fsdbDumpvars(0, "+all");
//      end
//      //---------------------------------------------------------------------------------
//      // TODO: Declare cache port signals:
//      //---------------------------------------------------------------------------------
//      logic clk;
//      logic rst;
//      // CPU-side (upward facing port) signals.
//      logic   [31:0]      bmem_addr;
//      logic               bmem_read;
//      logic               bmem_write;
//      logic   [63:0]      bmem_wdata;
//      logic               bmem_ready;
//      logic   [31:0]      bmem_raddr;
//      logic   [63:0]      bmem_rdata;
//      logic               bmem_rvalid;
//      logic               dequeue;
//      logic   [31:0]      data;
//      //---------------------------------------------------------------------------------
//      // TODO: Instantiate the DUT:
//      //---------------------------------------------------------------------------------
//      cpu dut (
//          .clk            (clk),
//          .rst            (rst),
//          .bmem_addr      (bmem_addr),                                          // memory address to access
//          .bmem_read      (bmem_read),                                          // read operation
//          .bmem_write     (bmem_write),                                         // write operation
//          .bmem_wdata     (bmem_wdata),                                         // data to write, output serially
//          .bmem_ready     (bmem_ready),                                         // TODO: default 1?
//          .bmem_raddr     (bmem_raddr),                                         // memory address finished reading
//          .bmem_rdata     (bmem_rdata),                                         // data finished reading
//          .bmem_rvalid    (bmem_rvalid),
//          .dequeue        (dequeue),
//          .data           (data)
//      );
//      //---------------------------------------------------------------------------------
//      // TODO: Generate a clock:
//      //---------------------------------------------------------------------------------
//      always #1ns clk = ~clk;
//      //---------------------------------------------------------------------------------
//      // TODO: Verification constructs (recommended)
//      //---------------------------------------------------------------------------------
//      // Here's ASCII art of how the recommended testbench works:
//      //                                +--------------+                           +-----------+
//      //                       +------->| Golden model |---output_transaction_t--->|           |
//      //                       |        +--------------+                           |           |
//      //  input_transaction ---+                                                   | Check ==  |
//      //                       |        +------+                                   |           |
//      //                       +------->|  DUT |---output_transaction_t----------->|           |
//      //                                +------+                                   +-----------+
//      logic [64:0] dmem_input[1024];
//      int i_iter, o_iter;
//      //---------------------------------------------------------------------------------
//      // TODO: Main initial block that calls your tasks, then calls $finish
//      //---------------------------------------------------------------------------------
//      initial begin
//          // Initialize signals.
//          clk = '0;
//          rst = '1;
//          bmem_ready='1;
//          bmem_rvalid='0;
//          // Drive reset.
//          repeat (3) @(posedge clk);
//          rst = '0;
//          i_iter=1024;
//          o_iter=1024*2;
//          for(int i=0; i<1024; ++i) begin
//              dmem_input[i][63:0]={i*2+1, i*2};
//              dmem_input[i][64]=dmem_input[i][63];
//          end
//          // Drive the DUT.
//          fork
//              while (i_iter) begin
//                  bmem_rvalid='0;
//                  if(!bmem_read) begin
//                      @(posedge clk);
//                      continue;
//                  end
//                  for(int i=$urandom_range(1,5); i>0; --i) begin
//                      @(posedge clk);
//                  end
//                  for(int i=0; i<4; ++i) begin
//                      bmem_rvalid='1;
//                      bmem_raddr=bmem_addr;
//                      bmem_rdata=dmem_input[(bmem_addr-32'hAAAAA000)/8+i][63:0];
//                      i_iter=i_iter-1;
//                      @(posedge clk);
//                  end
//              end
//              begin
//                  while (o_iter) begin
//                      if($urandom_range(0,5)) begin
//                          @(posedge clk);
//                          dequeue='0;
//                          continue;
//                      end
//                      dequeue='1;
//                      o_iter=o_iter-1;
//                      @(posedge clk);
//                  end
//              end
//          join
//          $finish;
//      end
//  endmodule : top_tb
