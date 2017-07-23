// Part 2 skeleton

module BouncyBall
	(
		CLOCK_50,						//	On Board 50 MHz
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
		.VGA_CLK(VGA_CLK)
	);
	
	defparam VGA.RESOLUTION = "160x120";
	defparam VGA.MONOCHROME = "FALSE";
	defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
	defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
    
    // lots of wires to connect our datapath and control
    wire move_objects, bounce_ball, reset_ball, left_key, right_key; 
	wire [7:0] ball_x, ball_y, paddle_x;
	
	// Controller keys
	assign left_key = KEY[3];
	assign right_key = KEY[0];

    // Instantiate datapath
    datapath D0(
        .clk(clk),
        .resetn(resetn),

        .draw_screen(draw_screen), 
        .move_objects(move_objects), 
        .bounce_ball(bounce_ball),
        .reset_ball(reset_ball),

        .left_key(left_key),
        .right_key(right_key),
		
		.ball_x(ball_x),
		.ball_y(ball_y),
		.paddle_x(paddle_x),
		
		.writeEn(writeEn),
        .draw_x(x),
        .draw_y(y)
        .colour(colour),
    );

    // Instantiate FSM control
    control C0(
        .clk(clk),
        .resetn(resetn),
        
        .go(go),
        
		.ball_x(ball_x),
		.ball_y(ball_y),
		.paddle_x(paddle_x),
		
        .draw_screen(draw_screen), 
        .move_objects(move_objects), 
        .bounce_ball(bounce_ball),
        .reset_ball(reset_ball),
    );

    
endmodule


module control(
    input clk,
    input resetn,
    input go,
	
	input [7:0] ball_x, ball_y, paddle_x,

    output reg draw_screen, move_objects, bounce_ball, reset_ball,
	output reg [9:0] counter_1, counter_2
    );

    reg [4:0] current_state, next_state;
	reg incCounter_1, incCounter_2, reset_counter_1, reset_counter_2;
	
	localparam	SCREEN_WIDTH			= 8'd160,
				SCREEN_HEIGHT			= 8'd120;
    
    localparam  S_INITIALIZE  			= 4'd0,
				S_START_DRAW			= 4'd1,
				S_DRAW_ROW      		= 4'd2,
				S_DRAW_NEXT_ROW  		= 4'd3,
                S_WAIT   				= 4'd4,
                S_MOVE   				= 4'd5,
                S_BOUNCE   				= 4'd6;
    
    // Next state logic aka our state table
    always@(*)
    begin: state_FFs 
        if (current_state == S_INITIALIZE)
            next_state = S_START_DRAW;
        if (current_state == S_START_DRAW)
            next_state = S_DRAW_ROW;			
        else if(current_state == S_DRAW_ROW && counter_1 <= SCREEN_WIDTH)
            next_state = S_DRAW_ROW;
        else if(current_state == S_DRAW_ROW && counter_1 > SCREEN_WIDTH)
            next_state = S_DRAW_NEXT_ROW;
        else if(current_state == S_DRAW_NEXT_ROW && counter_2 <= SCREEN_HEIGHT)
            next_state = S_DRAW_ROW;
        else if(current_state == S_DRAW_NEXT_ROW && counter_2 > SCREEN_HEIGHT)
            next_state = S_WAIT;
        else if(current_state == S_WAIT)
            next_state = go ? S_WAIT : S_MOVE; // Loop in current state until go signal goes low
        else if(current_state == S_MOVE)
            next_state = S_MOVE;
        else if(current_state == S_BOUNCE)
            next_state = S_MOVE;
        else
            next_state = S_INITIALIZE;
    end // state_FFs
   

    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
        // By default make all our signals 0
		draw_screen = 1'b0;
        move_objects = 1'b0;
		bounce_ball = 1'b0;
		reset_ball = 1'b0;
		reset_counter_1 = 1'b0;
		reset_counter_2 = 1'b0;
		incCounter_1 = 1'b0;
		incCounter_2 = 1'b0;

        case (current_state)
            S_INITIALIZE: begin
                end
            S_START_DRAW: begin
				reset_counter_1 = 1'b1;
				reset_counter_2 = 1'b1;
                end
            S_DRAW_ROW: begin
				draw_screen = 1'b1;
				incCounter_1 = 1'b1;
                end
            S_DRAW_NEXT_ROW: begin
				incCounter_2 = 1'b1;
                end
            S_MOVE: begin
                move_objects = 1'b1;
                end
            S_BOUNCE: begin				// Set Dividend in Quotient register (Q <= Dividend + 0)
				bounce_ball = 1'b1;
                end
        // default:    // don't need default since we already made sure all of our outputs were assigned a value at the start of the always block
        endcase
    end // enable_signals
   
    // current_state registers
    always@(posedge clk)
    begin: state_FFs2
        if(resetn)
            current_state <= S_LOAD;
        else
            current_state <= next_state;
    end // state_FFS2
	
    // handle counter 1
    always@(posedge clk)
    begin: counter_1_FFs
        if(resetn || reset_counter_1)
            counter_1 <= 9'b0;
        else if(incCounter_1)
            counter_1 <= counter_1 + 1'b1;
    end
	
    // handle counter 2
    always@(posedge clk)
    begin: counter_2_FFs
        if(resetn || reset_counter_2)
            counter_2 <= 9'b0;
        else if(incCounter_1)
            counter_2 <= counter_2 + 1'b1;
    end
endmodule

module datapath(
    input clk,
    input resetn,
    input draw_screen, move_objects, bounce_ball, reset_ball,

    input left_key, right_key,
	
	output reg [7:0] ball_x, ball_y, paddle_x,
    output reg writeEn, draw_x, draw_y,
	output reg [2:0] colour
    );
    
    // Ball movement/bounce logic
    always @ (posedge clk) begin
        if (resetn || reset_ball) begin
            ball_x <= 8'd0; 
            ball_y <= 8'd0;
        end
        else if (move_objects
            if (ld_values)
				begin
					divisor <= data_in[3:0];
					dividend <= data_in[7:4];
				end
            if (ld_q)
                quotient <= alu_out[3:0];
            if (ld_r)
                remainder <= alu_out[3:0];
            if (reset_a)
                reg_A <= 5'd0;
            else if (ld_A)
                reg_A <= alu_out[4:0];
        end
    end
	
    // Paddle movement logic
    always @ (posedge clk) begin
        if (resetn) begin
            paddle_x <= 8'd0; 
        end
        else if (move_objects
            if (ld_values)
				begin
					divisor <= data_in[3:0];
					dividend <= data_in[7:4];
				end
            if (ld_q)
                quotient <= alu_out[3:0];
            if (ld_r)
                remainder <= alu_out[3:0];
            if (reset_a)
                reg_A <= 5'd0;
            else if (ld_A)
                reg_A <= alu_out[4:0];
        end
    end
    
endmodule

module hex_decoder(hex_digit, segments);
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