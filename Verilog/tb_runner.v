`timescale 1ns / 1ps

module tb_runner;
    reg [7:0] A;
    reg [7:0] B;
    wire [15:0] Product;

    integer file_in, file_out, status;

    hybrid_dadda_8x8 uut (
        .A(A),
        .B(B),
        .Product(Product)
    );

    initial begin
        file_in = $fopen("input_pairs.txt", "r");
        file_out = $fopen("hardware_outputs.txt", "w");

        while (!$feof(file_in)) begin
            status = $fscanf(file_in, "%d %d\n", A, B);
            #10;
            $fdisplay(file_out, "%d", Product);
        end

        $fclose(file_in);
        $fclose(file_out);
        $finish;
    end
endmodule
