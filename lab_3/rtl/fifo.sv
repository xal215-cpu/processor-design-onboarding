`timescale 1ns/1ps

module fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 4
) (
    input  logic             clk,
    input  logic             reset,

    input  logic             wr_en,
    input  logic [WIDTH-1:0] wr_data,

    input  logic             rd_en,
    output logic [WIDTH-1:0] rd_data,

    output logic             full,
    output logic             empty
);

    localparam PTR_WIDTH = $clog2(DEPTH);

    logic [WIDTH-1:0] mem [0:DEPTH-1];
    logic [PTR_WIDTH-1:0] wr_ptr;
    logic [PTR_WIDTH-1:0] rd_ptr;
    logic [$clog2(DEPTH+1)-1:0] count;

    logic write_ok;
    logic read_ok;

    assign full  = (count == DEPTH);
    assign empty = (count == 0);

    assign write_ok = wr_en && !full;
    assign read_ok  = rd_en && !empty;

    always_ff @(posedge clk) begin
        if (reset) begin
            wr_ptr  <= '0;
            rd_ptr  <= '0;
            count   <= '0;
            rd_data <= '0;
        end
        else begin

            if (write_ok) begin
                mem[wr_ptr] <= wr_data;
                wr_ptr <= wr_ptr + 1'b1;
            end

            if (read_ok) begin
                rd_data <= mem[rd_ptr];
                rd_ptr <= rd_ptr + 1'b1;
            end

            case ({write_ok, read_ok})
                2'b10: count <= count + 1'b1;
                2'b01: count <= count - 1'b1;
                default: count <= count;
            endcase

        end
    end

endmodule
