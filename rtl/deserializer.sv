module deserializer #(
  // This module will collect serial data
  // of data bus size and put it in parallel
  // form with first came bit as MSB
  parameter DATA_BUS_WIDTH = 16
)(
  input  logic                        clk_i,
  input  logic                        srst_i,

  input  logic                        data_i,
  input  logic                        data_val_i,
  output logic [DATA_BUS_WIDTH - 1:0] deser_data_o,
  output logic                        deser_data_val_o
);

  localparam COUNTER_SIZE = $clog2(DATA_BUS_WIDTH) + 1;

  logic [COUNTER_SIZE - 1:0]   counter;
  logic [DATA_BUS_WIDTH - 1:0] data_buf;

  always_ff @( posedge clk_i )
    begin
      if ( data_val_i )
        data_buf[DATA_BUS_WIDTH - 1 - counter] <= data_i;
    end

  always_ff @( posedge clk_i )
    begin
      if ( srst_i )
        counter <= '0;
      else if ( data_val_i && counter == DATA_BUS_WIDTH - 1 )
        counter <= '0;
      else if ( data_val_i )
        counter <= counter + (COUNTER_SIZE)'(1); 
    end

  always_ff @( posedge clk_i )
    begin
      if ( srst_i )
        deser_data_val_o <= 1'b0;
      else
        begin
          if ( data_val_i && counter == DATA_BUS_WIDTH - 1 )
            deser_data_val_o <= 1'b1;
          else 
            deser_data_val_o <= 1'b0;
        end
    end

  always_ff @( posedge clk_i )
    begin
      deser_data_o <= { data_buf[DATA_BUS_WIDTH - 1:1], data_i };
    end
endmodule