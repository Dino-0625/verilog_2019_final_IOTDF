`timescale 1ns/10ps
module IOTDF( clk, rst, in_en, iot_in, fn_sel, busy, valid, iot_out);
input          clk;
input          rst;
input          in_en;
input  [7:0]   iot_in;
input  [2:0]   fn_sel;
output         busy;
output         valid;
output reg [127:0] iot_out;

parameter GETDATA = 3'b000;
parameter Fun1 = 3'b001;
parameter Fun2 = 3'b010;
parameter Fun3 = 3'b011;
parameter Fun4 = 3'b100;
parameter Fun5 = 3'b101;
parameter Fun6 = 3'b110;
parameter Fun7 = 3'b111;


reg f1_ret, f2_ret, f3_ret, f4_ret, f5_ret, f6_ret, f7_ret, hold;
reg cin_0, cin_1, cin_2, cin_3, cin_4, cin_5, cin_6, cin_7, cin_8, cin_9, cin_10, cin_11, cin_12, cin_13, cin_14, cin_15, cin;
reg excludeable, extractable, peak_change;
reg [1:0] shift;
reg [7:0] compare1, compare2, iot_max_8_bit, iot_previous_8_bit;
reg [2:0] state, nextState;
reg [3:0] ith_cycle, MSB3;
reg [6:0] dataset_num; //total 96
reg [7:0] adder1, adder2;
wire [8:0] adder;

wire compare, getdata, equal, extract, exclude, avg;
wire [3:0] F4_low, F4_high, F5_low, F5_high;
assign compare = compare1 > compare2;
assign equal = (compare1 == compare2);
assign adder = adder1 + adder2 + cin;
assign busy = hold;
assign getdata = (state == GETDATA);
assign extract = (fn_sel == 4);
assign exclude = (fn_sel == 5);
assign avg     = (fn_sel == 3);
assign F4_low = 6;
assign F4_high = 10;
assign F5_low = 7;
assign F5_high = 11;

assign valid = (f1_ret && (fn_sel == 1)) || (f2_ret&& (fn_sel == 2)) || (f3_ret&& (fn_sel == 3)) || (f4_ret&& (fn_sel == 4)) || (f5_ret&& (fn_sel == 5)) || (f6_ret&& (fn_sel == 6)) || (f7_ret&& (fn_sel == 7));


always@(posedge clk)begin
	if(rst)
		hold <= 0;
	else if((fn_sel == 3)&&(dataset_num[2:0] == 7 && ith_cycle == 14)&& in_en)
		hold <= 1;
	else if((fn_sel == 3)&&(dataset_num[2:0] == 7 && ith_cycle == 14)&& !in_en)
		hold <= 0;
	else
		hold <= hold;
	
end
always@(posedge clk)begin
	//shift 0 ==> unknown, shift 1 ==> shift, shift 2 ==>not shift
	if(rst || ith_cycle == 15)
		shift <= 0;
	else if(shift == 1 || shift == 2)
		shift <= shift;
	else
		case(state)
			Fun1:begin
				if(equal)
					shift <= shift;
				else if(compare)
					shift <= 2;
				else
					shift <= 1;
					
			end
			Fun2:begin
				if(equal)
					shift <= shift;
				else if(compare)
					shift <= 1;
				else
					shift <= 2;
					
			end
			Fun6:begin
				if(equal)
					shift <= shift;
				else if(compare)
					shift <= 2;
				else
					shift <= 1;
					
			end
			Fun7:begin
				if(equal)
					shift <= shift;
				else if(compare)
					shift <= 1;
				else
					shift <= 2;
					
			end
		endcase
end
always@(state, fn_sel, ith_cycle)begin
	case(state)
		GETDATA:begin
			if(ith_cycle == 15)
				case(fn_sel)
					1:nextState = Fun1;
					2:nextState = Fun2;
					3:nextState = Fun3;
					4:nextState = Fun4;
					5:nextState = Fun5;
					6:nextState = Fun6;
					7:nextState = Fun7;
					default: nextState = Fun1;
				endcase
			else
				nextState = GETDATA;
			
		end
		Fun1, Fun2:begin
			if(dataset_num[2:0] == 7 && ith_cycle == 15)begin
					nextState = GETDATA;
				end
			else if(state == Fun1)
				nextState = Fun1;
			else
				nextState = Fun2;
				
		end
		Fun3:begin
			if(dataset_num[2:0] == 7 && ith_cycle == 15 && !in_en)begin
					nextState = GETDATA;
			end
			else
				nextState = Fun3;
		end
		Fun4:
			nextState = Fun4;
		Fun5:
			nextState = Fun5;
		Fun6:
			nextState = Fun6;
		Fun7:
			nextState = Fun7;
		default:
			nextState = 0;
	endcase
end

always@(posedge clk)begin
	if(rst)
		state <= 0;
	else
		state <= nextState;
end

always@(posedge clk)begin
	if(rst)begin
		extractable <= 0;
		excludeable <= 0;
		MSB3 <= 0;
		cin_0 <= 0;
		cin_1 <= 0;
		cin_2 <= 0;
		cin_3 <= 0;
		cin_4 <= 0;
		cin_5 <= 0;
		cin_6 <= 0;
		cin_7 <= 0;
		cin_8 <= 0;
		cin_9 <= 0;
		cin_10 <= 0;
		cin_11 <= 0;
		cin_12 <= 0;
		cin_13 <= 0;
		cin_14 <= 0;
		cin_15 <= 0;
	end
	
	else
		case(ith_cycle)
			0:begin
				if(getdata || extract || exclude)
					iot_out[127:120] <= iot_in;
					
				else if(avg)begin
					iot_out[127:120] <= adder[7:0];
					MSB3 <= MSB3 + adder[8];
				end
				else	
					iot_out[127:120] <= iot_out[127:120];
				iot_max_8_bit <= iot_in;
				iot_previous_8_bit <= iot_in;
				
			end
			1:begin 
				if(getdata || extract || exclude)
					iot_out[119:112] <= iot_in;
				else if(shift == 1)begin
					iot_out[119:112] <= iot_in;
					
					iot_out[127:120] <= iot_previous_8_bit;
				end
				else if(avg)begin
					iot_out[119:112] <= adder[7:0];
					cin_1 <= adder[8];
				end
				else
					iot_out[119:112] <= iot_out[119:112];
				if(extract)begin
					if(iot_out[127:124] <= F4_high && iot_out[127:124] > F4_low)
						extractable <= 1;
					else
						extractable <= 0;
				end
				if(exclude)begin
					if(iot_out[127:124] <= F5_low || iot_out[127:124] > F5_high)
						excludeable <= 1;
					else
						excludeable <= 0;
				end
				iot_previous_8_bit <= iot_in;
				
			end
			2:begin
				if(getdata || extract || exclude)
					iot_out[111:104] <= iot_in;
				else if(shift == 1)begin
					iot_out[111:104] <= iot_in;
					iot_out[119:112] <= iot_previous_8_bit;
				end
				else if(avg)begin
					iot_out[111:104] <= adder[7:0];
					cin_2 <= adder[8];
				end
				else
					iot_out[111:104] <= iot_out[111:104];
				iot_previous_8_bit <= iot_in;
			end
			3:begin
				if(getdata || extract || exclude)
					iot_out[103:96] <= iot_in;
				else if(shift == 1)begin
					iot_out[103:96] <= iot_in;
					iot_out[111:104] <= iot_previous_8_bit;
				end
				else if(avg)begin
					iot_out[103:96] <= adder[7:0];
					cin_3 <= adder[8];
				end
				else
					iot_out[103:96] <= iot_out[103:96];
				iot_previous_8_bit <= iot_in;
			end
			4:begin
				if(getdata || extract || exclude)
					iot_out[95:88] <= iot_in;
				else if(shift == 1)begin
					iot_out[95:88] <= iot_in;
					iot_out[103:96] <= iot_previous_8_bit;
				end
				else if(avg)begin
					iot_out[95:88] <= adder[7:0];
					cin_4 <= adder[8];
				end
				else
					iot_out[95:88] <= iot_out[95:88];
				iot_previous_8_bit <= iot_in;
			end
			5:begin
				if(getdata || extract || exclude)
					iot_out[87:80] <= iot_in;
				else if(shift == 1)begin
					iot_out[87:80] <= iot_in;
					iot_out[95:88] <= iot_previous_8_bit;
				end
				else if(avg)begin
					iot_out[87:80] <= adder[7:0];
					cin_5 <= adder[8];
				end
				else
					iot_out[87:80] <= iot_out[87:80];
				iot_previous_8_bit <= iot_in;
			end
			6:begin
				if(getdata || extract || exclude)
					iot_out[79:72] <= iot_in;
				else if(shift == 1)begin
					iot_out[79:72] <= iot_in;
					iot_out[87:80] <= iot_previous_8_bit;
				end
				else if(avg)begin
					iot_out[79:72] <= adder[7:0];
					cin_6 <= adder[8];
				end
				else
					iot_out[79:72] <= iot_out[79:72];
				iot_previous_8_bit <= iot_in;
			end
			7:begin 
				if(getdata || extract || exclude)
					iot_out[71:64] <= iot_in;
				else if(shift == 1)begin
					iot_out[71:64] <= iot_in;
					iot_out[79:72] <= iot_previous_8_bit;
				end
				else if(avg)begin
					iot_out[71:64] <= adder[7:0];
					cin_7 <= adder[8];
				end
				else
					iot_out[71:64] <= iot_out[71:64];
				iot_previous_8_bit <= iot_in;
			end
			8:begin
				if(getdata || extract || exclude)
					iot_out[63:56] <= iot_in;
				else if(shift == 1)begin
					iot_out[63:56] <= iot_in;
					iot_out[71:64] <= iot_previous_8_bit;
				end
				else if(avg)begin
					iot_out[63:56] <= adder[7:0];
					cin_8 <= adder[8];
				end
				else
					iot_out[63:56] <= iot_out[63:56];
				iot_previous_8_bit <= iot_in;
			end
			9:begin
				if(getdata || extract || exclude)
					iot_out[55:48] <= iot_in;
				else if(shift == 1)begin
					iot_out[55:48] <= iot_in;
					iot_out[63:56] <= iot_previous_8_bit;
				end
				else if(avg)begin
					iot_out[55:48] <= adder[7:0];
					cin_9 <= adder[8];
				end
				else
					iot_out[55:48] <= iot_out[55:48];
				iot_previous_8_bit <= iot_in;
			end
			10:begin
				if(getdata || extract || exclude)
					iot_out[47:40] <= iot_in;
				else if(shift == 1)begin
					iot_out[47:40] <= iot_in;
					iot_out[55:48] <= iot_previous_8_bit;
				end
				else if(avg)begin
					iot_out[47:40] <= adder[7:0];
					cin_10 <= adder[8];
				end
				else
					iot_out[47:40] <= iot_out[47:40];
				iot_previous_8_bit <= iot_in;
			end
			11:begin
				if(getdata || extract || exclude)
					iot_out[39:32] <= iot_in;
				else if(shift == 1)begin
					iot_out[39:32] <= iot_in;
					iot_out[47:40] <= iot_previous_8_bit;
				end
				else if(avg)begin
					iot_out[39:32] <= adder[7:0];
					cin_11 <= adder[8];
				end
				else
					iot_out[39:32] <= iot_out[39:32];
				iot_previous_8_bit <= iot_in;
			end
			12:begin
				if(getdata || extract || exclude)
					iot_out[31:24] <= iot_in;
				else if(shift == 1)begin
					iot_out[31:24] <= iot_in;
					iot_out[39:32] <= iot_previous_8_bit;
				end
				else if(avg)begin
					iot_out[31:24] <= adder[7:0];
					cin_12 <= adder[8];
				end
				else
					iot_out[31:24] <= iot_out[31:24];
				iot_previous_8_bit <= iot_in;
			end
			13:begin
				if(getdata || extract || exclude)
					iot_out[23:16] <= iot_in;
				else if(shift == 1)begin
					iot_out[23:16] <= iot_in;
					iot_out[31:24] <= iot_previous_8_bit;
				end
				else if(avg)begin
					iot_out[23:16] <= adder[7:0];
					cin_13 <= adder[8];
				end
				else
					iot_out[23:16] <= iot_out[23:16];
				iot_previous_8_bit <= iot_in;
			end
			14:begin
				if(getdata || extract || exclude)
					iot_out[15:8] <= iot_in;
				else if(shift == 1)begin
					iot_out[15:8] <= iot_in;
					iot_out[23:16] <= iot_previous_8_bit;
				end
				else if(avg)begin
					iot_out[15:8] <= adder[7:0];
					cin_14 <= adder[8];
				end
				else
					iot_out[15:8] <= iot_out[15:8];
				iot_previous_8_bit <= iot_in;
			end
			15:begin
				if(getdata || extract || exclude)
					iot_out[7:0] <= iot_in;
				else if(shift == 1)begin
					iot_out[7:0] <= iot_in;
					iot_out[15:8] <= iot_previous_8_bit;
				end
				else if(avg)begin
					iot_out[7:0] <= adder[7:0];
					cin_15 <= adder[8];
				end
				else
					iot_out[7:0] <= iot_out[7:0];
				iot_previous_8_bit <= iot_in;
				if(dataset_num[2:0] == 7 && !in_en)begin
				
					iot_out <= {MSB3[2:0],iot_out[127:3]};
					MSB3 <= 0;
				end
			end
		endcase
end

always@(iot_out, iot_in, rst,ith_cycle)begin
	if(rst)begin
		compare1 = 0;
		compare2 = 0;
		adder1 = 0;
		adder2 = 0;
	end
	else
		case(ith_cycle)
			0:begin
				compare1 = iot_out[127:120];
				compare2 = iot_in;
				adder1   = iot_out[127:120];
				if(hold)
					adder2 = 0;
				else
					adder2   = iot_in;
				cin      = cin_1;
			end
			1:begin 
				compare1 = iot_out[119:112];
				compare2 = iot_in;
				adder1   = iot_out[119:112];
				if(hold)
					adder2 = 0;
				else
					adder2   = iot_in;
				cin      = cin_2;
			end
			2:begin 
				compare1 = iot_out[111:104];
				compare2 = iot_in;
				adder1   = iot_out[111:104];
				if(hold)
					adder2 = 0;
				else
					adder2   = iot_in;
				cin      = cin_3;
			end
			3:begin 
				compare1 = iot_out[103:96];
				compare2 = iot_in;
				adder1   = iot_out[103:96];
				if(hold)
					adder2 = 0;
				else
					adder2   = iot_in;
				cin      = cin_4;
			end
			4:begin 
				compare1 = iot_out[95:88];
				compare2 = iot_in;
				adder1   = iot_out[95:88];
				if(hold)
					adder2 = 0;
				else
					adder2   = iot_in;
				cin      = cin_5;
			end
			5:begin 
				compare1 = iot_out[87:80];
				compare2 = iot_in;
				adder1   = iot_out[87:80];
				if(hold)
					adder2 = 0;
				else
					adder2   = iot_in;
				cin      = cin_6;
			end
			6:begin 
				compare1 = iot_out[79:72];
				compare2 = iot_in;
				adder1   = iot_out[79:72];
				if(hold)
					adder2 = 0;
				else
					adder2   = iot_in;
				cin      = cin_7;
			end
			7:begin 
				compare1 = iot_out[71:64];
				compare2 = iot_in;
				adder1   = iot_out[71:64];
				if(hold)
					adder2 = 0;
				else
					adder2   = iot_in;
				cin      = cin_8;
			end
			8:begin
				compare1 = iot_out[63:56];
				compare2 = iot_in;
				adder1   = iot_out[63:56];
				if(hold)
					adder2 = 0;
				else
					adder2   = iot_in;
				cin      = cin_9;
			end
			9:begin
				compare1 = iot_out[55:48];
				compare2 = iot_in;
				adder1   = iot_out[55:48];
				if(hold)
					adder2 = 0;
				else
					adder2   = iot_in;
				cin      = cin_10;
			end
			10:begin
				compare1 = iot_out[47:40];
				compare2 = iot_in;
				adder1   = iot_out[47:40];
				if(hold)
					adder2 = 0;
				else
					adder2   = iot_in;
				cin      = cin_11;
			end
			11:begin
				compare1 = iot_out[39:32];
				compare2 = iot_in;
				adder1   = iot_out[39:32];
				if(hold)
					adder2 = 0;
				else
					adder2   = iot_in;
				cin      = cin_12;
			end
			12:begin
				compare1 = iot_out[31:24];
				compare2 = iot_in;
				adder1   = iot_out[31:24];
				if(hold)
					adder2 = 0;
				else
					adder2   = iot_in;
				cin      = cin_13;
			end
			13:begin
				compare1 = iot_out[23:16];
				compare2 = iot_in;
				adder1   = iot_out[23:16];
				if(hold)
					adder2 = 0;
				else
					adder2   = iot_in;
				cin      = cin_14;
			end
			14:begin
				compare1 = iot_out[15:8];
				compare2 = iot_in;
				adder1   = iot_out[15:8];
				if(hold)
					adder2 = 0;
				else
					adder2   = iot_in;
				cin      = cin_15;
			end
			15:begin
				compare1 = iot_out[7:0];
				compare2 = iot_in;
				adder1   = iot_out[7:0];
				
				adder2   = iot_in;
				cin      = 0;
			end
		endcase
end

always@(posedge clk)begin
	f1_ret <= 0;
	f2_ret <= 0;
	f3_ret <= 0;
	f4_ret <= 0;
	f5_ret <= 0;
	f6_ret <= 0;
	f7_ret <= 0;
	
	ith_cycle <= 0;
	if(rst)begin
		dataset_num <= 0;
		peak_change <= 0;
		
	end
	else 
		case(state)
			GETDATA:begin
				if(in_en)
					ith_cycle <= ith_cycle + 1;
				else
					ith_cycle <= ith_cycle;
				if(ith_cycle == 15)begin
					dataset_num <= dataset_num + 1;
					f4_ret <= extractable;
					f5_ret <= excludeable;
				end
				else	
					dataset_num <= dataset_num;
				
			end
			Fun1, Fun2 ,Fun4, Fun5:begin
				if(dataset_num[2:0] == 7 && ith_cycle == 15)begin
					f1_ret <= 1;
					f2_ret <= 1;
					f4_ret <= extractable;
					f5_ret <= excludeable;
					dataset_num <= dataset_num + 1;
					
				end
				else if(ith_cycle == 15)begin
					dataset_num <= dataset_num + 1;
					f4_ret <= extractable;
					f5_ret <= excludeable;
					
				end	
				else begin
					dataset_num <= dataset_num;
				end
				ith_cycle <= ith_cycle + 1;
			end
			Fun3:begin
				
				if(ith_cycle == 15)begin
					if(dataset_num[2:0] == 7 && in_en)begin
						dataset_num <= dataset_num;
					end
					else if(dataset_num[2:0] == 7 && !in_en)begin
						f3_ret <= 1;
						dataset_num <= dataset_num + 1;
					end
					else
						dataset_num <= dataset_num + 1;
				end
				ith_cycle <= ith_cycle + 1;
			end
			Fun6, Fun7:begin
				if(dataset_num[2:0] == 7 && ith_cycle == 15)begin
					f6_ret <= peak_change;
					f7_ret <= peak_change;
					peak_change <= 0;
					dataset_num <= dataset_num + 1;
				end
				else if(shift == 1)
					peak_change <= 1;
				if(ith_cycle == 15)begin
					dataset_num <= dataset_num + 1;
				end	
				else begin
					dataset_num <= dataset_num;
				end
				ith_cycle <= ith_cycle + 1;
				
				
			end
			
		endcase
			
end
endmodule
