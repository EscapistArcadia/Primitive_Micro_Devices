//-----------------------------------------------------------------------------
// Title                 : random_tb
// Project               : ECE 411 mp_verif
//-----------------------------------------------------------------------------
// File                  : random_tb.sv
// Author                : ECE 411 Course Staff
//-----------------------------------------------------------------------------
// IMPORTANT: If you don't change the random seed, every time you do a `make run`
// you will run the /same/ random test. SystemVerilog calls this "random stability",
// and it's to ensure you can reproduce errors as you try to fix the DUT. Make sure
// to change the random seed or run more instructions if you want more extensive
// coverage.
//------------------------------------------------------------------------------
module random_tb
import rv32cpu_type::*;
(
    mem_itf_banked.mem itf
);

    `include "randinst.svh"

    RandInst random_gens[0:7];

    // Initialize each instance in the array.
    initial begin
        for (int i = 0; i < 8; i++) begin
            random_gens[i] = new();
        end
    end

    RandInst gen = new();
    RandInst gen1 = new();

    // Do a bunch of LUIs to get useful register state.
    task init_register_state();
        for (int i = 0; i < 32; i++) begin
            @(posedge itf.clk iff itf.read);
                gen.randomize() with {
                    instr.j_type.opcode == op_b_lui;
                    instr.j_type.rd     == i[4:0];
                    instr.j_type.rd     != '0;
                };

                gen1.randomize() with {
                    instr.j_type.opcode == op_b_lui;
                    instr.j_type.rd     == i[4:0];
                    instr.j_type.rd     != '0;
                };
                itf.rdata  <= {gen1.instr.word, gen.instr.word};

            @(posedge itf.clk);
            itf.ready  <= 1'b1;
            itf.rvalid <= 1'b1;
        end
    endtask : init_register_state

    // Note that this memory model is not consistent! It ignores
    // writes and always reads out a random, valid instruction.
    task run_random_instrs();
        repeat (10000) begin
            logic [255:0] addr;
            @(posedge itf.clk iff itf.read);

            for (int i = 0; i < 8; i++) begin
                random_gens[i].randomize();
            end

            for (int i = 0; i < 8; i++) begin
                addr[i*32 +: 32] = random_gens[i].instr.word;
            end

            for (int burst = 0; burst < 4; burst++) begin
                @(posedge itf.clk);
                itf.rdata  <= addr[burst*64 +: 64];
                itf.rvalid <= 1'b1;
                itf.raddr  <= itf.addr;
            end
            
            @(posedge itf.clk);
            itf.rdata <= 'x;
            itf.rvalid <= 1'b0;
        end
    endtask : run_random_instrs

    always @(posedge itf.clk iff !itf.rst) begin
        if ($isunknown(itf.read) || $isunknown(itf.write)) begin
            $error("Memory Error: read/write containes 'x");
            itf.error <= 1'b1;
        end
        if ((|itf.read) && (|itf.write)) begin
            $error("Memory Error: Simultaneous memory read and write");
            itf.error <= 1'b1;
        end
        if ((|itf.read) || (|itf.write)) begin
            if ($isunknown(itf.addr)) begin
                $error("Memory Error: Address contained 'x");
                itf.error <= 1'b1;
            end
            // Only check for 16-bit alignment since instructions are
            // allowed to be at 16-bit boundaries due to JALR.
            if (itf.addr[0] != 1'b0) begin
                $error("Memory Error: Address is not 16-bit aligned");
                itf.error <= 1'b1;
            end
        end
    end

    
    // A single initial block ensures random stability.
    initial begin

        // Wait for reset.
        itf.ready <= 1'b1;
        itf.rvalid <= 1'b0;
        @(posedge itf.clk iff itf.rst == 1'b0);
        itf.ready <= 1'b1;


        // Get some useful state into the processor by loading in a bunch of state.
        // init_register_state();

        // Run!
        run_random_instrs();

        // Finish up
        $display("Random testbench finished!");
        $finish;
    end

endmodule : random_tb
