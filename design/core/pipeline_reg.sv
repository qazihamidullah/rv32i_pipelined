
module pipeline_reg #(
  parameter   width = 32
) (
    clk, reset, in, out, en, flush
);
    input     logic                   clk           ;
    input     logic                   en            ;
    input     logic                   reset         ;
    input     logic                   flush         ;
    input     logic   [width-1:0]     in            ;
    output    logic   [width-1:0]     out           ;

    always_ff @(posedge clk or negedge reset) begin
      if(!reset)
        out <= 0;
      else if(flush)
        out <= 0;
      else if(en)
        out <= in;
    end 

endmodule