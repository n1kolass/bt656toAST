//START_MODULE_NAME------------------------------------------------------------
//
// Module Name     :  dcfifo
//
// Description     :  Dual Clocks FIFO
//
// Limitation      :
//
// Results expected:
//
//END_MODULE_NAME--------------------------------------------------------------

// BEGINNING OF MODULE
`timescale 1 ps / 1 ps

// MODULE DECLARATION
module dcfifo ( data, rdclk, wrclk, aclr, rdreq, wrreq,
                eccstatus, rdfull, wrfull, rdempty, wrempty, rdusedw, wrusedw, q);

// GLOBAL PARAMETER DECLARATION
    parameter lpm_width = 1;
    parameter lpm_widthu = 1;
    parameter lpm_numwords = 2;
    parameter delay_rdusedw = 1;
    parameter delay_wrusedw = 1;
    parameter rdsync_delaypipe = 0;
    parameter wrsync_delaypipe = 0;
    parameter intended_device_family = "Stratix";
    parameter lpm_showahead = "OFF";
    parameter underflow_checking = "ON";
    parameter overflow_checking = "ON";
    parameter clocks_are_synchronized = "FALSE";
    parameter use_eab = "ON";
    parameter add_ram_output_register = "OFF";
    //parameter lpm_hint = "USE_EAB=ON";
    parameter lpm_type = "dcfifo";
    parameter add_usedw_msb_bit = "OFF";
    parameter read_aclr_synch = "OFF";
    parameter write_aclr_synch = "OFF";
    parameter enable_ecc = "FALSE";

// LOCAL_PARAMETERS_BEGIN

    parameter add_width = 1;
    parameter ram_block_type = "AUTO";

// LOCAL_PARAMETERS_END

// INPUT PORT DECLARATION
    input [lpm_width-1:0] data;
    input rdclk;
    input wrclk;
    input aclr;
    input rdreq;
    input wrreq;

// OUTPUT PORT DECLARATION
    output rdfull;
    output wrfull;
    output rdempty;
    output wrempty;
    output [lpm_widthu-1:0] rdusedw;
    output [lpm_widthu-1:0] wrusedw;
    output [lpm_width-1:0] q;
    output [1:0] eccstatus;

// INTERNAL WIRE DECLARATION
    wire w_rdfull;
    wire w_wrfull;
    wire w_rdempty;
    wire w_wrempty;
    wire [lpm_widthu-1:0] w_rdusedw;
    wire [lpm_widthu-1:0] w_wrusedw;
    wire [lpm_width-1:0] w_q;

// INTERNAL TRI DECLARATION
    tri0 aclr;

    dcfifo_mixed_widths DCFIFO_MW (
        .data (data),
        .rdclk (rdclk),
        .wrclk (wrclk),
        .aclr (aclr),
        .rdreq (rdreq),
        .wrreq (wrreq),
        .rdfull (w_rdfull),
        .wrfull (w_wrfull),
        .rdempty (w_rdempty),
        .wrempty (w_wrempty),
        .rdusedw (w_rdusedw),
        .wrusedw (w_wrusedw),
        .q (w_q) );
    defparam
        DCFIFO_MW.lpm_width = lpm_width,
        DCFIFO_MW.lpm_widthu = lpm_widthu,
        DCFIFO_MW.lpm_width_r = lpm_width,
        DCFIFO_MW.lpm_widthu_r = lpm_widthu,
        DCFIFO_MW.lpm_numwords = lpm_numwords,
        DCFIFO_MW.delay_rdusedw = delay_rdusedw,
        DCFIFO_MW.delay_wrusedw = delay_wrusedw,
        DCFIFO_MW.rdsync_delaypipe = rdsync_delaypipe,
        DCFIFO_MW.wrsync_delaypipe = wrsync_delaypipe,
        DCFIFO_MW.intended_device_family = intended_device_family,
        DCFIFO_MW.lpm_showahead = lpm_showahead,
        DCFIFO_MW.underflow_checking = underflow_checking,
        DCFIFO_MW.overflow_checking = overflow_checking,
        DCFIFO_MW.clocks_are_synchronized = clocks_are_synchronized,
        DCFIFO_MW.use_eab = use_eab,
        DCFIFO_MW.add_ram_output_register = add_ram_output_register,
        DCFIFO_MW.add_width = add_width,
        DCFIFO_MW.ram_block_type = ram_block_type,
        DCFIFO_MW.add_usedw_msb_bit = add_usedw_msb_bit,
        DCFIFO_MW.read_aclr_synch = read_aclr_synch,
        DCFIFO_MW.write_aclr_synch = write_aclr_synch,
        DCFIFO_MW.lpm_hint = lpm_hint;

// CONTINOUS ASSIGNMENT
    assign  rdfull = w_rdfull;
    assign  wrfull = w_wrfull;
    assign rdempty = w_rdempty;
    assign wrempty = w_wrempty;
    assign rdusedw = w_rdusedw;
    assign wrusedw = w_wrusedw;
    assign       q = w_q;

// ECC status
    assign eccstatus = {2'b0};

endmodule // dcfifo
// END OF MODULE