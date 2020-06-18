module man
(
    input  wire        RST,
    input  wire        CLK,
    output wire        BUSY,
    output wire [7:0]  OUT,
    output wire        OUT_STB,

    input  wire [7:0]  INPUT_SIGN,
    input  wire        SIGN_STB,

    input  wire [7:0]  INPUT_NUMBER,
    input  wire        NUMBER_STB
);

//*******************************************STACK**************************************************
reg [31:0] num_stack [15:0];
reg [3: 0] num_stack_ptr;
//**************************************************************************************************

//***********************************DEFINING "JUMP POINTS"*****************************************
parameter GET_DATA = 1,
          PUSH_NUM = 2,
          FINISHED = 3;
//**************************************************************************************************

//****************************************AUXILIARY*************************************************
reg [3:0]  program_selector, selector_setter;
reg        busy;
reg [7:0]  sign, ftmp, stmp, tmp;
reg [31:0] result;
//**************************************************************************************************

//*****************************************MAIN CODE************************************************
always @(posedge CLK) begin
    if(RST) begin
        busy = 0;
        num_stack_ptr <= 0;
        result <= 0;
        selector_setter <= GET_DATA;
    end else begin
        program_selector <= selector_setter;
        casex (program_selector)
            GET_DATA: begin
                if(NUMBER_STB && SIGN_STB) begin
                    selector_setter <= FINISHED;
                end else if(SIGN_STB) begin
                    ftmp = num_stack[num_stack_ptr - 1];
                    num_stack_ptr = num_stack_ptr - 1;
                    stmp = num_stack[num_stack_ptr - 1];

                    casex (INPUT_SIGN)
                        "+": begin
                            tmp <= (ftmp + stmp);
                        end
                        "-": begin
                            tmp <= (ftmp - stmp);
                        end
                        "*": begin
                            tmp <= (ftmp * stmp);
                        end
                        "/": begin
                            tmp <= (stmp / ftmp);
                        end
                    endcase

                    selector_setter <= PUSH_NUM;

                end else if(NUMBER_STB) begin
                    num_stack[num_stack_ptr] <= INPUT_NUMBER;
                    num_stack_ptr += 1;
                    selector_setter <= GET_DATA;
                end
            end

            PUSH_NUM: begin
                num_stack[num_stack_ptr - 1] <= tmp;
                selector_setter <= GET_DATA;
            end

            FINISHED: begin
                casex (INPUT_SIGN)
                    "+": result <= (num_stack[0] + num_stack[1]);
                    "-": result <= (num_stack[0] - num_stack[1]);
                    "*": result <= (num_stack[0] * num_stack[1]);
                    "/": result <= (num_stack[0] / num_stack[1]);
                endcase
            end
        endcase
    end
end

assign BUSY = SIGN_STB | NUMBER_STB | busy;
assign OUT = result;
assign OUT_STB = (result != 0) && NUMBER_STB && SIGN_STB  ? 1 : 0;

//**************************************************************************************************

endmodule : man