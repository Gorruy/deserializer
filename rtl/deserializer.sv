module deserializer #(
  // This module will collect serial data
  // of data bus size and put it in parallel
  // form with first came bit as MSB
  parameter DATA_BUS_WIDTH = 16,
  parameter COUNTER_SIZE   = $clog2(DATA_BUS_WIDTH)
)(
  input  logic                        clk_i,
  input  logic                        srst_i,

  input  logic                        data_i,
  input  logic                        data_val_i,
  output logic [DATA_BUS_WIDTH - 1:0] deser_data_o,
  output logic                        deser_data_val_o
);

  logic [COUNTER_SIZE - 1:0]   counter;
  logic [DATA_BUS_WIDTH - 1:0] data_buf;
  logic                        done_flag;

  always_ff @( posedge clk_i )
    begin
      if ( srst_i )
        data_buf  <= '0;
      else if ( data_val_i )
        data_buf[counter] <= data_i;   
    end

  always_ff @( posedge clk_i )
    begin
      if ( srst_i )
        counter <= '1;
      else if ( data_val_i )
        counter <= counter - (COUNTER_SIZE)'(1);
    end

  always_ff @( posedge clk_i )
    begin
      if ( srst_i )
        begin
          deser_data_val_o <= 1'b0;
          deser_data_o     <= '0;
          done_flag        <= 1'b0;
        end
      else
        begin
          if ( done_flag )
            begin
              deser_data_val_o <= 1'b1;
              deser_data_o     <= data_buf;
              done_flag        <= 1'b0;
            end
          else if ( data_val_i && counter == (COUNTER_SIZE)'(0) )
            done_flag        <= 1'b1;
          else 
            begin
              deser_data_val_o <= 1'b0;
              deser_data_o     <= '0;
              done_flag        <= 1'b0;
            end
        end
    end
endmodule
