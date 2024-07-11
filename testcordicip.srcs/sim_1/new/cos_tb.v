`timescale 1ns / 1ps

module example_sim();
	reg [31:0] clockcount_;
    reg clock_;
    always #5 clock_ = ~clock_;
    reg reset_;
    always #10 clockcount_ = clockcount_ + 1;

    reg valid_;
    wire outvalid_;
    wire [31:0] cosout_, sinout_;
    reg [31:0] x0_, y0_, z0_;

	parameter TEST_SIZE = 65;
	reg [31:0] testinputs_ [TEST_SIZE - 1 : 0];

/*

module cos(
	input clock,
	input reset,
	input [31:0] z0,
	input valid,
	output reg [31:0] out_x,
	output reg [31:0] out_y,
	output outvalid
    );
    */
    
wire [31:0] outx_, outy_;
cos cosdut(
    .clock(clock_),
    .reset(reset_),
    .z0(z0_),
    .valid(valid_),
    .out_x(cosout_),
    .out_y(sinout_),
    .outvalid(outvalid_));

integer idx_;
integer cyclecount_;

integer delay_;
shortreal testfloat_;
shortreal testin_;

shortreal actualsin_;
shortreal expectedsin_;
shortreal errorsin_;

shortreal actualcos_;
shortreal expectedcos_;
shortreal errorcos_;


function real abs;
	input real val;
	begin
		abs = $sqrt($pow(val, 2.0));
	end
endfunction


     wire [31:0] TWO_PI;
     
    assign TWO_PI = 32'h40c90fdb;
     
     wire a_ready, b_ready;
     reg a_valid, b_valid;
     
     wire [31:0] div_out;
     reg [31:0] div_out_reg;
     wire div_ready, div_valid;
     
     
    divider div(
        .aclk(clock_),
        .s_axis_a_tdata(z0_),
        .s_axis_a_tvalid(a_valid),
        .s_axis_b_tdata(TWO_PI),
        .s_axis_b_tvalid(b_valid),
        .m_axis_result_tdata(div_out),
        .m_axis_result_tvalid(div_valid));

initial begin
    
    valid_ = 0;
	delay_ = 89;
	a_valid <= 1;
    b_valid <= 1;
	clockcount_ = 32'd0;
    clock_ = 1'b1;
    reset_ = 1'b1;
	#10;
    #10;
    valid_ = 1;
    reset_ = 1'b0;
    #10;

    /* Though they look like common angles in degrees, the angles in 
		the comments are in fact radians, NOT degrees. They are large to
		test floating point modulus by 2*PI.
    */
	testinputs_[0] = 32'hc27b53d2; //cos(-62.831856)=1.000000, sin(-62.831856)=-0.000003
	testinputs_[1] = 32'hc2737933; //cos(-60.868359)=-0.382683, sin(-60.868359)=0.923880
	testinputs_[2] = 32'hc26b9e94; //cos(-58.904861)=-0.707106, sin(-58.904861)=-0.707107
	testinputs_[3] = 32'hc263c3f6; //cos(-56.941368)=0.923879, sin(-56.941368)=-0.382685
	testinputs_[4] = 32'hc25be958; //cos(-54.977875)=0.000003, sin(-54.977875)=1.000000
	testinputs_[5] = 32'hc2540eb9; //cos(-53.014378)=-0.923880, sin(-53.014378)=-0.382682
	testinputs_[6] = 32'hc24c341a; //cos(-51.050880)=0.707107, sin(-51.050880)=-0.707107
	testinputs_[7] = 32'hc244597c; //cos(-49.087387)=0.382685, sin(-49.087387)=0.923879
	testinputs_[8] = 32'hc23c7edd; //cos(-47.123890)=-1.000000, sin(-47.123890)=0.000000
	testinputs_[9] = 32'hc234a440; //cos(-45.160400)=0.382678, sin(-45.160400)=-0.923882
	testinputs_[10] = 32'hc22cc9a0; //cos(-43.196899)=0.707107, sin(-43.196899)=0.707106
	testinputs_[11] = 32'hc224ef02; //cos(-41.233406)=-0.923879, sin(-41.233406)=0.382686
	testinputs_[12] = 32'hc21d1463; //cos(-39.269909)=-0.000001, sin(-39.269909)=-1.000000
	testinputs_[13] = 32'hc21539c4; //cos(-37.306412)=0.923879, sin(-37.306412)=0.382684
	testinputs_[14] = 32'hc20d5f26; //cos(-35.342918)=-0.707106, sin(-35.342918)=0.707108
	testinputs_[15] = 32'hc2058488; //cos(-33.379425)=-0.382686, sin(-33.379425)=-0.923878
	testinputs_[16] = 32'hc1fb53d2; //cos(-31.415928)=1.000000, sin(-31.415928)=-0.000001
	testinputs_[17] = 32'hc1eb9e94; //cos(-29.452431)=-0.382684, sin(-29.452431)=0.923879
	testinputs_[18] = 32'hc1dbe958; //cos(-27.488937)=-0.707108, sin(-27.488937)=-0.707106
	testinputs_[19] = 32'hc1cc341a; //cos(-25.525440)=0.923880, sin(-25.525440)=-0.382683
	testinputs_[20] = 32'hc1bc7edd; //cos(-23.561945)=0.000000, sin(-23.561945)=1.000000
	testinputs_[21] = 32'hc1acc9a0; //cos(-21.598450)=-0.923880, sin(-21.598450)=-0.382683
	testinputs_[22] = 32'hc19d1462; //cos(-19.634953)=0.707108, sin(-19.634953)=-0.707106
	testinputs_[23] = 32'hc18d5f27; //cos(-17.671461)=0.382686, sin(-17.671461)=0.923879
	testinputs_[24] = 32'hc17b53d3; //cos(-15.707965)=-1.000000, sin(-15.707965)=0.000002
	testinputs_[25] = 32'hc15be958; //cos(-13.744469)=0.382683, sin(-13.744469)=-0.923880
	testinputs_[26] = 32'hc13c7edd; //cos(-11.780972)=0.707107, sin(-11.780972)=0.707107
	testinputs_[27] = 32'hc11d1462; //cos(-9.817476)=-0.923880, sin(-9.817476)=0.382683
	testinputs_[28] = 32'hc0fb53ce; //cos(-7.853980)=0.000002, sin(-7.853980)=-1.000000
	testinputs_[29] = 32'hc0bc7ee2; //cos(-5.890489)=0.923880, sin(-5.890489)=0.382681
	testinputs_[30] = 32'hc07b53d8; //cos(-3.926992)=-0.707106, sin(-3.926992)=0.707108
	testinputs_[31] = 32'hbffb53d8; //cos(-1.963496)=-0.382684, sin(-1.963496)=-0.923879
	testinputs_[32] = 32'h00000000; //cos(0.000000)=1.000000, sin(0.000000)=0.000000
	testinputs_[33] = 32'h3ffb53d8; //cos(1.963496)=-0.382684, sin(1.963496)=0.923879
	testinputs_[34] = 32'h407b53d8; //cos(3.926992)=-0.707106, sin(3.926992)=-0.707108
	testinputs_[35] = 32'h40bc7ee2; //cos(5.890489)=0.923880, sin(5.890489)=-0.382681
	testinputs_[36] = 32'h40fb53ce; //cos(7.853980)=0.000002, sin(7.853980)=1.000000
	testinputs_[37] = 32'h411d1462; //cos(9.817476)=-0.923880, sin(9.817476)=-0.382683
	testinputs_[38] = 32'h413c7edd; //cos(11.780972)=0.707107, sin(11.780972)=-0.707107
	testinputs_[39] = 32'h415be958; //cos(13.744469)=0.382683, sin(13.744469)=0.923880
	testinputs_[40] = 32'h417b53d3; //cos(15.707965)=-1.000000, sin(15.707965)=-0.000002
	testinputs_[41] = 32'h418d5f24; //cos(17.671455)=0.382680, sin(17.671455)=-0.923881
	testinputs_[42] = 32'h419d1464; //cos(19.634956)=0.707105, sin(19.634956)=0.707108
	testinputs_[43] = 32'h41acc9a0; //cos(21.598450)=-0.923880, sin(21.598450)=0.382683
	testinputs_[44] = 32'h41bc7ee0; //cos(23.561951)=0.000006, sin(23.561951)=-1.000000
	testinputs_[45] = 32'h41cc341a; //cos(25.525440)=0.923880, sin(25.525440)=0.382683
	testinputs_[46] = 32'h41dbe956; //cos(27.488934)=-0.707105, sin(27.488934)=0.707108
	testinputs_[47] = 32'h41eb9e96; //cos(29.452435)=-0.382680, sin(29.452435)=-0.923881
	testinputs_[48] = 32'h41fb53d0; //cos(31.415924)=1.000000, sin(31.415924)=-0.000002
	testinputs_[49] = 32'h42058488; //cos(33.379425)=-0.382686, sin(33.379425)=0.923878
	testinputs_[50] = 32'h420d5f26; //cos(35.342918)=-0.707106, sin(35.342918)=-0.707108
	testinputs_[51] = 32'h421539c6; //cos(37.306419)=0.923882, sin(37.306419)=-0.382677
	testinputs_[52] = 32'h421d1463; //cos(39.269909)=-0.000001, sin(39.269909)=1.000000
	testinputs_[53] = 32'h4224ef01; //cos(41.233402)=-0.923880, sin(41.233402)=-0.382682
	testinputs_[54] = 32'h422cc9a1; //cos(43.196903)=0.707110, sin(43.196903)=-0.707104
	testinputs_[55] = 32'h4234a43e; //cos(45.160393)=0.382685, sin(45.160393)=0.923879
	testinputs_[56] = 32'h423c7ede; //cos(47.123894)=-1.000000, sin(47.123894)=-0.000004
	testinputs_[57] = 32'h4244597c; //cos(49.087387)=0.382685, sin(49.087387)=-0.923879
	testinputs_[58] = 32'h424c3419; //cos(51.050877)=0.707110, sin(51.050877)=0.707104
	testinputs_[59] = 32'h42540eb9; //cos(53.014378)=-0.923880, sin(53.014378)=0.382682
	testinputs_[60] = 32'h425be957; //cos(54.977871)=-0.000000, sin(54.977871)=-1.000000
	testinputs_[61] = 32'h4263c3f7; //cos(56.941372)=0.923878, sin(56.941372)=0.382688
	testinputs_[62] = 32'h426b9e94; //cos(58.904861)=-0.707106, sin(58.904861)=0.707107
	testinputs_[63] = 32'h42737934; //cos(60.868362)=-0.382679, sin(60.868362)=-0.923881
	testinputs_[64] = 32'h427b53d2; //cos(62.831856)=1.000000, sin(62.831856)=0.000003

	#10;
	
	for(idx_ = 0; idx_ < 600; idx_ = idx_ + 1) begin

		if(idx_ < TEST_SIZE) begin
			testfloat_ = $bitstoshortreal(testinputs_[idx_]);
			z0_ <= testinputs_[idx_];
		end
		
		if(idx_ >= delay_) begin
			actualsin_ = $bitstoshortreal(sinout_);
			actualcos_ = $bitstoshortreal(cosout_);
			testin_ = $bitstoshortreal(testinputs_[idx_ - delay_]);
			expectedsin_ = $sin(testin_);
			expectedcos_ = $cos(testin_);
			errorsin_ = expectedsin_ != 0.0 ? abs((actualsin_ - expectedsin_)/expectedsin_)*100.0 : abs(actualsin_ * 100.0);
			errorcos_ = expectedcos_ != 0.0 ? abs((actualcos_ - expectedcos_)/expectedcos_)*100.0 : abs(actualcos_ * 100.0);
			/* $display("test input (rad): %.8f test sin: %.8f expected sin: %.8f sin Percent Err: %.8f%%", 
				testin_,
				actualsin_,
				expectedsin_,
				errorsin_
				); */
			$display("test input (rad): %.8f test cos: %.8f expected cos: %.8f cos Percent Err: %.8f%%", 
				testin_,
				actualcos_,
				expectedcos_,
				errorcos_
				);				
		end
		#10;
	end
    
end
    
endmodule

