module test;
  parameter DATA_WIDTH = 32;
  parameter ADDR_LEN = 10;

  reg                   CLK0;
  reg                   RST0;
  wire [DATA_WIDTH-1:0] Q;
  reg                   DEQ;
  wire                  EMPTY;
  wire                  ALM_EMPTY;
  
  reg                   CLK1;
  reg                   RST1;
  reg  [DATA_WIDTH-1:0] D;
  reg                   ENQ;
  wire                  FULL;
  wire                  ALM_FULL;
  
  BramFifo
  uut
   (CLK0, RST0, Q, DEQ, EMPTY, ALM_EMPTY,
    CLK1, RST1, D, ENQ,  FULL,  ALM_FULL);

  initial begin
    CLK0 = 0;
    forever #5 CLK0 = !CLK0;
  end
  
  initial begin
    CLK1 = 0;
    forever #10 CLK1 = !CLK1;
  end

  task n_CLK0;
    begin
      wait(~CLK0);
      wait(CLK0);
      #1;
    end
  endtask

  task n_CLK1;
    begin
      wait(~CLK1);
      wait(CLK1);
      #1;
    end
  endtask

  integer i;
  integer j;

  reg [DATA_WIDTH-1:0] sum_out;
  
  initial begin
    DEQ = 0;
    RST0 = 0;
    #100;
    RST0 = 1;
    #100;
    RST0 = 0;
    #100;

    for(i=0; i<1024*3; i=i+1) begin
      n_CLK0();
    end

    sum_out = 0;
    
    for(i=0; i<1024*16; i=i+1) begin
      if(DEQ) begin
        sum_out = sum_out + Q;
      end
      if(EMPTY) begin
        DEQ = 0;
      end else begin
        DEQ = 1;
      end
      n_CLK0();
    end
    
  end

  reg [DATA_WIDTH-1:0] sum_in;
  
  initial begin
    D = 0;
    ENQ = 0;
    RST1 = 0;
    #100;
    RST1 = 1;
    #100;
    RST1 = 0;
    #100;

    for(j=0; j<10; j=j+1) begin
      n_CLK1();
    end

    D = 0;
    sum_in = 0;
    
    for(j=0; j<1024*16; j=j+1) begin
      if(ALM_FULL) begin
        ENQ = 0;
      end else if(D >= 2**ADDR_LEN + 10) begin
        ENQ = 0;
      end else begin
        D = D + 1;
        ENQ = 1;
        sum_in = sum_in + D;
      end        
      n_CLK1();
    end
    
  end

  initial begin
    #100000;
    $display("sum_in=%d, sum_out=%d match?=%b", sum_in, sum_out, sum_in == sum_out);
    $finish;
  end

  always @(posedge CLK0) begin
    if(RST0) begin
    end else begin
      $display("Q:%x DEQ:%x EMPTY:%x ALM_EMPTY:%x", Q, DEQ, EMPTY, ALM_EMPTY);
    end
  end

  always @(posedge CLK1) begin
    if(RST1) begin
    end else begin
      $display("D:%x ENQ:%x  FULL:%x  ALM_FULL:%x", D, ENQ, FULL, ALM_FULL);
    end
  end

  initial begin
    $dumpfile("uut.vcd");
    $dumpvars(0, uut);
  end
  
endmodule

module BramFifo(CLK0, RST0, Q, DEQ, EMPTY, ALM_EMPTY,
                CLK1, RST1, D, ENQ,  FULL,  ALM_FULL);
  parameter ADDR_LEN = 10;
  parameter DATA_WIDTH = 32;
  localparam MEM_SIZE = 2 ** ADDR_LEN;

  input                   CLK0;
  input                   RST0;
  output [DATA_WIDTH-1:0] Q;
  input                   DEQ;
  output                  EMPTY;
  output                  ALM_EMPTY;
  
  input                   CLK1;
  input                   RST1;
  input  [DATA_WIDTH-1:0] D;
  input                   ENQ;
  output                  FULL;
  output                  ALM_FULL;

  reg EMPTY;
  reg ALM_EMPTY;
  reg FULL;
  reg ALM_FULL;

  reg [ADDR_LEN-1:0] head;
  reg [ADDR_LEN-1:0] tail;

  wire [ADDR_LEN-1:0] gray_head;
  wire [ADDR_LEN-1:0] gray_tail;

  reg [ADDR_LEN-1:0] d_gray_head;
  reg [ADDR_LEN-1:0] d_gray_tail;

  reg [ADDR_LEN-1:0] dd_gray_head;
  reg [ADDR_LEN-1:0] dd_gray_tail;

  function [ADDR_LEN-1:0] to_gray;
    input [ADDR_LEN-1:0] in;
    to_gray = in ^ (in >> 1);
  endfunction
  
  // Read Pointer
  always @(posedge CLK0) begin
    if(RST0) begin
      head <= 0;
    end else begin
      if(!EMPTY && DEQ) head <= head == (MEM_SIZE-1)? 0 : head + 1;
    end
  end

  // Write Pointer
  always @(posedge CLK1) begin
    if(RST1) begin
      tail <= 0;
    end else begin
      if(!FULL && ENQ) tail <= tail == (MEM_SIZE-1)? 0 : tail + 1;
    end
  end
  
  assign gray_head = to_gray(head);
  assign gray_tail = to_gray(tail);

  // Read Pointer (CLK0 -> CLK1)
  always @(posedge CLK1) begin
    d_gray_head <= gray_head;
    dd_gray_head <= d_gray_head;
  end
  
  // Write Pointer (CLK1 -> CLK0)
  always @(posedge CLK0) begin
    d_gray_tail <= gray_tail;
    dd_gray_tail <= d_gray_tail;
  end
  
  always @(posedge CLK0) begin
    if(DEQ && !EMPTY) begin
      EMPTY <= (dd_gray_tail == to_gray(head+1));
      ALM_EMPTY <= (dd_gray_tail == to_gray(head+2)) || (dd_gray_tail == to_gray(head+1));
    end else begin
      EMPTY <= (dd_gray_tail == to_gray(head));
      ALM_EMPTY <= (dd_gray_tail == to_gray(head+1)) || (dd_gray_tail == to_gray(head));
    end
  end

  always @(posedge CLK1) begin
    if(ENQ && !FULL) begin
      FULL <= (dd_gray_head == to_gray(tail+2));
      ALM_FULL <= (dd_gray_head == to_gray(tail+3)) || (dd_gray_head == to_gray(tail+2));
    end else begin
      FULL <= (dd_gray_head == to_gray(tail+1));
      ALM_FULL <= (dd_gray_head == to_gray(tail+2)) || (dd_gray_head == to_gray(tail+1));
    end
  end

  wire ram_we;
  assign ram_we = ENQ && !FULL;
  BRAM2 #(.W_A(ADDR_LEN), .W_D(DATA_WIDTH))
  ram (.CLK0(CLK0), .ADDR0(head), .D0('h0), .WE0(1'b0), .Q0(Q), // read
       .CLK1(CLK1), .ADDR1(tail), .D1(D), .WE1(ram_we), .Q1()); // write
  
endmodule

//------------------------------------------------------------------------------
// Dual-port BRAM
//------------------------------------------------------------------------------
module BRAM2(CLK0, ADDR0, D0, WE0, Q0, 
             CLK1, ADDR1, D1, WE1, Q1);
  parameter W_A = 10;
  parameter W_D = 32;
  localparam LEN = 2 ** W_A;
  input            CLK0;
  input  [W_A-1:0] ADDR0;
  input  [W_D-1:0] D0;
  input            WE0;
  output [W_D-1:0] Q0;
  input            CLK1;
  input  [W_A-1:0] ADDR1;
  input  [W_D-1:0] D1;
  input            WE1;
  output [W_D-1:0] Q1;
  
  reg [W_A-1:0] d_ADDR0;
  reg [W_A-1:0] d_ADDR1;
  reg [W_D-1:0] mem [0:LEN-1];
  
  always @(posedge CLK0) begin
    if(WE0) mem[ADDR0] <= D0;
    d_ADDR0 <= ADDR0;
  end
  always @(posedge CLK1) begin
    if(WE1) mem[ADDR1] <= D1;
    d_ADDR1 <= ADDR1;
  end
  assign Q0 = mem[d_ADDR0];
  assign Q1 = mem[d_ADDR1];
endmodule
