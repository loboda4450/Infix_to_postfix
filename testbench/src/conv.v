module conv
    (
        input  wire       RST,
        input  wire       CLK,
        output wire       BUSY,

        input  wire [7:0] INPUT_SIGN,
        input  wire       SIGN_STB,
        output reg  [7:0] SIGN_OUT,
        output wire       SIGN_OUT_STB,
        input  wire       SIGN_OUT_ACK,

        input  wire [7:0] INPUT_NUMBER,
        input  wire       NUMBER_STB,
        output reg  [7:0] NUMBER_OUT,
        output wire       NUMBER_OUT_STB,
        input  wire       NUMBER_OUT_ACK
    );

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

    parameter GET_DATA = 1, //get value from file
              CHECK_PREC = 2, //check precendence of value
              PUSH_BACK = 3, //push popped value then push data
              PUSH_DATA = 4, //push value to stack
              PUSH_FIRST_STACK = 5, //push value to stack if it's empty
              PRINT_NUM = 6, //print value as decimal
              PRINT_STACK = 7, //print data from stack as long as it is not empty
              FINISHED = 8, //everything is done
              PRINT_FROM_STACK = 9; //print from stack when readed sign priority is less than top stack one

    reg [3:0] stack_counter, program_selector, selector_setter;
    wire [2:0] stack_tmp;
    reg [7:0] sign;
    reg busy;

    always @(posedge CLK) begin
        if(RST) begin
            NUMBER_OUT <= 0;
            SIGN_OUT <= 0;
            busy <= 0;
            pop_stb <= 0;
            push_stb <= 0;
            stack_counter <= 0;
            selector_setter <= GET_DATA;
        end

        program_selector = selector_setter;
        casex (program_selector)
            GET_DATA: begin
                push_stb <= 0;
                busy <= 0;
                if (NUMBER_STB && SIGN_STB) begin
                    selector_setter = PRINT_STACK;

                end else if(SIGN_STB) begin
                    casex (INPUT_SIGN)
                        11018, 43: begin
                            sign <= "+";
                            busy <= 1;
                            if(stack_counter != 0) pop_stb <= 1;
                            selector_setter <= CHECK_PREC;
                        end

                        11530, 45: begin
                            sign <= "-";
                            busy <= 1;
                            if(stack_counter != 0) pop_stb <= 1;
                            selector_setter <= CHECK_PREC;
                        end

                        10762, 42: begin
                            sign <= "*";
                            busy <= 1;
                            if(stack_counter != 0) pop_stb <= 1;
                            selector_setter <= CHECK_PREC;
                        end

                        12042, 47: begin
                            sign <= "/";
                            busy <= 1;
                            if(stack_counter != 0) pop_stb <= 1;
                            selector_setter <= CHECK_PREC;
                        end
                    endcase

                end else if (NUMBER_STB) begin
                    NUMBER_OUT <= INPUT_NUMBER;
                end
            end

            CHECK_PREC: begin
                if(busy && stack_counter != 0) begin
                    if (sign == 43 || sign == 45) begin //handling "+" and "-"
                        if(stack_tmp == 1 || stack_tmp == 2) begin
                            casex (stack_tmp)
                                1: SIGN_OUT <= "+";
                                2: SIGN_OUT <= "-";
                            endcase
                            selector_setter <= PUSH_DATA;
                        end else if(stack_tmp == 3 || stack_tmp == 4) begin
                            selector_setter <= PRINT_FROM_STACK;
                        end
                    end

                    else if (sign == 42 || sign == 47) begin //handling "*"	and "/"
                        if(stack_tmp == 3 || stack_tmp == 4) begin
                            casex (stack_tmp)
                                3: SIGN_OUT <= "*";
                                4: SIGN_OUT <= "/";
                            endcase
                            selector_setter <= PUSH_DATA;
                        end else if(stack_tmp == 1 || stack_tmp == 2) begin
                            selector_setter <= PUSH_BACK;
                        end
                    end
                end else if (busy && stack_counter == 0) begin
                    selector_setter = PUSH_FIRST_STACK;
                end
            end

            PRINT_FROM_STACK: begin
                casex (stack_tmp)
                    1: SIGN_OUT <= "+";
                    2: SIGN_OUT <= "-";
                    3: SIGN_OUT <= "*";
                    4: SIGN_OUT <= "/";
                endcase

                selector_setter <= CHECK_PREC;
            end

            PUSH_FIRST_STACK: begin
                casex (sign)
                    "+": push_dat <= 1;
                    "-": push_dat <= 2;
                    "*": push_dat <= 3;
                    "/": push_dat <= 4;
                endcase
                push_stb <= 1;
                stack_counter++;
                selector_setter <= GET_DATA;
            end

            PUSH_DATA: begin
                casex (sign)
                    "+": push_dat <= 1;
                    "-": push_dat <= 2;
                    "*": push_dat <= 3;
                    "/": push_dat <= 4;
                endcase
                push_stb <= 1;
                stack_counter++;
                selector_setter <= GET_DATA;
            end

            PUSH_BACK: begin
                push_stb <= 1;
                push_dat <= stack_tmp;
                stack_counter++;
                selector_setter <= PUSH_DATA;
            end

            PRINT_STACK: begin
                if(stack_counter != 0) begin
                    casex (pop_dat)
                        1: SIGN_OUT <= "+";
                        2: SIGN_OUT <= "-";
                        3: SIGN_OUT <= "*";
                        4: SIGN_OUT <= "/";
                    endcase
                    selector_setter = PRINT_STACK;
                end else if(stack_counter == 0) begin
                    selector_setter = FINISHED;
                end
            end

            FINISHED: begin

            end
        endcase
    end


    always @(posedge CLK) begin
        if(stack_counter != 0 && !pop_stb && (selector_setter == CHECK_PREC ||
            selector_setter == PRINT_STACK || selector_setter == PRINT_FROM_STACK)) pop_stb <= 1;
        else if(pop_stb && pop_ack) begin
            stack_counter--;
            pop_stb <= 0;
        end
    end


    assign stack_tmp = pop_stb ? pop_dat : stack_tmp;
    assign BUSY = SIGN_STB | NUMBER_STB | busy;

endmodule : conv