module testbench();
reg CLK;
initial CLK  <= 0;
always #50  CLK <= ~CLK;
		
reg RST;

integer file, count, file_error;

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
end


converter 
#(
.SIZE(9)
)
conv 
(
.RST(RST),
.CLK(CLK),
.REC_ACK(1),
.OUT(),
.SEND_STB(send_stb),
.FINISHED_ACK(finished_ack)
);


endmodule : testbench