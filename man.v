module man
(
    input  wire        RST,
    input  wire        CLK,
    output wire        BUSY,
    output wire [31:0] OUT,

    input  wire [7:0]  INPUT_SIGN,
    input  wire        SIGN_STB,

    input  wire [7:0]  INPUT_NUMBER,
    input  wire        NUMBER_STB,
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

reg [31:0] out;
reg [3:0]  stack_counter, program_selector, selector_setter;
reg        busy;
reg [7:0]  sign, f_num, s_num;
reg [31:0] result;

parameter GET_DATA    = 1,
          PUSH_NUM    = 2,
          POP_FIRST   = 3,
          POP_SECOND  = 4,
          CALC_POPPED = 5,
          PUSH_RESULT = 6,
          FINISHED    = 7;


always @(posedge CLK)  begin
    if(RST) begin
        out <= 0;
        pop_stb <= 0;
        push_stb <= 0;
        busy = 0;
        selector_setter <= GET_DATA;
    end

    program_selector <= selector_setter;
    casex (program_selector)
        GET_DATA: begin
            if(NUMBER_STB && SIGN_STB) begin
                selector_setter <= FINISHED;
            end else if(SIGN_STB) begin
                busy <= 1;
                sign <= INPUT_SIGN;
                pop_stb <= 1;
                selector_setter <= POP_FIRST;
            end else if(NUMBER_STB) begin
                busy <= 1;
                push_dat <= INPUT_NUMBER;
                push_stb <= 1;
                selector_setter <= PUSH_NUM;
            end
        end

        PUSH_NUM: begin
            busy <= 0;
            selector_setter <= GET_DATA;
        end

        POP_FIRST:begin
            f_num <= pop_dat;
            selector_setter <= POP_SECOND;
        end

        POP_SECOND: begin
            s_num <= pop_dat;
            selector_setter <= CALC_POPPED;
        end

        CALC_POPPED: begin
            casex (sign)
                "+": push_dat <= (f_num + s_num);
                "-": push_dat <= (f_num - s_num);
                "*": push_dat <= (f_num * s_num);
                "/": push_dat <= (f_num / s_num);
            endcase

            push_stb <= 1;
            busy <= 0;
            selector_setter <= GET_DATA;
        end

        FINISHED: begin

        end

    endcase
end

always @(posedge CLK) begin
    if(push_stb && push_ack) push_stb <= 0;
    if(pop_stb && pop_ack) pop_stb <= 0;
end

assign BUSY = SIGN_STB | NUMBER_STB | busy;
assign OUT = out;

endmodule : man