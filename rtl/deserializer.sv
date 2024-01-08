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

  enum logic [1:0] { IDLE_S,
                     WORK_S,
                     DONE_S } state, next_state;

  logic [DATA_BUS_WIDTH - 1:0] data_buf;
  integer                      counter;
 
  always_ff @( posedge clk_i ) 
    begin
      if ( srst_i ) 
        state <= IDLE_S;
      else 
        state <= next_state;
    end

  always_comb 
    begin
      next_state = state;
      case ( state )
        IDLE_S: begin
          if ( data_val_i ) 
            next_state = WORK_S;
          else 
            next_state = IDLE_S;
        end

        WORK_S: begin
          if ( counter == 0 ) 
            next_state = DONE_S;
          else 
            next_state = WORK_S;
        end

        DONE_S: begin
          // new input data came at the same moment when we expose data
          if ( data_val_i )
            next_state = WORK_S;
          else
            next_state = IDLE_S;
        end

        default: begin
          next_state = IDLE_S;
        end
      endcase
    end

  always_ff @( posedge clk_i ) 
    begin
      if ( state == IDLE_S && data_val_i == 1'b0 || 
           counter == 0 )
        counter <= DATA_BUS_WIDTH - 1;
      else if ( data_val_i == 1 )
        counter <= counter - 4'b1;  
    end

  always_ff @( posedge clk_i )
    begin
      if ( data_val_i == 1'b1 && counter >= 0 && counter < DATA_BUS_WIDTH )
        data_buf[counter] <= data_i;
      else if ( state == IDLE_S )
        data_buf <= '0;
    end

  always_comb 
    begin
      deser_data_o     = '0;
      deser_data_val_o = 1'b0;
      case ( state )
        IDLE_S: begin
          deser_data_o     = '0;
          deser_data_val_o = 1'b0;
        end

        WORK_S: begin
          deser_data_val_o = 1'b0;
          deser_data_o     = '0;
        end

        DONE_S: begin
          deser_data_val_o = 1'b1;
          deser_data_o     = data_buf;
        end

        default: begin
          deser_data_o     = '0;
          deser_data_val_o = 1'b0;
        end
      endcase
    end

endmodule
