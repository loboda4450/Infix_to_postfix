module testbench();
reg CLK;
initial CLK  <= 0;
always #50  CLK <= ~CLK;

reg RST;

integer file, count, file_error;
reg [87:0] data;
reg [31:0] result;
reg [7:0] input_sign;
reg [7:0] input_number;
reg input_sign_stb;
reg input_number_stb;
wire busy, busy_2, rdy, no_ack, so_ack, no_stb, so_stb;

wire [7:0] OUTPUT_SIGN, OUTPUT_NUMBER;


initial
    begin
        RST <= 0;
        RST <= #50 1;
        RST <= #500 0;
        file = $fopen("input.txt", "r");
        if(file == 0) begin
            $display("ERROR, couldn't open file");
            $finish;
        end
        input_number_stb <= 0;
        input_sign_stb <= 0;
    end

always @(posedge CLK) if (!busy && !RST) begin
    count = $fgets(data, file);
    if(count != 0) begin
        casex (data)
            11018, 43: begin
                input_sign <= "+";
                input_sign_stb <= 1;
            end

            11530, 45: begin
                input_sign <= "-";
                input_sign_stb <= 1;
            end

            10762, 42: begin
                input_sign <= "*";
                input_sign_stb <= 1;
            end

            12042, 47: begin
                input_sign <= "/";
                input_sign_stb <= 1;
            end

            default : begin
                file_error = !$sscanf(data, "%d", input_number);
                input_number_stb <= 1;
            end
        endcase
    end else begin
        input_sign_stb <= 1;
        input_number_stb <= 1;
    end
end

always @(posedge CLK) begin
    if(input_sign_stb && busy) input_sign_stb <= 0;
    else if(input_number_stb && busy) input_number_stb <= 0;
end


conv converter
(
    .RST(RST),
    .CLK(CLK),
    .BUSY(busy),


    .INPUT_SIGN(input_sign),
    .SIGN_STB(input_sign_stb),
    .SIGN_OUT(OUTPUT_SIGN),
    .SIGN_OUT_STB(so_stb),
    .SIGN_OUT_ACK(1),

    .INPUT_NUMBER(input_number),
    .NUMBER_STB(input_number_stb),
    .NUMBER_OUT(OUTPUT_NUMBER),
    .NUMBER_OUT_STB(no_stb),
    .NUMBER_OUT_ACK(1)
);

man man
(
    .RST(RST),
    .CLK(CLK),
    .BUSY(busy_2),
    .READY(rdy),
    .OUT(result),

    .INPUT_SIGN(OUTPUT_SIGN),
    .SIGN_STB(so_stb),
    .SIGN_ACK(),

    .INPUT_NUMBER(OUTPUT_NUMBER),
    .NUMBER_STB(no_stb),
    .NUMBER_ACK()
);


endmodule : testbench