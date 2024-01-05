module top_tb;

  parameter NUMBER_OF_TEST_RUNS = 1000;
  parameter DATA_BUS_WIDTH      = 16;

  bit                          clk;
  logic                        srst;
  bit                          srst_done;

  logic                        data;
  logic                        data_val;

  logic [DATA_BUS_WIDTH - 1:0] deser_data;
  logic                        deser_data_val;

  // flag to indicate if there is an error
  bit test_succeed;

  initial forever #5 clk = !clk;

  default clocking cb @( posedge clk );
  endclocking

  initial 
    begin
      srst <= 1'b0;
      ##1;
      srst <= 1'b1;
      ##1;
      srst <= 1'b0;
      srst_done = 1'b1;
    end

  deserializer #(
    .DATA_BUS_WIDTH ( DATA_BUS_WIDTH )
  ) DUT ( 
    .clk_i          ( clk            ),
    .srst_i         ( srst           ),
    .ser_data_o     ( ser_data       ),
    .ser_data_val_o ( ser_data_val   ),
    .busy_o         ( busy           ),
    .data_i         ( data           ),
    .data_val_i     ( data_val       ),
    .data_mod_i     ( data_mod       )
  );

  mailbox #( logic [DATA_BUS_WIDTH - 1:0]        ) input_data     = new(1);
  mailbox #( logic [DATA_BUS_WIDTH - 1:0]        ) output_data    = new(1);
  mailbox #( logic                               ) generated_data = new(DATA_BUS_WIDTH);
  mailbox #( logic [$clog(DATA_BUS_WIDTH) - 1:0] ) counter        = new(1);

  function void display_error( input logic [DATA_BUS_WIDTH - 1:0] in,  
                               input logic [DATA_BUS_WIDTH - 1:0] out,  
                               input int                          size
                             );
    for ( int i = 0; i < DATA_BUS_WIDTH - size; i++)
      in[i] = 0; // assign 0 to not valid bits
    $display( "expected values:%b, result value:%b", in, out);

  endfunction

  task raise_transaction_strobes( logic [DATA_BUS_WIDTH - 1:0] data_to_send,
                                  logic [$clog(DATA_BUS_WIDTH) - 1:0] counter
                                ); 
    
    // data comes at random moment
    int delay;
    delay = $urandom_range(10, 0);
    ##(delay);

    data     <= data_to_send[counter];
    data_val <= 1'b1;
    ## 1;
    data     <= '0;
    data_val <= '0; 

  endtask

  task compare_data( mailbox #( logic [DATA_BUS_WIDTH - 1:0]) input_data,
                     mailbox #( logic [DATA_BUS_WIDTH - 1:0]) output_data
                   );
    
    logic [DATA_BUS_WIDTH - 1:0] i_data, o_data;

    output_data.get( o_data );
    input_data.get( i_data );
    
    for ( int i = DATA_BUS_WIDTH; i > 0; i-- ) begin
      if ( i_data[i - 1] != o_data[i - 1] )
        begin
          display_error( i_data, o_data, tr_size );
          test_succeed <= 1'b0;
          return;
        end
    end
    
  endtask

  task generate_transaction ( mailbox #( logic [DATA_BUS_WIDTH - 1:0]) generated_data );
    
    logic [DATA_BUS_WIDTH - 1:0] data_to_send;

    data_to_send = $urandom_range( DATA_BUS_WIDTH**2 - 1, 'b1111111111 );

    generated_data.put(data_to_send);

  endtask

  task send_data ( mailbox #( logic [DATA_BUS_WIDTH - 1:0]) input_data,
                   mailbox #( logic [DATA_BUS_WIDTH - 1:0]) generated_data,
                   mailbox #( logic [DATA_MOD_WIDTH - 1:0]) counter
                 );

    logic [DATA_BUS_WIDTH - 1:0] data_to_send;
    
    for ( int i = 0; i < DATA_BUS_WIDTH; i++ ) begin
      generated_data.get( data_to_send );
      input_data.put( data_to_send );
      size.peek( size_to_send );

      raise_transaction_strobes( data_to_send, size_to_send );
      counter += 1;
    end

  endtask

  task read_data ( mailbox #( logic [DATA_BUS_WIDTH - 1:0]) output_data,
                   mailbox #( logic [DATA_MOD_WIDTH - 1:0]) size 
                 );
    
    logic [DATA_BUS_WIDTH - 1:0] recieved_data;
    logic [DATA_MOD_WIDTH - 1:0] tr_size;
    
    recieved_data <= '0;
    size.peek(tr_size);    
    
    @( posedge ser_data_val );
    for ( int i = 0; i < ( tr_size != 0? tr_size: DATA_BUS_WIDTH ); i++ ) begin
      @( posedge clk );
      recieved_data[DATA_BUS_WIDTH - 1 - i] = ser_data;
    end

    output_data.put(recieved_data);

  endtask

  task one_two_sizes_check;
    logic [DATA_BUS_WIDTH - 1:0] data_to_send;
    logic [DATA_MOD_WIDTH - 1:0] size_to_send;

    data_to_send = '1;  
    
    size_to_send = 1;
    raise_transaction_strobes( data_to_send, size_to_send );
    #10
    if ( ser_data_val == 1 )
      begin
        $display("Error occures! Transaction of size one activates DUT!");
        test_succeed <= 0;
      end
      
    size_to_send = 2;
    raise_transaction_strobes( data_to_send, size_to_send );
    #10
    if ( ser_data_val == 1 )
      begin
        $display("Error occures! Transaction of size two activates DUT!");
        test_succeed <= 0;
      end

  endtask

  initial begin
    test_succeed <= 1;

    $display("Simulation started!");
    wait( srst_done );

    repeat ( NUMBER_OF_TEST_RUNS )
    begin
      fork
        generate_transaction( generated_data, size );
        send_data( input_data, generated_data, size );
        read_data( output_data, size );
        compare_data( input_data, output_data, size );
      join
    end

    one_two_sizes_check();

    $display("Simulation is over!");
    if ( test_succeed )
      $display("All tests passed!");
    $stop();
  end



endmodule
