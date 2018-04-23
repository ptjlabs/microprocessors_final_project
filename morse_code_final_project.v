module project(SW,KEY,CLOCK_50,LEDR,LEDG);
	input [4:0] SW; // for letter selection
	input [1:0] KEY; // Start & Asynchronous ResetN
	input CLOCK_50; // 50MHz clock
	output [0:0] LEDR; // Outputs Morse Code 
	output [2:0] LEDG;	//used to test states
	
	reg [25:0] count;	//counts 50 MHz clock signals to 0.5 seconds 
	reg [4:0] length;	//morse code length  (from 1-4)
	reg [4:0] counter;	//morse code length counter (from 1-4)
	reg [3:0] M;	//morse code, 1 = dash, 0 = dot
	reg [3:0] Q;	//shift register outputs, Q[3] is the input to the FSM
	reg z;			//output to ledr
	
	reg[2:0] y_Q, Y_D;	//y_Q represents current state, Y_D represents next state
	// Letter representation of SW[2:0] input  
	parameter Aa = 5'b00000, Ba = 5'b00001, Ca = 5'b00010, Da = 5'b00011, Ea = 5'b00100,
				Fa = 5'b00101, Ga = 5'b00110, Ha = 5'b00111, Ia = 5'b01000, Ja = 5'b01001,
				Ka = 5'b01010, La = 5'b01011, Ma = 5'b01100, Na = 5'b01101, Oa = 5'b01110,
				Pa = 5'b01111, Qa = 5'b10000, Ra = 5'b10001, Sa = 5'b10010, Ta = 5'b10011,
				Ua = 5'b10100, Va = 5'b10101, Wa = 5'b10110, Xa = 5'b10111, Ya = 5'b11000,
				Za = 5'b11001;

	// States using minimum state encoding 
	parameter A = 5'b00000, B = 5'b00001, C = 5'b00010, D = 5'b00011, E = 5'b00100;  
		
	assign LEDR = z;
	
	always @(SW) // anytime user changes his selection, reset length of word and its output form 
	begin: letter_selection
		case(SW[4:0])
			Aa: begin
					length = 5'b00010;
					M = 4'b0100;
				end
			Ba: begin
					length = 5'b00100;
					M = 4'b1000;
				end
			Ca: begin
					length = 5'b00100;
					M = 4'b1010;
				end
			Da: begin
					length = 5'b00011;
					M = 4'b1000;
				end
			Ea: begin
					length = 5'b00001;
					M = 4'b0000;
				end
			Fa: begin
					length = 5'b00100;
					M = 4'b0010;
				end
			Ga: begin
					length = 5'b00011;
					M = 4'b1100;
				end
			Ha: begin
					length = 5'b00100;
					M = 4'b0000;
				end
			Ia: begin
					length = 5'b00010;
					M = 4'b0000;
				end
			Ja: begin
					length = 5'b00100;
					M = 4'b0111;
				end
			Ka: begin
					length = 5'b00011;
					M = 4'b1010;
				end
			La: begin
					length = 5'b00100;
					M = 4'b0100;
				end
			Ma: begin
					length = 5'b00010;
					M = 4'b1100;
				end
			Na: begin
					length = 5'b00010;
					M = 4'b1000;
				end
			Oa: begin
					length = 5'b00011;
					M = 4'b1110;
				end
			Pa: begin
					length = 5'b00100;
					M = 4'b0110;
				end
			Qa: begin
					length = 5'b00100;
					M = 4'b1101;
				end
			Ra: begin
					length = 5'b00011;
					M = 4'b0100;
				end
			Sa: begin
					length = 5'b00011;
					M = 4'b0000;
				end
			Ta: begin
					length = 5'b00001;
					M = 4'b1000;
				end
			Ua: begin
					length = 5'b00011;
					M = 4'b0010;
				end
			Va: begin
					length = 5'b00100;
					M = 4'b0001;
				end
			Wa: begin
					length = 5'b00011;
					M = 4'b0110;
				end
			Xa: begin
					length = 5'b00100;
					M = 4'b1001;
			Ya: begin
					length = 5'b00100;
					M = 4'b1011;
				end
			Za: begin
					length = 5'b00100;
					M = 4'b1100;
				end
				end

		endcase
	end	//letter_selection
	
//State Table
	// anytime register changes shift output, reset/start is pressed, 
	// when counter decrements cause 1 symbol is shown or current state changes 
	always @(Q[3], KEY[1:0], counter, y_Q) 
													
	begin: state_table
		case (y_Q)
			// State A = Idle State 
			A: if (!KEY[1]) Y_D = B; // if start is pressed, go to state B 
				else Y_D = A; // else, remain idle at state A 
			// State B => State Selection State  
			B: if (!Q[3]) Y_D = E; // if next Symbol is 0, go to state E (outputs 0.5sec)
				else Y_D = C; // if next Symbol is 1, go to state C (outputs 0.5sec)
			// B -> C -> D -> => 1.5 seconds => dash 
			C: if (!KEY[0]) Y_D = A; // as long as reset is pressed, go to state A
				else Y_D = D;			// else, go to state D
			D: if (!KEY[0]) Y_D = A; // as long as reset is pressed, go to state A
				else Y_D = E;			// else, go to state E 
			// B -> E 			=> 0.5 seconds => dot // the transition turns on LED for 0.5 seconds 
			E: if (counter == 0) Y_D = A; // if counter is 0, no more symbols, go to state A
				else Y_D = B;					// else, go to state B 
		default: Y_D = 5'bxxxxx; // In case of weird behaviour 
		endcase
	end	//state table
	
	//clock counter
	always @(posedge CLOCK_50)
	begin
		if (count < 50000000/2) // at every 0.5 seconds, activate  
			count <= count + 1;
		else
		begin
			count <= 0;
			y_Q <= Y_D; // go to next state 
			if (Y_D == A) begin // if next state is A, update counter to length and pattern to M 
				counter <= length;
				Q <= M;
			end
			if (Y_D == E) begin    // if state E 
				counter <= counter - 1; // deduct counter 
				// Shift pattern 
				Q[3] <= Q[2];
				Q[2] <= Q[1]; 
				Q[1] <= Q[0];
				Q[0] <= 1'b0;
			end
		end
	end
	
	//assign LEDR[0] = ~(~y_Q[0]&~y_Q[1]);
	
	// LED output based on current state 
	always @(y_Q)
	begin: zassign
		case (y_Q)
			B: z = 1; // turn on output 
			C: z = 1; // turn on output 
			D: z = 1; // turn on output 
			default: z = 0; // off output at States E or A 
		endcase
	end
endmodule 
