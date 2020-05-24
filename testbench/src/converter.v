module converter
#(
	parameter SIZE = 16
)
(
	input wire RST,
	input wire CLK,
	input wire REC_ACK,
	output reg [7:0] OUT,
	output wire SEND_STB,
	output wire FINISHED_ACK
);

parameter GET_DATA = 1, //get value from file
		  CHECK_PREC = 2, //check precendence of value
		  PUSH_BACK = 3, //push popped value then push data
		  PUSH_DATA = 4, //push value to stack
		  PUSH_FIRST_STACK = 5, //push value to stack if it's empty
		  PRINT_NUM = 6, //print value as decimal
		  PRINT_STACK = 7, //print data from stack as long as it is not empty
		  FINISHED = 8; //everything is done.

reg [87:0] data, stack_tmp;
reg [3 :0] stack_counter = 0, program_selector = 3'b0, selector_setter = GET_DATA;
reg [7 :0] output_data;
reg job_done = 0, out_ack = 0;

//******************************************FILE_OPEN***********************************************
integer file, count, file_error;

initial
	begin
		file = $fopen("input.txt", "r");
		if(file == 0) begin
			$display("ERROR, couldn't open file");
			$finish;
		end
	end
//**************************************************************************************************

//*******************************************STACK**************************************************
reg          push_stb;
reg  [31:0]  push_dat;
wire [31:0]  pop_dat;
reg          pop_stb;
wire         pop_ack;
wire         push_ack;

stack stck
	  (
		  .CLK(CLK),
		  .RST(RST),
		  .PUSH_STB(push_stb),
		  .PUSH_DAT(push_dat),
		  .POP_STB(pop_stb),
		  .POP_DAT(pop_dat),
		  .POP_ACK(pop_ack),
		  .PUSH_ACK(push_ack)
	  );
//**************************************************************************************************

always @(posedge CLK) if (!RST && REC_ACK) begin
	program_selector = selector_setter; @(posedge CLK);
	casex (program_selector)
		GET_DATA: begin
			count = $fgets(data, file); @(posedge CLK);
			if(count != 0) begin
				casex (data)
					11018, 43: begin
						data = "+";
						selector_setter = CHECK_PREC;
					end

					11530, 45: begin
						data = "-";
						selector_setter = CHECK_PREC;
					end

					10762, 42: begin
						data = "*";
						selector_setter = CHECK_PREC;
					end

					12042, 47: begin
						data = "/";
						selector_setter = CHECK_PREC;
					end

					10250, 40: begin
						data = "("; @(posedge CLK);
						selector_setter = CHECK_PREC;
					end

					10506, 41: begin
						data = ")"; @(posedge CLK);
						selector_setter = CHECK_PREC;
					end

					default: begin
						selector_setter = PRINT_NUM;
					end
				endcase
			end
			else begin
				selector_setter = PRINT_STACK;
			end
		end

		CHECK_PREC: begin
			if (count != 0 && stack_counter != 0) begin
				pop_stb <= 1; @(posedge CLK);
				stack_tmp = pop_dat;
				pop_stb <= 0; @(posedge CLK);
				stack_counter--;
				if (data == 43) begin //handling "+"
					if(stack_tmp == 1) begin
						OUT <= data;
						out_ack <= 1; @(posedge CLK);
						out_ack <= 0; @(posedge CLK);
						selector_setter = PUSH_DATA;
					end else if (stack_tmp == 2) begin
						OUT <= "-";
						out_ack <= 1; @(posedge CLK);
						out_ack <= 0; @(posedge CLK);
						selector_setter = PUSH_DATA;
					end else begin
						selector_setter = PUSH_BACK;
					end
				end

				else if (data == 45) begin //handling "-"
					if(stack_tmp == 1) begin
						OUT <= "+";
						out_ack <= 1; @(posedge CLK);
						out_ack <= 0; @(posedge CLK);
						selector_setter = PUSH_DATA;
					end else if (stack_tmp == 2) begin
						OUT <= data;
						out_ack <= 1; @(posedge CLK);
						out_ack <= 0; @(posedge CLK);
						selector_setter = PUSH_DATA;
					end else begin
						selector_setter = PUSH_BACK;
					end
				end

				else if (data == 42) begin //handling "*"
					if(stack_tmp == 3) begin
						OUT <= data;
						out_ack <= 1; @(posedge CLK);
						out_ack <= 0; @(posedge CLK);
						selector_setter = PUSH_DATA;
					end else if (stack_tmp == 4) begin
						OUT <= "/";
						out_ack <= 1; @(posedge CLK);
						out_ack <= 0; @(posedge CLK);
						selector_setter = PUSH_DATA;
					end else begin
						selector_setter = PUSH_BACK;
					end
				end

				else if (data == 47) begin //handling "/"
					if(stack_tmp == 3) begin
						OUT <= "*";
						out_ack <= 1; @(posedge CLK);
						out_ack <= 0; @(posedge CLK);
						selector_setter = PUSH_DATA;
					end else if (stack_tmp == 4) begin
						OUT <= data;
						out_ack <= 1; @(posedge CLK);
						out_ack <= 0; @(posedge CLK);
						selector_setter = PUSH_DATA;
					end else begin
						selector_setter = PUSH_BACK;
					end
				end
			end else begin
				selector_setter = PUSH_FIRST_STACK;
			end
		end

		PRINT_NUM: begin
			file_error = !$sscanf(data, "%d", OUT);
			out_ack <= 1; @(posedge CLK);
			out_ack <= 0; @(posedge CLK);
			selector_setter = GET_DATA;
		end

		PUSH_FIRST_STACK: begin
			casex (data)
				"+": push_dat <= 1;
				"-": push_dat <= 2;
				"*": push_dat <= 3;
				"/": push_dat <= 4;
			endcase

			push_stb <= 1; @(posedge CLK);
			push_stb <= 0; @(posedge CLK);
			stack_counter++;
			selector_setter = GET_DATA;
		end

		PUSH_DATA: begin
			casex (data)
				"+": push_dat <= 1;
				"-": push_dat <= 2;
				"*": push_dat <= 3;
				"/": push_dat <= 4;
			endcase

			push_stb <= 1; @(posedge CLK);
			push_stb <= 0; @(posedge CLK);
			stack_counter++;
			selector_setter = GET_DATA;
		end

		PUSH_BACK: begin
			casex (stack_tmp)
				"+": push_dat <= 1;
				"-": push_dat <= 2;
				"*": push_dat <= 3;
				"/": push_dat <= 4;
			endcase

			push_stb <= 1; @(posedge CLK);
			push_stb <= 0; @(posedge CLK);
			stack_counter++;

			casex (data)
				"+": push_dat <= 1;
				"-": push_dat <= 2;
				"*": push_dat <= 3;
				"/": push_dat <= 4;
			endcase

			push_stb <= 1; @(posedge CLK);
			push_stb <= 0; @(posedge CLK);
			stack_counter++;
			selector_setter = GET_DATA;
		end

		PRINT_STACK: begin
			if(stack_counter != 0) begin
				pop_stb <= 1; @(posedge CLK);
				stack_tmp = pop_dat;
				pop_stb <= 0; @(posedge CLK);
				stack_counter--;

				casex (stack_tmp)
					1: OUT <= "+";
					2: OUT <= "-";
					3: OUT <= "*";
					4: OUT <= "/";
				endcase
				out_ack <= 1; @(posedge CLK);
				out_ack <= 0; @(posedge CLK);

				selector_setter = PRINT_STACK;
			end
			else begin
				selector_setter = FINISHED;
			end
		end

		FINISHED: begin
			job_done = 1;
		end
	endcase
end

assign SEND_STB = out_ack;
assign FINISHED_ACK = job_done;

endmodule : converter