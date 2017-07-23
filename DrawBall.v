module DrawBall(CLOCK_50,
		// Your inputs and outputs here
        KEY,
        SW,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	wire resetn;
	assign resetn = KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
    
    // Instansiate datapath
	// datapath d0(...);

    // Instansiate FSM control
    // control c0(...);
	 assign inx = 8'b00000000;
	 assign iny = 7'b0000000;
	 control c0(
	 .clk(CLOCK_50),
	 .inx(inx),
	 .iny(iny),
	 .WriteEn(1'b0),
	 .reset(KEY[0]),
	 .x(x),
	 .y(y),
	 .color(colour),
	 .plot(WriteEn)
	 );
	 
    
endmodule

module control(
    input clk,
    input inx, iny,
    input WriteEn,
	 input reset,
	 output reg [7:0] x,
	 output reg [6:0] y,
	 output reg [2:0] color,
    output plot
    );


    reg [3:0] current_state, next_state; 
    
    localparam  draw1_0 = 4'd0,
                draw2_0 = 4'd1,
                draw0_1 = 4'd2,
                draw1_1 = 4'd3,
                draw2_1 = 4'd4,
                draw3_1 = 4'd5,
                draw0_2 = 4'd6,
                draw1_2 = 4'd7,
                draw2_2 = 4'd8,
                draw3_2 = 4'd9,
                draw1_3 = 4'd10,
				draw2_3 = 4'd11,
				drawnone = 4'd12;
    
    // Next state logic aka our state table
    always@(*)
    begin: state_table 
            case (current_state)
					 draw1_0: next_state = draw2_0;
                draw2_0: next_state = draw0_1;
					 draw0_1: next_state = draw1_1;
					 draw1_1: next_state = draw2_1;
					 draw2_1: next_state = draw3_1;
					 draw3_1: next_state = draw0_2;
					 draw0_2: next_state = draw1_2;
					 draw1_2: next_state = draw2_2;
					 draw2_2: next_state = draw3_2;
					 draw3_2: next_state = draw1_3;
					 draw1_3: next_state = draw2_3;
					 draw2_3: next_state = draw1_0;
					 drawnone: next_state = WriteEn ? drawnone : draw1_0;
            default:     next_state = drawnone;
        endcase
    end // state_table
   
    // Output logic aka all of our datapath control signals
    always @(*)
    begin: set_pixel_location
		  color = 3'b000;
		  x = inx;
		  y = iny;
        case (current_state)
            draw1_0: begin
					 color = 3'b111;
					 x = x + 1'b1;
                end
            draw2_0: begin
                color = 3'b111;
					 x = x + 1'b1;
                end
            draw0_1: begin
                color = 3'b111;
					 x = x - 2'b10;
					 y = y + 1'b1;
                end
            draw1_1: begin
                color = 3'b111;
					 x = x + 1'b1;
                end
            draw2_1: begin
					 color = 3'b111;
					 x = x + 1'b1;
					 end
            draw3_1: begin
					 color = 3'b111;
					 x = x + 1'b1;
					 end
				draw0_2: begin
					 color = 3'b111;
					 x = x - 2'b11;
					 y = y + 1'b1;
					 end
				draw1_2: begin
					 color = 3'b111;
					 x = x + 1'b1;
					 end
				draw2_2: begin
					 color = 3'b111;
					 x = x + 1'b1;
					 end
				draw3_2: begin
					 color = 3'b111;
					 x = x + 1'b1;
			 		 end
				draw1_3: begin
					 color = 3'b111;
					 x = x - 2'b10;
					 y = y + 1'b1;
					 end
				draw2_3: begin
					 color = 3'b111;
					 x = x + 1'b1;
					 end
				drawnone: begin
					 color = 3'b000;
					 end
			   default: begin
				x = inx;
				y = iny;
				color = 3'b000;
				end
        endcase
    end // enable_signals
   
    // current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(!reset)
            current_state <= drawnone;
        else
            current_state <= next_state;
    end // state_FFS
endmodule


module hex_decoder(hex_digit, segments);// I'm just here... for no reason... maybe in the future I'll be used
    input [3:0] hex_digit;
    output reg [6:0] segments;
   
    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b000_1110;   
            default: segments = 7'h7f;
        endcase
endmodule
