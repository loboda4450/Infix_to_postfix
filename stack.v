module stack
(                            
input  wire        CLK,      
input  wire        RST,                      
input  wire        PUSH_STB, 
input  wire [31:0] PUSH_DAT,                            
input  wire        POP_STB,  
output wire [31:0] POP_DAT,
output wire        POP_ACK,
output wire        PUSH_ACK
);                           
//-------------------------------------------------------------------------------
reg    [3:0] push_ptr;
//-------------------------------------------------------------------------------
reg    [3:0] pop_ptr;
//-------------------------------------------------------------------------------
always@(posedge CLK or posedge RST)
if(RST)  
	begin   
		pop_ptr  <= 4'hF;
		push_ptr <= 4'h0; 
end
else if(PUSH_STB)
	begin
		push_ptr <= push_ptr + 4'd1;
		pop_ptr  <= pop_ptr  + 4'd1;
end    
	else if(POP_STB)
		begin
			push_ptr <= push_ptr - 4'd1;
			pop_ptr  <= pop_ptr  - 4'd1;
end    	

//-------------------------------------------------------------------------------
reg [31:0] RAM [0:15];  
//-------------------------------------------------------------------------------
reg [31:0] O_BUF;
//-------------------------------------------------------------------------------
always@( posedge CLK)
if(PUSH_STB) RAM [ push_ptr ] <= PUSH_DAT;
//-------------------------------------------------------------------------------
always@( posedge CLK) O_BUF = RAM[pop_ptr]; 
//-------------------------------------------------------------------------------

assign POP_DAT  = POP_STB  ? O_BUF : 0;  
assign POP_ACK  = PUSH_STB ?     0 : 1;  
assign PUSH_ACK = POP_STB  ?     0 : 1;

endmodule