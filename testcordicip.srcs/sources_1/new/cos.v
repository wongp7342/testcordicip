`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/26/2024 05:34:10 PM
// Design Name: 
// Module Name: cos
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module RangeReducer(
    input clock, input reset,
    input [31:0] in, output reg [31:0] out);
     
     wire [31:0] TWO_PI;
     
    assign TWO_PI = 32'h40c90fdb;
     
     wire a_ready, b_ready;
     wire a_valid, b_valid;
     
     wire [31:0] div_out;
     wire div_ready, div_valid;
     
     assign a_valid = 1;
     assign b_valid = 1;
     
    divider div(
        .aclk(clock),
        .s_axis_a_tdata(in),
        .s_axis_a_tvalid(a_valid),
        .s_axis_b_tdata(TWO_PI),
        .s_axis_b_tvalid(b_valid),
        .m_axis_result_tdata(div_out),
        .m_axis_result_tvalid(div_valid));
     

     wire [31:0] extract_out;
     
     FP_extract extract(
     .io_in_a(div_out),
     .io_out_frac(extract_out));
     
     wire mul_a_ready, mul_b_ready;
     wire mul_a_valid, mul_b_valid;
     wire [31:0] mul_out;
     wire mul_ready, mul_valid;
     
     assign mul_a_valid = 1;
     assign mul_b_valid = 1;
     assign mul_ready = 1;
     
     multiplier mul(
        .aclk(clock),
        .s_axis_a_tdata(extract_out),
        .s_axis_a_tvalid(mul_a_valid),
        .s_axis_b_tdata(TWO_PI),
        .s_axis_b_tvalid(mul_b_valid),
        .m_axis_result_tdata(mul_out),
        .m_axis_result_tvalid(mul_valid)
     );
     

    always @(posedge clock) begin
        out <= mul_valid == 1 ? mul_out : 32'h0;
    end

endmodule

module sub (input clock,
    input [31:0] a, input [31:0] b,
    output reg [31:0] out);
    
    wire avalid, bvalid;
    wire outvalid;
    wire [31:0] outwire;
    
    assign avalid = 1;
    assign bvalid = 1;
    subtractor impl(
        .aclk(clock),
        .s_axis_a_tdata(a),
        .s_axis_a_tvalid(avalid),
        .s_axis_b_tdata(b),
        .s_axis_b_tvalid(bvalid),
        .m_axis_result_tdata(outwire),
        .m_axis_result_tvalid(outvalid)  
    );
    
    always @(posedge clock) begin
        out <= outvalid == 1 ? outwire : 32'h0;
    end
    
endmodule

module Register (input clock, input reset, input [31:0] in, output reg [31:0] out);

    always @(posedge clock) begin
        if(reset == 1) begin
            out <= 32'h0;
        end else begin
            out <= in;
        end
    end

endmodule

module RegChain #(parameter COUNT = 8) (
       input clock,
       input reset,
       input [31:0] in,
       output reg [31:0] out
    );
    
    wire [31:0] regout [COUNT - 1 : 0];
    
    Register r1(.clock(clock), .reset(reset),
                .in(in), .out(regout[0]));
    
    genvar idx;
    generate
        for(idx = 1; idx < COUNT; idx = idx + 1) begin
            Register r(
                .clock(clock),
                .reset(reset),
                .in(regout[idx - 1]),
                .out(regout[idx]));     
        end
    endgenerate
    
    always @(posedge clock) begin
        out <= regout[COUNT - 1];
    end
    
endmodule

module cos(
	input clock,
	input reset,
	input [31:0] z0,
	input valid,
	output reg [31:0] out_x,
	output reg [31:0] out_y,
	output outvalid
    );
    
    wire signed [31:0] PI_DIV_TWO, TWO_PI, PI, THREE_PI_DIV_TWO;
    assign PI_DIV_TWO = 32'h3fc90fdb;
    assign TWO_PI = 32'h40c90fdb;
    assign PI = 32'h40490fdb;
    assign THREE_PI_DIV_TWO = 32'h4096cbe4;
    
    wire [63:0] out;
    wire signed [31:0] fixedin;
    wire [31:0] fixed_out_x, fixed_out_y;
    
    wire [31:0] reducer_out;
    
    
    wire signed [31:0] theta;
    wire signed [31:0] cordicin;
    
    RangeReducer reducer(
    .clock(clock), .reset(reset),
    .in(z0), .out(reducer_out));

    assign theta = {1'b0, reducer_out[30:0]};

    wire signed [31:0] sub1out, sub2out, sub3out;
    
    sub sub1(
        .clock(clock),
        .a(theta),
        .b(TWO_PI),
        .out(sub1out));
        
   sub sub2(
        .clock(clock),
        .a(PI),
        .b(theta),
        .out(sub2out));
   
    sub sub3(
        .clock(clock),
        .a(theta),
        .b(32'h0),
        .out(sub3out));
    
    wire [31:0] floatin;
    wire [1:0] mode, modeout;
    
    assign floatin = (sub3out >= THREE_PI_DIV_TWO) ? sub1out :
        (sub3out >= PI_DIV_TWO && sub3out < THREE_PI_DIV_TWO) ? sub2out :
        sub3out;
    assign mode = (sub3out >= THREE_PI_DIV_TWO) ? 2'd0 :
        (sub3out >= PI_DIV_TWO && sub3out < THREE_PI_DIV_TWO) ? 2'd1 :
        2'd2;
        
     RegChain #(.COUNT(37)) rchain (
        .clock(clock), .reset(reset),
        .in(mode), .out(modeout)
     );
    
    wire cordicvalid;
    assign cordicvalid = 1;
    cordic cordic(
    .aclk(clock),
    .s_axis_phase_tdata(fixedin),
    .s_axis_phase_tvalid(cordicvalid),
    .m_axis_dout_tdata(out),
    .m_axis_dout_tvalid(outvalid)
    );

    assign valid = 1;
    
    Q3_VFloatToFixed32 inputtofixed(
	.in(floatin),
	.out(fixedin));
    
    Q2_VFixedToFloat32 fixedtofloatx(
	.in(out[31:0]),
	.out(fixed_out_x));
	
	Q2_VFixedToFloat32 fixedtofloaty(
	.in(out[63:32]),
	.out(fixed_out_y));
    
    always @(posedge clock) begin
        out_x <= modeout == 1 ? {~fixed_out_x[31], fixed_out_x[30:0]} : fixed_out_x;
        out_y <= modeout == 1 ? {~fixed_out_y[31], fixed_out_y[30:0]} : fixed_out_y;
    end
    
endmodule


module VCLZ32(
	input [31:0] in,
	output [31:0] out
);

wire [31:0] ax, bx, cx, dx, ex;

assign ax = in;
assign bx = (ax & 32'hFFFF0000) == 32'h0 ? ax << 16 : ax;
assign cx = (bx & 32'hFF000000) == 32'h0 ? bx << 8 : bx;
assign dx = (cx & 32'hF0000000) == 32'h0 ? cx << 4 : cx;
assign ex = (dx & 32'hC0000000) == 32'h0 ? dx << 2 : dx;

assign out = {(ax & 32'hFFFF0000) == 32'h0, (bx & 32'hFF000000) == 32'h0,
	(cx & 32'hF0000000) == 32'h0, (dx & 32'hC0000000) == 32'h0,
	(ex & 32'h80000000) == 32'h0};

endmodule

module VFloatToFixed32(
	input [31:0] in,
	output [31:0] out
);
	wire [31:0] frac;
	wire signed [7:0] exp;
	wire sign;
	wire signed [7:0] shiftamt;
	
	assign frac = {9'b000000000, in[22:0]};
	assign exp = in[30:23];
	assign sign = in[31];
	assign shiftamt = exp - 8'sd127;
	
	wire signed [31:0] data = shiftamt[7] == 1 ?
	(((frac[31:0] | 32'h00800000) << 5) >> (-shiftamt)) :
	(((frac[31:0] | 32'h00800000) << 5) << shiftamt);
	assign out = in[31] == 1 ? (~data + 1) : data;
	
endmodule

module VFixedToFloat32(
	input [31:0] in,
	output [31:0] out);
	
	wire sign;
	wire signed [7:0] exp;
	wire signed [22:0] frac;
	wire signed [31:0] data;
	wire [31:0] clzout;
	wire [18:0] leadingzeros;
	
	assign sign = in[31];
	assign data = in[31] == 1 ? (~in + 1) : in;
	
	VCLZ32 clz32(
		.in(data),
		.out(clzout)
	);
	
	assign leadingzeros = {14'h0, clzout[4:0]};
	assign exp = ((8'sd4 - 8'sd1) - leadingzeros) + 8'sd127;
	assign frac = (data << (leadingzeros + 1)) >> (32 - 23);
	assign out = {sign, exp, frac[22:0]};
	
endmodule

module Q3_VFloatToFixed32(
	input [31:0] in,
	output [31:0] out
);
	wire [31:0] frac;
	wire signed [7:0] exp;
	wire sign;
	wire signed [7:0] shiftamt;
	
	assign frac = {9'b000000000, in[22:0]};
	assign exp = in[30:23];
	assign sign = in[31];
	assign shiftamt = exp - 8'sd127;
	
	wire signed [31:0] data = shiftamt[7] == 1 ?
	(((frac[31:0] | 32'h00800000) << 6) >> (-shiftamt)) :
	(((frac[31:0] | 32'h00800000) << 6) << shiftamt);
	assign out = in[31] == 1 ? (~data + 1) : data;
	
endmodule

module Q3_VFixedToFloat32(
	input [31:0] in,
	output [31:0] out);
	
	wire sign;
	wire signed [7:0] exp;
	wire signed [22:0] frac;
	wire signed [31:0] data;
	wire [31:0] clzout;
	wire [18:0] leadingzeros;
	
	assign sign = in[31];
	assign data = in[31] == 1 ? (~in + 1) : in;
	
	VCLZ32 clz32(
		.in(data),
		.out(clzout)
	);
	
	assign leadingzeros = {14'h0, clzout[4:0]};
	assign exp = ((8'sd3 - 8'sd1) - leadingzeros) + 8'sd127;
	assign frac = (data << (leadingzeros + 1)) >> (32 - 23);
	assign out = {sign, exp, frac[22:0]};
	
endmodule


module Q2_VFloatToFixed32(
	input [31:0] in,
	output [31:0] out
);
	wire [31:0] frac;
	wire signed [7:0] exp;
	wire sign;
	wire signed [7:0] shiftamt;
	
	assign frac = {9'b000000000, in[22:0]};
	assign exp = in[30:23];
	assign sign = in[31];
	assign shiftamt = exp - 8'sd127;
	
	wire signed [31:0] data = shiftamt[7] == 1 ?
	(((frac[31:0] | 32'h00800000) << 7) >> (-shiftamt)) :
	(((frac[31:0] | 32'h00800000) << 7) << shiftamt);
	assign out = in[31] == 1 ? (~data + 1) : data;
	
endmodule

module Q2_VFixedToFloat32(
	input [31:0] in,
	output [31:0] out);
	
	wire sign;
	wire signed [7:0] exp;
	wire signed [22:0] frac;
	wire signed [31:0] data;
	wire [31:0] clzout;
	wire [18:0] leadingzeros;
	
	assign sign = in[31];
	assign data = in[31] == 1 ? (~in + 1) : in;
	
	VCLZ32 clz32(
		.in(data),
		.out(clzout)
	);
	
	assign leadingzeros = {14'h0, clzout[4:0]};
	assign exp = ((8'sd2 - 8'sd1) - leadingzeros) + 8'sd127;
	assign frac = (data << (leadingzeros + 1)) >> (32 - 23);
	assign out = {sign, exp, frac[22:0]};
	
endmodule

module leadingOneDetector(
  input  [22:0] io_in,
  output [4:0]  io_out
);
  wire [1:0] _hotValue_T = io_in[1] ? 2'h2 : 2'h1; // @[Mux.scala 47:70]
  wire [1:0] _hotValue_T_1 = io_in[2] ? 2'h3 : _hotValue_T; // @[Mux.scala 47:70]
  wire [2:0] _hotValue_T_2 = io_in[3] ? 3'h4 : {{1'd0}, _hotValue_T_1}; // @[Mux.scala 47:70]
  wire [2:0] _hotValue_T_3 = io_in[4] ? 3'h5 : _hotValue_T_2; // @[Mux.scala 47:70]
  wire [2:0] _hotValue_T_4 = io_in[5] ? 3'h6 : _hotValue_T_3; // @[Mux.scala 47:70]
  wire [2:0] _hotValue_T_5 = io_in[6] ? 3'h7 : _hotValue_T_4; // @[Mux.scala 47:70]
  wire [3:0] _hotValue_T_6 = io_in[7] ? 4'h8 : {{1'd0}, _hotValue_T_5}; // @[Mux.scala 47:70]
  wire [3:0] _hotValue_T_7 = io_in[8] ? 4'h9 : _hotValue_T_6; // @[Mux.scala 47:70]
  wire [3:0] _hotValue_T_8 = io_in[9] ? 4'ha : _hotValue_T_7; // @[Mux.scala 47:70]
  wire [3:0] _hotValue_T_9 = io_in[10] ? 4'hb : _hotValue_T_8; // @[Mux.scala 47:70]
  wire [3:0] _hotValue_T_10 = io_in[11] ? 4'hc : _hotValue_T_9; // @[Mux.scala 47:70]
  wire [3:0] _hotValue_T_11 = io_in[12] ? 4'hd : _hotValue_T_10; // @[Mux.scala 47:70]
  wire [3:0] _hotValue_T_12 = io_in[13] ? 4'he : _hotValue_T_11; // @[Mux.scala 47:70]
  wire [3:0] _hotValue_T_13 = io_in[14] ? 4'hf : _hotValue_T_12; // @[Mux.scala 47:70]
  wire [4:0] _hotValue_T_14 = io_in[15] ? 5'h10 : {{1'd0}, _hotValue_T_13}; // @[Mux.scala 47:70]
  wire [4:0] _hotValue_T_15 = io_in[16] ? 5'h11 : _hotValue_T_14; // @[Mux.scala 47:70]
  wire [4:0] _hotValue_T_16 = io_in[17] ? 5'h12 : _hotValue_T_15; // @[Mux.scala 47:70]
  wire [4:0] _hotValue_T_17 = io_in[18] ? 5'h13 : _hotValue_T_16; // @[Mux.scala 47:70]
  wire [4:0] _hotValue_T_18 = io_in[19] ? 5'h14 : _hotValue_T_17; // @[Mux.scala 47:70]
  wire [4:0] _hotValue_T_19 = io_in[20] ? 5'h15 : _hotValue_T_18; // @[Mux.scala 47:70]
  wire [4:0] _hotValue_T_20 = io_in[21] ? 5'h16 : _hotValue_T_19; // @[Mux.scala 47:70]
  assign io_out = io_in[22] ? 5'h17 : _hotValue_T_20; // @[Mux.scala 47:70]
endmodule

module FP_extract(
  input  [31:0] io_in_a,
  output [31:0] io_out_frac
);
  wire [22:0] leadingOne_io_in; // @[FloatingPointDesigns.scala 894:28]
  wire [4:0] leadingOne_io_out; // @[FloatingPointDesigns.scala 894:28]
  wire [7:0] exp = io_in_a[30:23]; // @[FloatingPointDesigns.scala 888:19]
  wire [22:0] mant = io_in_a[22:0]; // @[FloatingPointDesigns.scala 890:20]
  wire [7:0] subres = exp - 8'h7f; // @[FloatingPointDesigns.scala 898:21]
  wire [277:0] _GEN_1 = {{255'd0}, mant}; // @[FloatingPointDesigns.scala 901:27]
  wire [277:0] _firstshiftf_T = _GEN_1 << subres; // @[FloatingPointDesigns.scala 901:27]
  wire [4:0] _new_exp_T_1 = 5'h17 - leadingOne_io_out; // @[FloatingPointDesigns.scala 904:39]
  wire [4:0] _new_exp_T_3 = _new_exp_T_1 + 5'h1; // @[FloatingPointDesigns.scala 904:59]
  wire [6:0] _GEN_5 = {{2'd0}, _new_exp_T_3}; // @[FloatingPointDesigns.scala 904:25]
  wire [6:0] _new_exp_T_5 = 7'h7f - _GEN_5; // @[FloatingPointDesigns.scala 904:25]
  wire [22:0] firstshiftf = _firstshiftf_T[22:0]; // @[FloatingPointDesigns.scala 900:29 901:19]
  wire [53:0] _GEN_2 = {{31'd0}, firstshiftf}; // @[FloatingPointDesigns.scala 906:31]
  wire [53:0] _new_mant_T_4 = _GEN_2 << _new_exp_T_3; // @[FloatingPointDesigns.scala 906:31]
  wire [7:0] new_exp = {{1'd0}, _new_exp_T_5}; // @[FloatingPointDesigns.scala 903:25 904:15]
  wire [22:0] new_mant = _new_mant_T_4[22:0]; // @[FloatingPointDesigns.scala 905:26 906:16]
  wire [31:0] _result_frac_T_2 = {io_in_a[31],new_exp,new_mant}; // @[FloatingPointDesigns.scala 907:47]
  wire [7:0] _GEN_6 = {{3'd0}, _new_exp_T_3}; // @[FloatingPointDesigns.scala 913:22]
  wire [7:0] new_exp_1 = exp - _GEN_6; // @[FloatingPointDesigns.scala 913:22]
  wire [53:0] _GEN_3 = {{31'd0}, mant}; // @[FloatingPointDesigns.scala 915:24]
  wire [53:0] _new_mant_T_9 = _GEN_3 << _new_exp_T_3; // @[FloatingPointDesigns.scala 915:24]
  wire [22:0] new_mant_1 = _new_mant_T_9[22:0]; // @[FloatingPointDesigns.scala 914:26 915:16]
  wire [31:0] _result_frac_T_5 = {io_in_a[31],new_exp_1,new_mant_1}; // @[FloatingPointDesigns.scala 916:47]
  wire [31:0] _GEN_0 = exp < 8'h7f ? io_in_a : _result_frac_T_5; // @[FloatingPointDesigns.scala 908:29 909:19 916:19]
  leadingOneDetector leadingOne ( // @[FloatingPointDesigns.scala 894:28]
    .io_in(leadingOne_io_in),
    .io_out(leadingOne_io_out)
  );
  assign io_out_frac = exp > 8'h7f ? _result_frac_T_2 : _GEN_0; // @[FloatingPointDesigns.scala 896:24 907:19]
  assign leadingOne_io_in = exp > 8'h7f ? firstshiftf : mant; // @[FloatingPointDesigns.scala 895:22 896:24 902:24]
endmodule
