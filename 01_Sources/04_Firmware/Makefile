#
#
#
#

CC = /opt/riscv32i/bin/riscv32-unknown-elf-gcc
LD = /opt/riscv32i/bin/riscv32-unknown-elf-ld
OBJDUMP = /opt/riscv32i/bin/riscv32-unknown-elf-objdump
OBJCOPY = /opt/riscv32i/bin/riscv32-unknown-elf-objcopy
INC = -I.
OPTS = -Os -march=rv32im -g
LD_OPTS_BOOTLOADER = -T sections_boot.lds -nostdlib
LD_OPTS = -T sections.lds -nostdlib
PYTHON = python3


all: firmware.elf user_app.elf

firmware.elf: firmware_start.o firmware_irq.o firmware.o print.o
	$(LD) $(LD_OPTS_BOOTLOADER) firmware_start.o firmware_irq.o print.o firmware.o -o firmware.elf
	$(OBJCOPY) -O binary firmware.elf firmware.bin
	$(OBJDUMP) -d firmware.elf >firmware.s.txt
	$(PYTHON) makehex.py firmware.bin 4096 . > firmware.mif
	

firmware.o: firmware.c firmware.h
	$(CC) $(OPTS) $(INC) firmware.c -c

print.o: print.c firmware.h
	$(CC) $(OPTS) $(INC) print.c -c

firmware_irq.o: firmware_irq.c firmware.h
	$(CC) $(OPTS) $(INC) firmware_irq.c -c

firmware_start.o: firmware_start.S
	$(CC) $(OPTS) $(INC) firmware_start.S -c
    
clean:
	rm *.hex *.o *.elf

user_app.elf: start.o user_app.o print.o
	$(LD) $(LD_OPTS) start.o print.o user_app.o -o user_app.elf
	$(OBJCOPY) -O ihex user_app.elf user_app.hex
	$(OBJDUMP) -d user_app.elf >user_app.s.txt

