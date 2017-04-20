[ActiveSupport PAR]
; Global primary clocks
GLOBAL_PRIMARY_USED = 1;
; Global primary clock #0
GLOBAL_PRIMARY_0_SIGNALNAME = clk_c;
GLOBAL_PRIMARY_0_DRIVERTYPE = CLK_PIN;
GLOBAL_PRIMARY_0_LOADNUM = 550;
; # of global secondary clocks
GLOBAL_SECONDARY_USED = 8;
; Global secondary clock #0
GLOBAL_SECONDARY_0_SIGNALNAME = mem_rdata_0_sqmuxa;
GLOBAL_SECONDARY_0_DRIVERTYPE = SLICE;
GLOBAL_SECONDARY_0_LOADNUM = 24;
GLOBAL_SECONDARY_0_SIGTYPE = CE;
; Global secondary clock #1
GLOBAL_SECONDARY_1_SIGNALNAME = cpu/pcpi_insn4;
GLOBAL_SECONDARY_1_DRIVERTYPE = SLICE;
GLOBAL_SECONDARY_1_LOADNUM = 57;
GLOBAL_SECONDARY_1_SIGTYPE = CE+RST;
; Global secondary clock #2
GLOBAL_SECONDARY_2_SIGNALNAME = resetn_i;
GLOBAL_SECONDARY_2_DRIVERTYPE = SLICE;
GLOBAL_SECONDARY_2_LOADNUM = 59;
GLOBAL_SECONDARY_2_SIGTYPE = CE+RST;
; Global secondary clock #3
GLOBAL_SECONDARY_3_SIGNALNAME = cpu/cpu_state[5];
GLOBAL_SECONDARY_3_DRIVERTYPE = SLICE;
GLOBAL_SECONDARY_3_LOADNUM = 74;
GLOBAL_SECONDARY_3_SIGTYPE = CE;
; Global secondary clock #4
GLOBAL_SECONDARY_4_SIGNALNAME = cpu/N_2145_i;
GLOBAL_SECONDARY_4_DRIVERTYPE = SLICE;
GLOBAL_SECONDARY_4_LOADNUM = 21;
GLOBAL_SECONDARY_4_SIGTYPE = CE;
; Global secondary clock #5
GLOBAL_SECONDARY_5_SIGNALNAME = resetn_counter[7];
GLOBAL_SECONDARY_5_DRIVERTYPE = SLICE;
GLOBAL_SECONDARY_5_LOADNUM = 27;
GLOBAL_SECONDARY_5_SIGTYPE = RST;
; Global secondary clock #6
GLOBAL_SECONDARY_6_SIGNALNAME = cpu/un1_mem_la_firstword_reg9_1_i;
GLOBAL_SECONDARY_6_DRIVERTYPE = SLICE;
GLOBAL_SECONDARY_6_LOADNUM = 16;
GLOBAL_SECONDARY_6_SIGTYPE = CE;
; Global secondary clock #7
GLOBAL_SECONDARY_7_SIGNALNAME = cpu/N_1509_i;
GLOBAL_SECONDARY_7_DRIVERTYPE = SLICE;
GLOBAL_SECONDARY_7_LOADNUM = 50;
GLOBAL_SECONDARY_7_SIGTYPE = CE;
; I/O Bank 0 Usage
BANK_0_USED = 4;
BANK_0_AVAIL = 28;
BANK_0_VCCIO = 2.5V;
BANK_0_VREF1 = NA;
; I/O Bank 1 Usage
BANK_1_USED = 0;
BANK_1_AVAIL = 29;
BANK_1_VCCIO = NA;
BANK_1_VREF1 = NA;
; I/O Bank 2 Usage
BANK_2_USED = 5;
BANK_2_AVAIL = 29;
BANK_2_VCCIO = 2.5V;
BANK_2_VREF1 = NA;
; I/O Bank 3 Usage
BANK_3_USED = 0;
BANK_3_AVAIL = 9;
BANK_3_VCCIO = NA;
BANK_3_VREF1 = NA;
; I/O Bank 4 Usage
BANK_4_USED = 0;
BANK_4_AVAIL = 10;
BANK_4_VCCIO = NA;
BANK_4_VREF1 = NA;
; I/O Bank 5 Usage
BANK_5_USED = 0;
BANK_5_AVAIL = 10;
BANK_5_VCCIO = NA;
BANK_5_VREF1 = NA;
