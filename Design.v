module dff(rst,clk,in,out);
  input clk,rst,in;
  output reg out;
  always@(posedge clk or negedge clk)
    begin
      if(rst)
        out<=0;
      else
        out<=in;
    end
endmodule
