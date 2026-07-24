module approx_4_2_compressor(
    input A, B, C, D,
    output Sum, Carry
);
wire ab, cd, ab_or, cd_or, Y0, Y1, Y2, correction, approx_enable, carry_en;

assign ab = A & B;
assign cd = C & D;
assign ab_or = A | B;
assign cd_or = C | D;

assign approx_enable = ab_or | cd_or;
assign Y0 = approx_enable;
assign Y1 = ab_or & cd_or;
assign Y2 = approx_enable ? (ab | cd) : 1'b0;

assign correction = (ab & ~cd_or) | (cd & ~ab_or);
assign carry_en = Y1 | Y2;

assign Sum = approx_enable ? ((~Y1 | Y2) & ~correction) : 1'b0;
assign Carry = approx_enable ? carry_en : 1'b0;
endmodule

module half_adder(
    input A, B,
    output Sum, Carry
);
    assign Sum   = A ^ B;
    assign Carry = A & B;
endmodule
