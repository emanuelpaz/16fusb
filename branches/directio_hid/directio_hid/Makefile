# 16FUSB - USB 1.1 implemetation for PIC16F628/628A
#
# Copyright (C) 2011-2012  Emanuel Paz <efspaz@gmail.com>
#
# This is free software, licensed under the terms of the GNU General
# Public License as published by the Free Software Foundation.
#

# Change it according to your system. Use '\' for Windows and '/' for Posix systems
/ = $(strip $(strip \))

# System command to delete files
CC = del

# Change this to your Mpasm Suite folder
MP = C:/Program\ Files/Microchip/MPASM\ Suite

# Compiler command. Make sure it's in your PATH
AS = MPASMWIN.exe

# Linker command. Make sure it's in your PATH
LD = mplink.exe

#16FUSB core location
16FUSB = ..$/16fusb


16FUSB.cof : func.o isr.o usb.o stdreq.o out.o main.o setup.o
	$(LD) /p16F628 "func.o" "isr.o" "usb.o" "stdreq.o" "out.o" "main.o" "setup.o" /u_DEBUG /z__MPLAB_BUILD=1 /z__MPLAB_DEBUG=1 /m"16FUSB.map" /w /o"16FUSB.cof"

func.o : $(16FUSB)$/func.asm def.inc $(MP)$/P16F628.INC $(16FUSB)$/def.inc 
	$(AS) /q /p16F628 "$(16FUSB)$/func.asm" /l"func.lst" /e"func.err" /o"func.o" /d__DEBUG=1

isr.o : $(16FUSB)$/isr.asm def.inc $(MP)$/P16F628.INC $(16FUSB)$/def.inc 
	$(AS) /q /p16F628 "$(16FUSB)$/isr.asm" /l"isr.lst" /e"isr.err" /o"isr.o" /d__DEBUG=1

usb.o : $(16FUSB)$/usb.asm def.inc $(MP)$/P16F628.INC $(16FUSB)$/def.inc 
	$(AS) /q /p16F628 "$(16FUSB)$/usb.asm" /l"usb.lst" /e"usb.err" /o"usb.o" /d__DEBUG=1

stdreq.o : $(16FUSB)$/stdreq.asm def.inc $(MP)$/P16F628.INC $(16FUSB)$/def.inc 
	$(AS) /q /p16F628 "$(16FUSB)$/stdreq.asm" /l"stdreq.lst" /e"stdreq.err" /o"stdreq.o" /d__DEBUG=1

out.o : out.asm def.inc $(MP)$/P16F628.INC $(16FUSB)$/def.inc 
	$(AS) /q /p16F628 "out.asm" /l"out.lst" /e"out.err" /o"out.o" /d__DEBUG=1

main.o : main.asm def.inc $(MP)$/P16F628.INC $(16FUSB)$/def.inc 
	$(AS) /q /p16F628 "main.asm" /l"main.lst" /e"main.err" /o"main.o" /d__DEBUG=1

setup.o : setup.asm def.inc rpt_desc.inc $(MP)$/P16F628.INC $(16FUSB)$/def.inc 
	$(AS) /q /p16F628 "setup.asm" /l"setup.lst" /e"setup.err" /o"setup.o" /d__DEBUG=1

clean :
	$(CC) "func.o" "func.err" "func.lst" "isr.o" "isr.err" "isr.lst" "usb.o" "usb.err" "usb.lst" "stdreq.o" "stdreq.err" "stdreq.lst" "out.o" "out.err" "out.lst" "main.o" "main.err" "main.lst" "setup.o" "setup.err" "setup.lst" "16FUSB.cof" "16FUSB.hex" "16FUSB.map"

