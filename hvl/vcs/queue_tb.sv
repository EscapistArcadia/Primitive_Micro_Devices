// module top_tb;

//     timeunit 1ps;
//     timeprecision 1ps;

//     int clock_half_period_ps;
//     initial begin
//         $value$plusargs("CLOCK_PERIOD_PS_ECE411=%d", clock_half_period_ps);
//         clock_half_period_ps = clock_half_period_ps / 2;
//     end

//     bit clk;
//     always #(clock_half_period_ps) clk = ~clk;
//     bit rst;

//     parameter DATA_WIDTH = 64; 
//     parameter QUEUE_SIZE = 16;

//     logic [DATA_WIDTH-1:0]  data_in;
//     logic [DATA_WIDTH-1:0]  data_out;
//     logic                   enqueue;
//     logic                   dequeue;
//     logic                   full;
//     logic                   empty;

//     instruction_queue #(
//         .QUEUE_SIZE(QUEUE_SIZE)
//     ) dut (
//         .clk(clk),
//         .rst(rst),
//         .enqueue(enqueue),
//         .data_in(data_in),
//         .dequeue(dequeue),
//         .data_out(data_out),
//         .full(full),
//         .empty(empty)
//     );

//     task enqueue_op(input logic [DATA_WIDTH-1:0] write_data);
//         begin
//             data_in <= write_data;
//             enqueue <= 1'b1;
//             dequeue <= 1'b0;
//             @(posedge clk);
//             data_in <= 'x;
//             enqueue <= 1'b0;
//         end
//     endtask

//     task dequeue_op();
//         begin
//             data_in <= 'x;
//             enqueue <= 1'b0;
//             dequeue <= 1'b1;
//             @(posedge clk);
//             dequeue <= 1'b0;
//         end
//     endtask

//     task simultaneous_test;
//         begin
//             enqueue_op(32'hECEB_AAAA);
//             @(posedge clk);
//             data_in <= 64'(32'hECEB_BBBB);
//             enqueue <= 1'b1;
//             dequeue <= 1'b1;
//             @(posedge clk);
//             data_in <= 'x;
//             enqueue <= 1'b0;
//             dequeue <= 1'b0;
//         end
//     endtask

//     task simultaneous_test2;
//         begin
//             data_in <= 64'(32'hECEB_AAAA);
//             enqueue <= 1'b1;
//             dequeue <= 1'b1;
//             @(posedge clk);
//             data_in <= 64'(32'hECEB_BBBB);
//             enqueue <= 1'b1;
//             dequeue <= 1'b1;
//             @(posedge clk);
//             data_in <= 64'(32'hECEB_CCCC);
//             enqueue <= 1'b1;
//             dequeue <= 1'b1;
//             @(posedge clk);
//             data_in <= 64'(32'hECEB_DDDD);
//             enqueue <= 1'b1;
//             dequeue <= 1'b1;
//             @(posedge clk);
//             data_in <= 64'(32'hECEB_EEEE);
//             enqueue <= 1'b1;
//             dequeue <= 1'b1;
//             @(posedge clk);
//             data_in <= 'x;
//             enqueue <= 1'b0;
//             dequeue <= 1'b0;
//         end
//     endtask

//     task simultaneous_test3;
//         begin
//             underflow_test;
//             @(posedge clk);
//             data_in <= 64'(32'hECEB_CCCC);
//             enqueue <= 1'b1;
//             dequeue <= 1'b1;
//             @(posedge clk);
//             data_in <= 'x;
//             enqueue <= 1'b0;
//             dequeue <= 1'b0;
//         end
//     endtask

//     task queue_test1;
//         begin
//             enqueue_op(32'hECEBAAAA);
//             enqueue_op(32'hECEBBBBB);
//             enqueue_op(32'hECEBCCCC);
//         end
//     endtask

//     task overflow_test;
//         begin
//             enqueue_op(32'hECEBAAAA);
//             enqueue_op(32'hECEBBBBB);
//             enqueue_op(32'hECEBCCCC);
//             enqueue_op(32'hECEBDDDD);
//             enqueue_op(32'hECEBEEEE);
//             enqueue_op(32'hECEBFFFF);
//             enqueue_op(32'hECEB1111);
//             enqueue_op(32'hECEB2222);
//             enqueue_op(32'hECEB3333);
//             enqueue_op(32'hECEB4444);
//             enqueue_op(32'hECEB5555);
//             enqueue_op(32'hECEB6666);
//             enqueue_op(32'hECEB7777);
//             enqueue_op(32'hECEB8888);
//             enqueue_op(32'hECEB9999);
//             enqueue_op(32'hECEB0000);

//             enqueue_op(32'hECEBABCD);
//             enqueue_op(32'hECEBABEF);
//             enqueue_op(32'hECEBACCA);
//         end
//     endtask

//     task underflow_test;
//         begin
//             enqueue_op(32'hECEBAAAA);
//             enqueue_op(32'hECEBBBBB);
//             repeat (16) begin
//                 dequeue_op();;
//             end
//         end
//     endtask

//     task underflow_op;
//         begin
//             repeat (20) begin
//                 dequeue_op();;
//             end
//         end
//     endtask

//     task overflow_underflow;
//         begin
//             overflow_test;
//             underflow_op;
//             enqueue_op(32'hECEBCCCC); // try to enqueue after underflow
//             enqueue_op(32'hECEBDDDD);
//             enqueue_op(32'hECEBEEEE);
//         end
//     endtask

//     task underflow_overflow;
//         begin
//             underflow_test;
//             overflow_test;
//             dequeue_op();
//             dequeue_op();
//             dequeue_op();
//         end
//     endtask

//     initial begin
//         $fsdbDumpfile("dump.fsdb");
//         if ($test$plusargs("NO_DUMP_ALL_ECE411")) begin
//             $fsdbDumpvars(0, dut, "+all");
//             $fsdbDumpoff();
//         end else begin
//             $fsdbDumpvars(0, "+all");
//         end
//         rst = 1'b1;
//         repeat (2) @(posedge clk);
//         rst <= 1'b0;
//         // queue_test1;
//         // overflow_test;
//         // underflow_test;
//         // overflow_underflow;
//         // underflow_overflow;
//         // simultaneous_test1;
//         simultaneous_test2;
//         // simultaneous_test3;
//         #5000
//         $finish;
//     end


// endmodule : top_tb