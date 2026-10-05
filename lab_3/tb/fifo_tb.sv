`timescale 1ns/1ps

module fifo_tb;

    logic clk;
    logic reset;

    logic wr_en;
    logic [7:0] wr_data;

    logic rd_en;
    logic [7:0] rd_data;

    logic full;
    logic empty;

    logic [7:0] expected_queue[$];
    logic [7:0] expected_data;
    logic do_write;
    logic do_read;
    logic [31:0] rand_value;

    fifo #(
        .WIDTH(8),
        .DEPTH(4)
    ) dut (
        .clk(clk),
        .reset(reset),
        .wr_en(wr_en),
        .wr_data(wr_data),
        .rd_en(rd_en),
        .rd_data(rd_data),
        .full(full),
        .empty(empty)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    task do_write_task(input logic [7:0] value);
        begin
            @(negedge clk);
            wr_en = 1;
            wr_data = value;
            rd_en = 0;

            @(posedge clk);
            #1;

            @(negedge clk);
            wr_en = 0;
        end
    endtask

    task do_read_task(input logic [7:0] expected);
        begin
            @(negedge clk);
            rd_en = 1;
            wr_en = 0;

            @(posedge clk);
            #1;

            if (rd_data !== expected)
                $fatal(
                    1,
                    "Expected rd_data=%0d, got %0d",
                    expected,
                    rd_data
                );

            @(negedge clk);
            rd_en = 0;
        end
    endtask

    initial begin
        reset = 1;
        wr_en = 0;
        rd_en = 0;
        wr_data = 0;

        @(posedge clk);
        #1;

        if (!empty)
            $fatal(1, "FIFO should be empty after reset");

        reset = 0;

        // Directed tests
        do_write_task(8'd10);

        if (empty)
            $fatal(1, "FIFO should not be empty after write");

        do_read_task(8'd10);

        if (!empty)
            $fatal(1, "FIFO should be empty after read");

        do_write_task(8'd10);
        do_write_task(8'd20);
        do_write_task(8'd30);

        do_read_task(8'd10);
        do_read_task(8'd20);
        do_read_task(8'd30);

        do_write_task(8'd1);
        do_write_task(8'd2);
        do_write_task(8'd3);
        do_write_task(8'd4);

        if (!full)
            $fatal(1, "FIFO should be full");

        @(negedge clk);
        wr_en = 1;
        wr_data = 8'd99;

        @(posedge clk);
        #1;

        @(negedge clk);
        wr_en = 0;

        do_read_task(8'd1);
        do_read_task(8'd2);
        do_read_task(8'd3);
        do_read_task(8'd4);

        if (!empty)
            $fatal(1, "FIFO should be empty after draining");

        @(negedge clk);
        rd_en = 1;

        @(posedge clk);
        #1;

        @(negedge clk);
        rd_en = 0;

        if (!empty)
            $fatal(1, "FIFO should remain empty");

        // Pointer wraparound
        do_write_task(8'd11);
        do_write_task(8'd22);
        do_write_task(8'd33);
        do_write_task(8'd44);

        do_read_task(8'd11);
        do_read_task(8'd22);

        do_write_task(8'd55);
        do_write_task(8'd66);

        do_read_task(8'd33);
        do_read_task(8'd44);
        do_read_task(8'd55);
        do_read_task(8'd66);

        // Simultaneous read/write
        do_write_task(8'd7);
        do_write_task(8'd8);

        @(negedge clk);
        wr_en = 1;
        wr_data = 8'd9;
        rd_en = 1;

        @(posedge clk);
        #1;

        if (rd_data !== 8'd7)
            $fatal(1, "Simultaneous read/write returned wrong data");

        @(negedge clk);
        wr_en = 0;
        rd_en = 0;

        do_read_task(8'd8);
        do_read_task(8'd9);

        if (!empty)
            $fatal(1, "FIFO should end empty");

        // Randomized testing
        reset = 1;
        wr_en = 0;
        rd_en = 0;
        wr_data = 0;
        expected_queue.delete();

        @(posedge clk);
        #1;

        reset = 0;

        repeat (200) begin
            @(negedge clk);

            rand_value = $urandom_range(1, 0);
            wr_en = rand_value[0];

            rand_value = $urandom_range(1, 0);
            rd_en = rand_value[0];

            rand_value = $urandom_range(255, 0);
            wr_data = rand_value[7:0];

            do_write = wr_en && !full;
            do_read  = rd_en && !empty;

            if (do_read)
                expected_data = expected_queue.pop_front();

            if (do_write)
                expected_queue.push_back(wr_data);

            @(posedge clk);
            #1;

            if (do_read && rd_data !== expected_data)
                $fatal(
                    1,
                    "Random read mismatch: expected=%0d got=%0d",
                    expected_data,
                    rd_data
                );

            if (empty !== (expected_queue.size() == 0))
                $fatal(1, "Incorrect empty flag");

            if (full !== (expected_queue.size() == 4))
                $fatal(1, "Incorrect full flag");
        end

        $display("All FIFO tests passed!");
        $finish;
    end

    initial begin
        #100us;
        $fatal(1, "Simulation timed out");
    end

endmodule
