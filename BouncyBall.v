module BouncyBall
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		HEX0,
		HEX1,
		HEX2,
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
	input   [6:0]   HEX0;
	input   [6:0]   HEX1;
	input   [6:0]   HEX2;

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
	assign resetn = SW[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	// vga_adapter VGA(
		// .resetn(resetn),
		// .clock(CLOCK_50),
		// .colour(colour),
		// .x(x),
		// .y(y),
		// .plot(writeEn),
		// /* Signals for the DAC to drive the monitor. */
		// .VGA_R(VGA_R),
		// .VGA_G(VGA_G),
		// .VGA_B(VGA_B),
		// .VGA_HS(VGA_HS),
		// .VGA_VS(VGA_VS),
		// .VGA_BLANK(VGA_BLANK_N),
		// .VGA_SYNC(VGA_SYNC_N),
		// .VGA_CLK(VGA_CLK)
	// );
	
	// defparam VGA.RESOLUTION = "160x120";
	// defparam VGA.MONOCHROME = "FALSE";
	// defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
	// defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
    
    // lots of wires to connect our datapath and control
    wire draw_background, draw_ball, draw_paddle, check_ball_touching, move_objects, bounce_ball, reset_ball, reset_paddle, left_key, right_key, go_key, game_over; 
	wire ball_touching_wall, ball_touching_paddle, ball_hitting_floor;
	wire [7:0] ball_x, paddle_x;
	wire [6:0] ball_y;
	wire [24:0] counter_1, counter_2;
	wire [5:0] counter_4;
	wire [10:0] score;
	wire [11:0] decimal_score;
	
	// Controller keys
	assign left_key = !KEY[3];
	assign right_key = !KEY[0];
	assign go_key = !KEY[1];

    // Instantiate datapath
    datapath D0(
        .clk(CLOCK_50),
        .resetn(resetn),

        .draw_background(draw_background), 
        .draw_ball(draw_ball), 
        .draw_paddle(draw_paddle), 
		.check_ball_touching(check_ball_touching),
        .move_ball(move_ball), 
		.move_paddle(move_paddle),
        .bounce_ball(bounce_ball),
        .reset_ball(reset_ball),
		.reset_paddle(reset_paddle),
		
        .counter_1(counter_1),
        .counter_2(counter_2),
		.counter_4(counter_4),
		.game_over(game_over),

        .left_key(left_key),
        .right_key(right_key),
		
		.ball_x(ball_x),
		.ball_y(ball_y),
		.paddle_x(paddle_x),
		.ball_touching_wall(ball_touching_wall),
		.ball_hitting_floor(ball_hitting_floor),
		.ball_touching_paddle(ball_touching_paddle),
		
		.writeEn(writeEn),
        .draw_x(x),
        .draw_y(y),
        .colour(colour)
    );

    // Instantiate FSM control
    control C0(
        .clk(CLOCK_50),
        .resetn(resetn),
        
        .go(go_key),
        
		.ball_x(ball_x),
		.ball_y(ball_y),
		.paddle_x(paddle_x),
		.ball_touching_wall(ball_touching_wall),
		.ball_hitting_floor(ball_hitting_floor),
		.ball_touching_paddle(ball_touching_paddle),
		
        .draw_background(draw_background), 
        .draw_ball(draw_ball), 
        .draw_paddle(draw_paddle), 
		.check_ball_touching(check_ball_touching),
        .move_ball(move_ball), 
		  .move_paddle(move_paddle),
        .bounce_ball(bounce_ball),
        .reset_ball(reset_ball),
		.reset_paddle(reset_paddle),
		
        .counter_1(counter_1),
        .counter_2(counter_2),
		.counter_4(counter_4),
		.score(score),
		.game_over(game_over)
    );

    // Display score
	binary_to_decimal bd0(score, decimal_score);
	hex_decoder H0 (decimal_score[3:0], HEX0);
	hex_decoder H1 (decimal_score[7:4], HEX1);
	hex_decoder H2 (decimal_score[11:8], HEX2);
endmodule


module control(
    input clk,
    input resetn,
    input go,
	
	input [7:0] ball_x, 
	input [6:0] ball_y,
	input [7:0] paddle_x,
	input ball_touching_wall, ball_hitting_floor, ball_touching_paddle,

    output reg draw_background, draw_ball, draw_paddle, check_ball_touching, move_ball, move_paddle, bounce_ball, reset_ball, reset_paddle,
	output reg [24:0] counter_1, counter_2,
	output reg [5:0] counter_4,
	output reg [10:0] score,
	output reg game_over
    );

    reg [4:0] current_state, next_state;
	reg incCounter_1, incCounter_2, incCounter_3, reset_counter_1, reset_counter_2, reset_counter_3, wait_for_start, check_for_start, start_game, reset_score, inc_score;
	reg inc_level, begin_game, set_game_over;
	reg [10:0] counter_3;
	reg [23:0] wait_cycles;
	
	localparam	//SCREEN_WIDTH			= 8'd8,				// For ModelSim Testing purposes
				//SCREEN_HEIGHT			= 7'd4,
				SCREEN_WIDTH			= 8'd160,
				SCREEN_HEIGHT			= 8'd120,
				NUM_OF_BALL_PIXELS		= 4'd12,
				//PADDLE_WIDTH			= 5'd4,		// For ModelSim Testing purposes
				PADDLE_WIDTH			= 5'd18,
				PADDLE_HEIGHT			= 2'd2,
				//STARTING_WAIT_CYCLES	= 5'b5;		// For ModelSim Testing purposes
				STARTING_WAIT_CYCLES	= 24'd1562500;		// ~32 cycles per second
    
    localparam  S_INITIALIZE  						= 5'd0,
				S_START_WAIT_0 						= 5'd1,
				S_WAIT_0   							= 5'd2,
				S_START_DRAW_BACKGROUND				= 5'd3,
				S_DRAW_BACKGROUND_ROW				= 5'd4,
				S_DRAW_BACKGROUND_NEXT_ROW			= 5'd5,
				S_START_DRAW_BALL			   		= 5'd6,
				S_DRAW_BALL	  						= 5'd7,
				S_START_DRAW_PADDLE					= 5'd8,
				S_DRAW_PADDLE_ROW					= 5'd9,
				S_DRAW_PADDLE_NEXT_ROW				= 5'd10,
				S_START_WAIT_1 						= 5'd11,
				S_WAIT_1   							= 5'd12,
				S_CHECK_BALL_TOUCHING_1				= 5'd13,
				S_CHECK_BALL_TOUCHING_2				= 5'd14,
        		S_BOUNCE_BALL						= 5'd15,
        		S_INCREMENT_SCORE					= 5'd16,
				S_MOVE_BALL							= 5'd17,
				S_MOVE_PADDLE						= 5'd18,
				S_GAME_OVER                     	= 5'd19,
				S_START_WAIT_2 						= 5'd20,
				S_WAIT_2  							= 5'd21;
    
    // Next state logic aka our state table
	// Current model: Intialize -> Draw Screen -> Wait -> Move Objects -> Draw Screen - > Wait -> etc.
    always@(*)
    begin: state_FFs 
        if (current_state == S_INITIALIZE)
            next_state <= S_START_DRAW_BACKGROUND;
		else if (current_state == S_WAIT_0 && !start_game)
            next_state <= S_WAIT_0;
		else if (current_state == S_WAIT_0 && start_game)
            next_state <= S_START_WAIT_1;
        else if (current_state == S_START_DRAW_BACKGROUND)
            next_state <= S_DRAW_BACKGROUND_ROW;			
        else if(current_state == S_DRAW_BACKGROUND_ROW && counter_1 < SCREEN_WIDTH - 1)
            next_state <= S_DRAW_BACKGROUND_ROW;
        else if(current_state == S_DRAW_BACKGROUND_ROW && counter_1 >= SCREEN_WIDTH - 1)
            next_state <= S_DRAW_BACKGROUND_NEXT_ROW;
        else if(current_state == S_DRAW_BACKGROUND_NEXT_ROW && counter_2 < SCREEN_HEIGHT - 1)
            next_state <= S_DRAW_BACKGROUND_ROW;
        else if(current_state == S_DRAW_BACKGROUND_NEXT_ROW && counter_2 >= SCREEN_HEIGHT - 1)
            next_state <= S_START_DRAW_BALL;
        else if (current_state == S_START_DRAW_BALL)
            next_state <= S_DRAW_BALL;		          
        else if(current_state == S_DRAW_BALL && counter_1 < NUM_OF_BALL_PIXELS - 1)
            next_state <= S_DRAW_BALL;		
        else if(current_state == S_DRAW_BALL && counter_1 >= NUM_OF_BALL_PIXELS - 1)
            next_state <= S_START_DRAW_PADDLE;
        else if (current_state == S_START_DRAW_PADDLE)
            next_state <= S_DRAW_PADDLE_ROW;		
        else if(current_state == S_DRAW_PADDLE_ROW && counter_1 < PADDLE_WIDTH - 1)
            next_state <= S_DRAW_PADDLE_ROW;		
        else if(current_state == S_DRAW_PADDLE_ROW && counter_1 >= PADDLE_WIDTH - 1)
            next_state <= S_DRAW_PADDLE_NEXT_ROW;
        else if(current_state == S_DRAW_PADDLE_NEXT_ROW && counter_2 < PADDLE_HEIGHT - 1)
            next_state <= S_DRAW_PADDLE_ROW;
        else if(current_state == S_DRAW_PADDLE_NEXT_ROW && counter_2 >= PADDLE_HEIGHT - 1) begin
			if (game_over)
				next_state <= S_START_WAIT_2;
			else if (start_game)
				next_state <= S_START_WAIT_1;
			else
				next_state <= S_WAIT_0;
		end
        else if (current_state == S_START_WAIT_1)
            next_state <= S_WAIT_1;
        else if(current_state == S_WAIT_1 && counter_1 < wait_cycles - 1)
            next_state <= S_WAIT_1;
        else if(current_state == S_WAIT_1 && counter_1 >= wait_cycles - 1)
            next_state <= S_MOVE_PADDLE;
        else if(current_state == S_MOVE_PADDLE && !counter_3[0])
            next_state <= S_CHECK_BALL_TOUCHING_1;
        else if(current_state == S_MOVE_PADDLE && counter_3[0])
            next_state <= S_START_DRAW_BACKGROUND;
        else if (current_state == S_CHECK_BALL_TOUCHING_1)
            next_state <= S_CHECK_BALL_TOUCHING_2;
		else if (current_state == S_CHECK_BALL_TOUCHING_2 && ball_hitting_floor)
			next_state <= S_GAME_OVER;
		else if (current_state == S_CHECK_BALL_TOUCHING_2 && ball_touching_paddle)
			next_state <= S_INCREMENT_SCORE;
        else if(current_state == S_CHECK_BALL_TOUCHING_2 && ball_touching_wall)
            next_state <= S_BOUNCE_BALL;
        else if(current_state == S_CHECK_BALL_TOUCHING_2 && !ball_touching_wall)
            next_state <= S_MOVE_BALL;
        else if(current_state == S_INCREMENT_SCORE)
            next_state <= S_BOUNCE_BALL;
        else if(current_state == S_BOUNCE_BALL)
            next_state <= S_MOVE_BALL;
        else if(current_state == S_MOVE_BALL)
            next_state <= S_START_DRAW_BACKGROUND;
	    else if (current_state == S_GAME_OVER)
		    next_state <= S_START_DRAW_BACKGROUND;
        else if (current_state == S_START_WAIT_2)
            next_state <= S_WAIT_2;
		else if (current_state == S_WAIT_2 && !start_game)
            next_state <= S_WAIT_2;
		else if (current_state == S_WAIT_2 && start_game)
            next_state <= S_INITIALIZE;
        else
            next_state <= S_INITIALIZE;
    end // state_FFs
   

    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
        // By default make all our signals 0
		wait_for_start = 1'b0;
		check_for_start = 1'b0;
		draw_background = 1'b0;
		draw_ball = 1'b0;
		draw_paddle = 1'b0;
		check_ball_touching = 1'b0;
        move_ball = 1'b0;
        move_paddle = 1'b0;
		bounce_ball = 1'b0;
		reset_ball = 1'b0;
		reset_paddle = 1'b0;
		reset_counter_1 = 1'b0;
		reset_counter_2 = 1'b0;
		reset_counter_3 = 1'b0;
		incCounter_1 = 1'b0;
		incCounter_2 = 1'b0;
		incCounter_3 = 1'b0;
		reset_score = 1'b0;
		inc_score = 1'b0;
		inc_level = 1'b0;
		begin_game = 1'b0;
		set_game_over = 1'b0;

        case (current_state)
            S_INITIALIZE: begin
				wait_for_start = 1'b1; 
				reset_ball = 1'b1; 
				reset_paddle = 1'b1;
				reset_counter_1 = 1'b1;
				reset_counter_2 = 1'b1;
				reset_counter_3 = 1'b1;
				reset_score = 1'b1;
				begin_game = 1'b1;
            end
            S_WAIT_0: begin
				check_for_start = 1'b1;
            end
            S_START_DRAW_BACKGROUND: begin
				reset_counter_1 = 1'b1;
				reset_counter_2 = 1'b1;
            end
            S_DRAW_BACKGROUND_ROW: begin
				draw_background = 1'b1;
				incCounter_1 = 1'b1;
            end
            S_DRAW_BACKGROUND_NEXT_ROW: begin
				incCounter_2 = 1'b1;
				reset_counter_1 = 1'b1;
            end
            S_START_DRAW_BALL: begin
				reset_counter_1 = 1'b1;
            end
            S_DRAW_BALL: begin
				draw_ball = 1'b1;
				incCounter_1 = 1'b1;
            end
            S_START_DRAW_PADDLE: begin
				reset_counter_1 = 1'b1;
				reset_counter_2 = 1'b1;
            end
            S_DRAW_PADDLE_ROW: begin
				draw_paddle = 1'b1;
				incCounter_1 = 1'b1;
            end
            S_DRAW_PADDLE_NEXT_ROW: begin
				incCounter_2 = 1'b1;
				reset_counter_1 = 1'b1;
            end
            S_START_WAIT_1: begin
				reset_counter_1 = 1'b1;
            end
            S_WAIT_1: begin
				incCounter_1 = 1'b1;
            end
			S_CHECK_BALL_TOUCHING_1: begin
				check_ball_touching = 1'b1;
			end
			S_INCREMENT_SCORE: begin
				inc_score = 1'b1;
				inc_level = 1'b1;
			end
			S_BOUNCE_BALL: begin
				bounce_ball = 1'b1;
			end	
			S_MOVE_BALL: begin
				move_ball = 1'b1;
			end		
			S_MOVE_PADDLE: begin
				move_paddle = 1'b1;
				incCounter_3 = 1'b1;
			end		
			S_GAME_OVER: begin
				set_game_over = 1'b1;
			end
        // default:    // don't need default since we already made sure all of our outputs were assigned a value at the start of the always block
        endcase
    end // enable_signals
   
    // current_state registers
    always@(posedge clk)
    begin: state_FFs2
        if(!resetn)
            current_state <= S_INITIALIZE;
        else
            current_state <= next_state;
    end // state_FFS2
	
    // handle counter 1
    always@(posedge clk)
    begin: counter_1_FFs
        if(!resetn || reset_counter_1)
            counter_1 <= 24'b0;
        else if(incCounter_1)
            counter_1 <= counter_1 + 1'b1;
    end
	
    // handle counter 2
    always@(posedge clk)
    begin: counter_2_FFs
        if(!resetn || reset_counter_2)
            counter_2 <= 24'b0;
        else if(incCounter_2)
            counter_2 <= counter_2 + 1'b1;
    end
	
    // handle counter 3 - counts the number of cycles so far
    always@(posedge clk)
    begin: counter_3_FFs
        if(!resetn || reset_counter_3)
            counter_3 <= 10'b0;
        else if(incCounter_3)
            counter_3 <= counter_3 + 1'b1;
    end
	
    // handle counter 4 - counts the number of clock cycles, used to generate pseudo-random numbers
    always@(posedge clk)
    begin: counter_4_FFs
        if(!resetn)
            counter_4 <= 6'b0;
        else
            counter_4 <= counter_4 + 1'b1;
    end
	
    // handle score
    always@(posedge clk)
    begin: score_FFs
        if(!resetn || reset_score)
            score <= 10'b0;
        else if(inc_score)
            score <= score + 1'b1;
    end
	
    // handle starting
    always@(posedge clk)
    begin: start_FFs
        if(!resetn || wait_for_start)
            start_game <= 1'b0;
        else if(go && check_for_start)
            start_game <= 1'b1;
    end
	
    // handle game over
    always@(posedge clk)
    begin: game_over_FFs
        if(!resetn || begin_game)
            game_over <= 1'b0;
        else if(set_game_over)
            game_over <= 1'b1;
    end
	
    // handle wait cycles
    always@(posedge clk)
    begin: wait_cycles_FFs
        if(!resetn)
            wait_cycles <= STARTING_WAIT_CYCLES;
        else if(inc_level && score[2:0] == 3'b111)
            wait_cycles <= ((wait_cycles * 3) << 2);		// Multiplied by 3/4 every 8 bounces off the paddle
    end
endmodule

module datapath(
    input clk,
    input resetn,
    input draw_background, draw_ball, draw_paddle, check_ball_touching, move_ball, move_paddle, bounce_ball, reset_ball, reset_paddle,
	input [24:0] counter_1, counter_2,
	input [5:0] counter_4,
	input game_over,

    input left_key, right_key,
	
	output reg [7:0] ball_x, 
	output reg [6:0] ball_y, 
	output reg [7:0] paddle_x,
	output reg ball_touching_wall, ball_hitting_floor, ball_touching_paddle,
    output reg writeEn,
	output reg [7:0] draw_x,
	output reg [6:0] draw_y,
	output reg [2:0] colour
    );
	
	reg [1:0] ball_direction;			// 0 = 45°, 1 = 135°, 2 = 225°, 3 = 315°
	
	localparam	// SCREEN_WIDTH			= 8'd8,			// For ModelSim Testing purposes
				// SCREEN_HEIGHT			= 7'd4,
				SCREEN_WIDTH			= 8'd160,
				SCREEN_HEIGHT			= 8'd120,
				// BALL_START_X			= 8'd0,		// For ModelSim Testing purposes
				// BALL_START_Y			= 8'd0,
				// PADDLE_START_X			= 8'd0;
				PADDLE_WIDTH			= 5'd18,
				PADDLE_HEIGHT			= 2'd2,
				BALL_START_X			= 8'd78,
				BALL_START_Y			= 8'd58,
				PADDLE_START_X			= 8'd71;
				
	// Ball drawing parameters
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
				draw2_3 = 4'd11;
	
	// Drawing Background logic
    always @ (posedge clk) begin
		writeEn <= 0;
		draw_x <= 0;
		draw_y <= 0;
		colour <= 0;
        if (draw_background) begin
            writeEn <= 1'b1; 
            draw_x <= counter_1;
			draw_y <= counter_2;
			if (counter_2 == (SCREEN_HEIGHT - 1'b1))
				colour <= 3'b100;
			else if (counter_1 == 1'b0 || counter_1 == (SCREEN_WIDTH - 1'b1) || counter_2 == 1'b0)
				colour <= 3'b010;
			else
				colour <= 3'b000;
        end
        else if (draw_ball) begin
			writeEn <= 1'b1;
			if (game_over)
				colour <= 3'b100;
			else
				colour <= 3'b111;
			begin: set_pixel_location
				draw_x <= ball_x;
				draw_y <= ball_y;
				case (counter_1)
					draw1_0: begin
						draw_x <= ball_x + 1'b1;
					end
					draw2_0: begin
						draw_x <= ball_x + 2'b10;
					end
					draw0_1: begin
						draw_y <= ball_y + 1'b1;
					end
					draw1_1: begin
						draw_x <= ball_x + 1'b1;
						draw_y <= ball_y + 1'b1;
					end
					draw2_1: begin
						draw_x <= ball_x + 2'b10;
						draw_y <= ball_y + 1'b1;
					end
					draw3_1: begin
						draw_x <= ball_x + 2'b11;
						draw_y <= ball_y + 1'b1;
					end
					draw0_2: begin
						draw_x <= ball_x;
						draw_y <= ball_y + 2'b10;
					end
					draw1_2: begin
						draw_x <= ball_x + 1'b1;
						draw_y <= ball_y + 2'b10;
					end
					draw2_2: begin
						draw_x <= ball_x + 2'b10;
						draw_y <= ball_y + 2'b10;
					end
					draw3_2: begin
						draw_x <= ball_x + 2'b11;
						draw_y <= ball_y + 2'b10;
					end
					draw1_3: begin
						draw_x <= ball_x + 1'b1;
						draw_y <= ball_y + 2'b11;
					end
					draw2_3: begin
						draw_x <= ball_x + 2'b10;
						draw_y <= ball_y + 2'b11;
					end
				endcase
			end
		end
        else if (draw_paddle) begin
            writeEn <= 1'b1; 
            draw_x <= paddle_x + counter_1;
			draw_y <= SCREEN_HEIGHT - counter_2 - 2;  
			colour <= 3'b011;	                       
        end
    end
    
    // Ball movement/bounce logic
    always @ (posedge clk) begin
        if (!resetn || reset_ball) begin
            ball_x <= BALL_START_X; 
            ball_y <= BALL_START_Y;
			ball_direction <= counter_4[1:0];
        end
        else if (bounce_ball) begin
			if (ball_x <= 8'b1 && ball_y <= 7'b1) //if hit top left corner
				 ball_direction <= 2'b01;
			else if (ball_x >= SCREEN_WIDTH - 3'b101 && ball_y <= 7'b1) //if hit top right corner
				 ball_direction <= 2'b10;
			else if (ball_x <= 8'b1 && ball_y >= SCREEN_HEIGHT - 3'b111) //if hit bottom left corner
				 ball_direction <= 2'b00;
			else if (ball_x >= SCREEN_WIDTH - 3'b101 && ball_y >= SCREEN_HEIGHT - 3'b111) //if hit bottom right corner
				 ball_direction <= 2'b11;
		   else if (paddle_x >= 2'b11 && ball_x == paddle_x - 2'b11 && ball_y == SCREEN_HEIGHT - 7'b110 && ball_direction == 2'b01) //if ball hits paddle's left corner
				 ball_direction <= 2'b11;
			else if (ball_x == paddle_x + 5'd17 && ball_y == SCREEN_HEIGHT - 4'b110 && ball_direction == 2'b10) //if ball hits paddle's right corner
				 ball_direction <= 2'b00;
			else if (ball_x <= 8'b1)begin
				if (ball_direction == 2'b11)
					ball_direction <= 2'b00;
				else if (ball_direction == 2'b10)
					ball_direction <= 2'b01;
				end
			else if (ball_y <= 8'b1)begin
				if (ball_direction == 2'b00)
					ball_direction <= 2'b01;
				else if (ball_direction == 2'b11)
					ball_direction <= 2'b10;
				end
			else if (ball_x >= SCREEN_WIDTH - 3'b101)begin
				 if (ball_direction == 2'b01)
					 ball_direction <= 2'b10;
				 else if (ball_direction == 2'b00)
					 ball_direction <= 2'b11;
				 end
			else if (ball_y >= SCREEN_HEIGHT - 3'b111)begin
				if (ball_direction == 2'b10)
					ball_direction <= 2'b11;
				else if (ball_direction == 2'b01)
					ball_direction <= 2'b00;
			end
		end
        else if (move_ball) begin
			// Logic for moving the ball based on ball_direction
				if (ball_direction == 2'b00)begin
					 ball_x <= ball_x + 1'b1;
					 ball_y <= ball_y - 1'b1;
					 end
				else if (ball_direction == 2'b01)begin
					 ball_x <= ball_x + 1'b1;
					 ball_y <= ball_y + 1'b1;
					 end
				else if (ball_direction == 2'b10)begin
					 ball_x <= ball_x - 1'b1;
					 ball_y <= ball_y + 1'b1;
					 end
				else if (ball_direction == 2'b11)begin
					 ball_x <= ball_x - 1'b1;
					 ball_y <= ball_y - 1'b1;
					 end
				end
    end
	
    // Paddle movement logic
    always @ (posedge clk) begin
        if (!resetn || reset_paddle) begin
            paddle_x <= PADDLE_START_X; 
        end
        else if (move_paddle) begin
			// Logic for moving the ball based on left_key and right_key
			if (left_key == 1'b1 && paddle_x > 8'd1)
				paddle_x <= paddle_x - 1'b1;
			else if (right_key == 1'b1 && paddle_x < SCREEN_WIDTH - PADDLE_WIDTH - 2)
				paddle_x <= paddle_x + 1'b1;
        end
    end
	
    // Determining if the ball is touching the wall or paddle logic
    always @ (posedge clk) begin
        if (!resetn) begin
            ball_touching_wall <= 1'b0;
            ball_touching_paddle <= 1'b0;
        end
		else if (check_ball_touching) begin
			if (ball_y >= SCREEN_HEIGHT - 3'b111 && ball_direction == 2'b01) begin
				if (paddle_x <= 8'b10)begin
					if (paddle_x - ball_x <= 2'b10 && ball_x <= paddle_x + PADDLE_WIDTH - 2'b10)
					ball_touching_paddle <= 1'b1;
					ball_touching_wall <= 1'b1;
			        end
				else if (paddle_x - 2'b11 <= ball_x && ball_x <= paddle_x + PADDLE_WIDTH - 2'b10)begin
					ball_touching_paddle <= 1'b1;
					ball_touching_wall <= 1'b1;
				end
			end
			else if (ball_y >= SCREEN_HEIGHT - 3'b111 && ball_direction == 2'b10) begin 
				if (paddle_x <= 8'b1)begin
					if (paddle_x <= ball_x && ball_x <= paddle_x + PADDLE_WIDTH)begin
						ball_touching_paddle <= 1'b1;
						ball_touching_wall <= 1'b1;
						end
					end
				else if (paddle_x - 2'b10 <= ball_x && ball_x <= paddle_x + PADDLE_WIDTH)begin
					ball_touching_paddle <= 1'b1;
					ball_touching_wall <= 1'b1;
				end
			end
			
			else if (ball_x <= 8'b1) begin
				ball_touching_wall <= 1'b1;
				ball_touching_paddle <= 1'b0;
			end 
			else if (ball_y <= 7'b1) begin
				ball_touching_wall <= 1'b1;
				ball_touching_paddle <= 1'b0;
			end 
			else if (ball_x >= SCREEN_WIDTH - 3'b101) begin
				ball_touching_wall <= 1'b1;
				ball_touching_paddle <= 1'b0;
			end 
			else begin
				ball_touching_wall <= 1'b0;
				ball_touching_paddle <= 1'b0;
			end 
		end
    end
	
    // Determining if the ball is touching the floor logic
    always @ (posedge clk) begin
        if (!resetn)
			ball_hitting_floor <= 1'b0;
		else if (ball_y >= SCREEN_HEIGHT - 3'b101)
			ball_hitting_floor <= 1'b1;
		else 
			ball_hitting_floor <= 1'b0;
    end
    
endmodule

module binary_to_decimal(binary_digits, decimal_digits);
    input [10:0] binary_digits;
    output [11:0] decimal_digits;
	
	wire [3:0] hundreds_digit;
   
    assign hundreds_digit = binary_digits / 100;
    assign decimal_digits = {hundreds_digit, ((binary_digits - hundreds_digit * 100) / 10), binary_digits % 10};
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
