interface dff_int;
  logic clk;
  logic rst;
  logic in;
  logic out;
endinterface

class transaction;
  rand bit in;
  rand bit clk;
  rand bit rst;
  bit out;
  constraint oper_ctrl {  
    clk dist {1 :/ 50 , 0 :/ 50};  
    rst dist {1 :/ 50 , 0 :/ 50};
  }
endclass

class generator;
  transaction trans;
  mailbox gen2drv;
  function new(mailbox gen2drv);
    this.gen2drv=gen2drv;
  endfunction
  task run();
    for(int i=0;i<10;i++)
      begin
        trans=new();
        assert(trans.randomize())
          $display("[GEN] Value of CLK is %d RST is %d and IN is %d",trans.clk,trans.rst,trans.in);
        else
          $display("FAILED");
        gen2drv.put(trans);
        #10;
      end
  endtask
endclass

class driver;
  transaction trans;
  mailbox gen2drv;
  virtual dff_int dint;
  function new(mailbox gen2drv);
    this.gen2drv=gen2drv;
  endfunction
  
  task reset();
    dint.rst<=1;
    repeat(5) @(posedge dint.clk);
    dint.rst<=0;
    $display("RESET DONE");
  endtask
      
      
  
  
  task run();
    forever
      begin
        gen2drv.get(trans);
        dint.in<=trans.in;
        dint.clk<=trans.clk;
        dint.rst<=trans.rst;
        $display("[DRV] VALUES OF CLK IS %d RST IS %d AND IN IS %d",trans.clk,trans.rst,trans.in);
        #10;
      end
  endtask
  
endclass
    
class monitor;
  transaction trans;
  mailbox mon2scb;
  virtual dff_int dint;
  function new(mailbox mon2scb);
    this.mon2scb=mon2scb;
  endfunction
  
  task run();
    trans=new();
    repeat(10)
      begin
        trans.out<=dint.out;
        $display("[MON] DATA RECIEVED IS %d",dint.out);
        mon2scb.put(trans);
        #10;
      end
  endtask
endclass
    
class scoreboard;
  transaction trans;
  mailbox mon2scb;
  
  function new(mailbox mon2scb);
    this.mon2scb=mon2scb;
  endfunction
  
  task run();
    forever
      begin
        mon2scb.get(trans);
        if(trans.in==trans.out)
          $display("MATCHED");
        else
          $display("MISMATCHED");
      end
  endtask
endclass
     

module tb();
  generator gen;
  driver drv;
  monitor mon;
  scoreboard sco;
  mailbox gen2drv;
  mailbox mon2scb;
  dff_int dinterf();
  dff d(.rst(dinterf.rst),.clk(dinterf.clk),.in(dinterf.in),.out(dinterf.out));
  
  initial
    begin
      dinterf.clk<=0;
    end
  always
    #5 dinterf.clk<=~dinterf.clk;
  
  initial
    begin
      gen2drv=new();
      mon2scb=new();
      
      gen=new(gen2drv);
      drv=new(gen2drv);
      mon=new(mon2scb);
      sco=new(mon2scb);
      drv.dint=dinterf;
      mon.dint=dinterf;
      fork
        drv.reset();
        #5 gen.run();
        #5 drv.run();
        #10 mon.run();
        #10 sco.run();
      join
    end
endmodule
