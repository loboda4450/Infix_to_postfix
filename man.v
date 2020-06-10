module man
(
    input  wire        RST,
    input  wire        CLK,
    output wire        BUSY,
    output wire        READY,
    output wire [31:0] OUT,

    input  wire [7:0]  INPUT_SIGN,
    input  wire        SIGN_STB,
    output wire        SIGN_ACK,

    input  wire [7:0]  INPUT_NUMBER,
    input  wire        NUMBER_STB,
    output wire        NUMBER_ACK
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
reg        rdy;
reg [7:0]  sign, number;

parameter GET_DATA    = 1,
          PUSH_NUM    = 2,
          POP_FIRST   = 3,
          POP_SECOND  = 4,
          CALC_POPPED = 5;


always @(posedge CLK)  begin
    if(RST) begin
        out <= 0;
        rdy <= 0;
        selector_setter <= GET_DATA;
    end

    program_selector <= selector_setter;
    casex (program_selector)
        GET_DATA: begin
            if(SIGN_STB) begin
                sign <= INPUT_SIGN;
                selector_setter <= POP_FIRST;
            end else if(NUMBER_STB) begin
                push_dat <= INPUT_NUMBER;
                push_stb <= 1;
                selector_setter <= PUSH_NUM;
            end
        end

        PUSH_NUM: begin
            if(push_stb && push_ack) push_stb <= 0;
            selector_setter <= GET_DATA;
        end
    endcase
end


assign SIGN_ACK = SIGN_STB;
assign NUMBER_ACK = NUMBER_ACK;
assign READY = rdy;
assign OUT = !rdy ? out : 0;

endmodule : man