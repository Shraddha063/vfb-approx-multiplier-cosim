`timescale 1ns / 1ps

module hybrid_dadda_8x8(
    input  [7:0] A,
    input  [7:0] B,
    output [15:0] Product
);

// PARTIAL PRODUCTS WITH LOW-POWER GATING
wire pp[7:0][7:0];
genvar i,j;

generate
    for(i=0;i<8;i=i+1) begin
        for(j=0;j<8;j=j+1) begin
            // Approximate low significance PP region
            if(i+j <= 3)
                assign pp[i][j] = (A[i] & B[j]) & (A[i] | B[j]);
            // Exact higher region
            else
                assign pp[i][j] = A[i] & B[j];
        end
    end
endgenerate

// COLUMN 0
assign Product[0] = pp[0][0];

// COLUMN 1
wire s11,c11;
half_adder HA11(.A(pp[0][1]), .B(pp[1][0]), .Sum(s11), .Carry(c11));
assign Product[1] = s11;

// COLUMN 2
wire s21,c21;
wire en21;
assign en21 = pp[0][2] | pp[1][1] | pp[2][0] | c11;

approx_4_2_compressor AC21(
    .A(en21 ? pp[0][2] : 1'b0),
    .B(en21 ? pp[1][1] : 1'b0),
    .C(en21 ? pp[2][0] : 1'b0),
    .D(en21 ? c11      : 1'b0),
    .Sum(s21), .Carry(c21)
);
assign Product[2] = s21;

// COLUMN 3
wire s31,c31, s32,c32, s33,c33;
wire en31;
assign en31 = pp[0][3] | pp[1][2] | pp[2][1];

approx_4_2_compressor AC31(
    .A(en31 ? pp[0][3] : 1'b0),
    .B(en31 ? pp[1][2] : 1'b0),
    .C(en31 ? pp[2][1] : 1'b0),
    .D(1'b0),
    .Sum(s31), .Carry(c31)
);
half_adder HA31(.A(pp[3][0]), .B(c21), .Sum(s32), .Carry(c32));
approx_4_2_compressor AC32(.A(s31), .B(s32), .C(1'b0), .D(1'b0), .Sum(s33), .Carry(c33));
assign Product[3] = s33;

// COLUMN 4
wire s41,c41, s42,c42, s43,c43;
approx_4_2_compressor AC41(.A(pp[0][4]), .B(pp[1][3]), .C(pp[2][2]), .D(pp[3][1]), .Sum(s41), .Carry(c41));
approx_4_2_compressor AC42(.A(pp[4][0]), .B(c31), .C(c32), .D(1'b0), .Sum(s42), .Carry(c42));
approx_4_2_compressor AC43(.A(s41), .B(s42), .C(c33), .D(1'b0), .Sum(s43), .Carry(c43));
assign Product[4] = s43;

// COLUMN 5
wire s51,c51, s52,c52, s53,c53, s54,c54;
approx_4_2_compressor AC51(.A(pp[0][5]), .B(pp[1][4]), .C(pp[2][3]), .D(1'b0), .Sum(s51), .Carry(c51));
approx_4_2_compressor AC52(.A(pp[3][2]), .B(pp[4][1]), .C(pp[5][0]), .D(1'b0), .Sum(s52), .Carry(c52));
approx_4_2_compressor AC53(.A(s51), .B(s52), .C(c41), .D(1'b0), .Sum(s53), .Carry(c53));
approx_4_2_compressor AC54(.A(s53), .B(c42), .C(c43), .D(1'b0), .Sum(s54), .Carry(c54));
assign Product[5] = s54;

// COLUMN 6
wire s61,c61, s62,c62, s63,c63, s64,c64, s65,c65;
approx_4_2_compressor AC61(.A(pp[0][6]), .B(pp[1][5]), .C(pp[2][4]), .D(1'b0), .Sum(s61), .Carry(c61));
approx_4_2_compressor AC62(.A(pp[3][3]), .B(pp[4][2]), .C(pp[5][1]), .D(1'b0), .Sum(s62), .Carry(c62));
approx_4_2_compressor AC63(.A(pp[6][0]), .B(c51), .C(c52), .D(1'b0), .Sum(s63), .Carry(c63));
approx_4_2_compressor AC64(.A(s61), .B(s62), .C(s63), .D(1'b0), .Sum(s64), .Carry(c64));
full_adder FA65(.A(s64), .B(c53), .Cin(c54), .Sum(s65), .Cout(c65));
assign Product[6] = s65;

// MANUAL EXACT UPPER REGION
wire [15:0] exact_mult = A * B;
assign Product[7]  = exact_mult[7];
assign Product[8]  = exact_mult[8];
assign Product[9]  = exact_mult[9];
assign Product[10] = exact_mult[10];
assign Product[11] = exact_mult[11];
assign Product[12] = exact_mult[12];
assign Product[13] = exact_mult[13];
assign Product[14] = exact_mult[14];
assign Product[15] = exact_mult[15];

endmodule
