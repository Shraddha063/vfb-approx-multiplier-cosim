module full_adder(
    input A, B, Cin,
    output Sum, Cout
);
wire ab, AxorB;
assign ab = A & B;
assign AxorB = A ^ B;
assign Sum = AxorB ^ Cin;
assign Cout = Cin ? (ab | AxorB) : ab;
endmodule
