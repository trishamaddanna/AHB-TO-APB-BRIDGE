AHB_slave_interface( input hclk, hresetn, hwrite, hreadyin, input [1:0] htrans, input [31:0] haddr, hwdata, output [1:0] hresp, output reg valid, output [31:0] hrdata, output reg [31:0] haddr1, haddr2, output reg [31:0] hwdata1, hwdata2, output hwritereg, output reg [2:0] tempselx 
); 
always @* 
  begin 
    if (hreadyin == 1'b1 && haddr >= 32'h8000_0000 && haddr < 32'h8C00_0000) 
      valid = 1'b1; 
    else valid = 1'b0; 
  end 
always @* 
  begin 
    tempselx = 3'b000; 
if (haddr >= 32'h8000_0000 && haddr < 32'h8400_0000) 
  tempselx = 3'b001; 
else if (haddr >= 32'h8400_000 && haddr < 32'h8800_0000) 
  tempselx = 3'b010; 
    else if (haddr >= 32'h8800_0000 && haddr < 32'h8C00_0000) 
      tempselx = 3'b100; 
    else tempselx = 3'b000; 
  end 
always @(posedge hclk) 
  begin 
    if (!hresetn) 
      begin 
        haddr1 <= 32'h0; haddr2 <= 32'h0; 
      end else 
        begin 
          haddr1 <= haddr; haddr2 <= haddr1; 
        end 
  end 
always @(posedge hclk) 
  begin 
    if (!hresetn) 
      begin 
        hwdata1 <= 32'h0; hwdata2 <= 32'h0; 
      end else 
        begin hwdata1 <= hwdata; hwdata2 <= hwdata1; 
        end 
  end 
endmodule 
