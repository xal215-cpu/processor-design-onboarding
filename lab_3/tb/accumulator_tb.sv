`timescale 1ns/1ps

module accumulator_tb;

    logic clk;
    logic reset;
    logic enable;
    logic [7:0] data_in;
    logic [7:0] sum;
    logic [7:0] expected_sum;
    logic [31:0] rand_value;

    accumulator #(
        .WIDTH(8)
    ) dut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .data_in(data_in),
        .sum(sum)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    task check_sum(input logic [7:0] expected);
        begin
            if (sum !== expected)
                $fatal(
                    1,
                    "Expected sum=%0d, got sum=%0d",
                    expected,
                    sum
                );
        end
    endtask

    initial begin
        // Directed tests
        reset = 1;
        enable = 0;
        data_in = 0;

        @(posedge clk);
        #1;
        check_sum(8'd0);

        reset = 0;
        enable = 1;
        data_in = 8'd5;

        @(posedge clk);
        #1;
        check_sum(8'd5);

        data_in = 8'd10;

        @(posedge clk);
        #1;
        check_sum(8'd15);

        data_in = 8'd20;

        @(posedge clk);
        #1;
        check_sum(8'd35);

        enable = 0;
        data_in = 8'd50;

        @(posedge clk);
        #1;
        check_sum(8'd35);

        enable = 1;
        data_in = 8'd5;

        @(posedge clk);
        #1;
        check_sum(8'd40);

        // Overflow test
        reset = 1;

        @(posedge clk);
        #1;
        check_sum(8'd0);

        reset = 0;
        enable = 1;
        data_in = 8'd250;

        @(posedge clk);
        #1;
        check_sum(8'd250);

        data_in = 8'd10;

        @(posedge clk);
        #1;
        check_sum(8'd4);

        // Randomized testing
        reset = 1;
        enable = 0;
        data_in = 0;
        expected_sum = 0;

        @(posedge clk);
        #1;
        check_sum(expected_sum);

        reset = 0;

        repeat (100) begin
            @(negedge clk);

            rand_value = $urandom_range(255, 0);
            data_in = rand_value[7:0];

            rand_value = $urandom_range(1, 0);
            enable = rand_value[0];

            if (enable)
                expected_sum = expected_sum + data_in;

            @(posedge clk);
            #1;

            check_sum(expected_sum);
        end

        $display("All accumulator tests passed!");
        $finish;
    end

    initial begin
        #100us;
        $fatal(1, "Simulation timed out");
    end

endmodule
