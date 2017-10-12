#!/usr/bin/make
# makefile for the arduino due.
#
# USAGE: put this file in the same dir as your .ino file is.
# configure the PORT variable and ADIR at the top of the file
# to match your local configuration.
# Type make upload to compile and upload.
#
#
# LICENSE: GPLv2
#
#
# Based on makefile by Paul Dreik 20130503 http://www.pauldreik.se/
# https://github.com/pauldreik/arduino-due-makefile


#user specific settings:
#where to find the IDE
ADIR:=YOUR_PATH_HERE
#which serial port to use (add a file with SUBSYSTEMS=="usb", ATTRS{product}=="Arduino Due Prog. Port", ATTRS{idProduct}=="003d", ATTRS{idVendor}=="2341", SYMLINK+="arduino_due" in /etc/udev/rules.d/ to get this working). for windows, name the port where your arduino is, e.g. COM9
PORT:=COM5

#User src code
USR_INC:=inc
USR_SRC:=src

#then some general settings. They should not be necessary to modify.
GGC_PATH:=$(ADIR)/tools/arm-none-eabi-gcc/
CXX:=$(GGC_PATH)/bin/arm-none-eabi-g++
CC:=$(GGC_PATH)/bin/arm-none-eabi-gcc
C:=$(CC)
SAM:=hardware
CMSIS:=$(SAM)/system/CMSIS
LIBSAM:=$(SAM)/system/libsam
# for windows, we compile in an subdirectory of the current dir. oooh, always run from the same place...:
#TMPDIR:=$(PWD)/build
TMPDIR:=.\build
AR:=$(GGC_PATH)/bin/arm-none-eabi-ar
BOSSAC:=$(ADIR)\tools\progdue.bat


#all these values are hard coded and should maybe be configured somehow else,
#like olikraus does in his makefile.
DEFINES:=-Dprintf=iprintf -DF_CPU=84000000L -DARDUINO=152 -D__SAM3X8E__ -DUSB_PID=0x003e -DUSB_VID=0x2341 -DUSBCON

# where are included header files. we use the local directory for '#include "..."', while '#include <...> goes to the specified directories. The Arduino IDE include LIBSAM, but not  LIBSAM/Include saving a lot of trouble - udp.h from Atmel seems to be broken (it is nearly empty) thus leading to compile errors. by not including LIBSAM/Include the compiler finds the correct udp.h. thsu, we omit LIBSAM/Include as well.
INCLUDES:=-iquote.
INCLUDES+=-I$(USR_INC)
INCLUDES+=-I$(ADIR)/$(LIBSAM)
INCLUDES+=-I$(ADIR)/$(CMSIS)/CMSIS/Include/
INCLUDES+=-I$(ADIR)/$(CMSIS)/Device/ATMEL/
INCLUDES+=-I$(ADIR)/$(SAM)/cores/arduino
INCLUDES+=-I$(ADIR)/$(SAM)/variants/arduino_due_x
INCLUDES+=-I$(ADIR)/$(SAM)/libraries/SPI/src
INCLUDES+=-I$(ADIR)/$(SAM)/libraries/HID/src
INCLUDES+=-I$(ADIR)/$(SAM)/libraries/Wire/src
# INCLUDES+=-I$(ADIR)/$(SAM)/libraries/Ethernet
# INCLUDES+=-I$(ADIR)/$(SAM)/libraries/Ethernet/utility

#compilation flags common to both c and c++
# replace -w with -v if you want to get a talkative compiler
COMMON_FLAGS:=-g -Os -w -ffunction-sections -fdata-sections -nostdlib --param max-inline-insns-single=500 -mcpu=cortex-m3 -mthumb

CFLAGS:=$(COMMON_FLAGS)
CXXFLAGS:=$(COMMON_FLAGS) -fno-rtti -fno-exceptions

#let the results be named after the project
PROJNAME:=$(basename $(wildcard *.ino))

#we will make a new mainfile from the ino file.
NEWMAINFILE:=$(TMPDIR)\$(PROJNAME).ino.cpp

#our own sourcefiles is the (converted) ino file and any local cpp files
MYSRCFILES:=$(NEWMAINFILE) $(wildcard $(USR_SRC)/*.cpp)
# MYSRCFILES:=$(NEWMAINFILE) $(shell ls *.cpp 2>/dev/null)
MYOBJFILES:=$(addsuffix .o,$(addprefix $(TMPDIR)/,$(notdir $(MYSRCFILES))))

#These source files are the ones forming core.a
CORESRCXX:=$(wildcard $(ADIR)/$(SAM)/cores/arduino/*.cpp)
CORESRCXX+=$(wildcard $(ADIR)/$(SAM)/cores/arduino/USB/*.cpp)
CORESRCXX+=$(wildcard $(ADIR)/$(SAM)/libraries/SPI/src/*.cpp)
CORESRCXX+=$(wildcard $(ADIR)/$(SAM)/libraries/HID/src/*.cpp)
CORESRCXX+=$(wildcard $(ADIR)/$(SAM)/libraries/Wire/src/*.cpp)
# CORESRCXX+=$(wildcard $(ADIR)/$(SAM)/libraries/Ethernet/*.cpp)
# CORESRCXX+=$(wildcard $(ADIR)/$(SAM)/libraries/Ethernet/Utility/*.cpp)
CORESRCXX+=$(wildcard $(ADIR)/$(SAM)/variants/arduino_due_x/variant.cpp)
CORESRC:=$(wildcard $(ADIR)/$(SAM)/cores/arduino/*.c)

# CORESRCXX:=$(shell ls ${ADIR}/${SAM}/cores/arduino/*.cpp)
# CORESRCXX+=$(shell ls ${ADIR}/${SAM}/cores/arduino/USB/*.cpp)
# CORESRCXX+=$(shell ls ${ADIR}/${SAM}/libraries/SPI/*.cpp)
# CORESRCXX+=$(shell ls ${ADIR}/${SAM}/libraries/Ethernet/*.cpp)
# CORESRCXX+=$(shell ls ${ADIR}/${SAM}/libraries/Ethernet/Utility/*.cpp)
# CORESRCXX+=$(shell ls ${ADIR}/${SAM}/variants/arduino_due_x/variant.cpp)
# CORESRC:=$(shell ls ${ADIR}/${SAM}/cores/arduino/*.c)

#convert the core source files to object files. assume no clashes.
COREOBJSXX:=$(addprefix $(TMPDIR)/core/,$(notdir $(CORESRCXX)) )
COREOBJSXX:=$(addsuffix .o,$(COREOBJSXX))
COREOBJS:=$(addprefix $(TMPDIR)/core/,$(notdir $(CORESRC)) )
COREOBJS:=$(addsuffix .o,$(COREOBJS))

default:
	@echo default rule, does nothing. Try make compile or make upload.

#This rule is good to just make sure stuff compiles, without having to wait
#for bossac.
compile: $(TMPDIR)/$(PROJNAME).bin

#This is a make rule template to create object files from the source files.
# arg 1=src file
# arg 2=object file
# arg 3= XX if c++, empty if c
define OBJ_template
$(2): $(1)
	$(C$(3)) -MD -c $(C$(3)FLAGS) $(DEFINES) $(INCLUDES) $(1) -o $(2)
endef
#now invoke the template both for c++ sources
$(foreach src,$(CORESRCXX), $(eval $(call OBJ_template,$(src),$(addsuffix .o,$(addprefix $(TMPDIR)/core/,$(notdir $(src)))),XX) ) )
#...and for c sources:
$(foreach src,$(CORESRC), $(eval $(call OBJ_template,$(src),$(addsuffix .o,$(addprefix $(TMPDIR)/core/,$(notdir $(src)))),) ) )

#and our own c++ sources
$(foreach src,$(MYSRCFILES), $(eval $(call OBJ_template,$(src),$(addsuffix .o,$(addprefix $(TMPDIR)/,$(notdir $(src)))),XX) ) )


clean:
	del /Q $(TMPDIR)\core $(TMPDIR)\*.*

.PHONY: upload default

$(TMPDIR):
	mkdir $(TMPDIR)

$(TMPDIR)/core:
	mkdir $(TMPDIR)\core

#creates the cpp file from the .ino file
$(NEWMAINFILE): $(PROJNAME).ino
	echo extern "C" void __cxa_pure_virtual() {while (true);} > $(TMPDIR)\temp.txt
	copy /B /Y $(ADIR)\$(SAM)\cores\arduino\main.cpp + $(PROJNAME).ino + $(TMPDIR)\temp.txt $(NEWMAINFILE)

#include the dependencies for our own files
-include $(MYOBJFILES:.o=.d)

#create the core library from the core objects. Do this EXACTLY as the
#arduino IDE does it, seems *really* picky about this.
#Sorry for the hard coding.
$(TMPDIR)/core.a: $(TMPDIR)/core $(COREOBJS) $(COREOBJSXX)
	$(AR) rcs $(TMPDIR)/core.a $(TMPDIR)/core/wiring_shift.c.o
	$(AR) rcs $(TMPDIR)/core.a $(TMPDIR)/core/wiring_analog.c.o
	$(AR) rcs $(TMPDIR)/core.a $(TMPDIR)/core/itoa.c.o
	$(AR) rcs $(TMPDIR)/core.a $(TMPDIR)/core/cortex_handlers.c.o
	$(AR) rcs $(TMPDIR)/core.a $(TMPDIR)/core/hooks.c.o
	$(AR) rcs $(TMPDIR)/core.a $(TMPDIR)/core/wiring.c.o
	$(AR) rcs $(TMPDIR)/core.a $(TMPDIR)/core/WInterrupts.c.o
	$(AR) rcs $(TMPDIR)/core.a $(TMPDIR)/core/syscalls_sam3.c.o
	$(AR) rcs $(TMPDIR)/core.a $(TMPDIR)/core/iar_calls_sam3.c.o
	$(AR) rcs $(TMPDIR)/core.a $(TMPDIR)/core/wiring_digital.c.o
	$(AR) rcs $(TMPDIR)/core.a $(TMPDIR)/core/Print.cpp.o
	$(AR) rcs $(TMPDIR)/core.a $(TMPDIR)/core/USARTClass.cpp.o
	$(AR) rcs $(TMPDIR)/core.a $(TMPDIR)/core/WString.cpp.o
	$(AR) rcs $(TMPDIR)/core.a $(TMPDIR)/core/USBCore.cpp.o
	$(AR) rcs $(TMPDIR)/core.a $(TMPDIR)/core/CDC.cpp.o
	$(AR) rcs $(TMPDIR)/core.a $(TMPDIR)/core/HID.cpp.o
	$(AR) rcs $(TMPDIR)/core.a $(TMPDIR)/core/wiring_pulse.cpp.o
	$(AR) rcs $(TMPDIR)/core.a $(TMPDIR)/core/UARTClass.cpp.o
	$(AR) rcs $(TMPDIR)/core.a $(TMPDIR)/core/main.cpp.o
	$(AR) rcs $(TMPDIR)/core.a $(TMPDIR)/core/abi.cpp.o
	$(AR) rcs $(TMPDIR)/core.a $(TMPDIR)/core/Stream.cpp.o
	$(AR) rcs $(TMPDIR)/core.a $(TMPDIR)/core/RingBuffer.cpp.o
	$(AR) rcs $(TMPDIR)/core.a $(TMPDIR)/core/IPAddress.cpp.o
	$(AR) rcs $(TMPDIR)/core.a $(TMPDIR)/core/Reset.cpp.o
	$(AR) rcs $(TMPDIR)/core.a $(TMPDIR)/core/WMath.cpp.o
	$(AR) rcs $(TMPDIR)/core.a $(TMPDIR)/core/variant.cpp.o
	$(AR) rcs $(TMPDIR)/core.a $(TMPDIR)/core/SPI.cpp.o

#link our own object files with core to form the elf file
$(TMPDIR)/$(PROJNAME).elf: $(TMPDIR)/core.a $(TMPDIR)/core/syscalls_sam3.c.o $(MYOBJFILES)
	$(CXX) -Os -Wl,--gc-sections -mcpu=cortex-m3 -T$(ADIR)/$(SAM)/variants/arduino_due_x/linker_scripts/gcc/flash.ld -Wl,-Map,$(NEWMAINFILE).map -o $@ -L$(TMPDIR) -lm -lgcc -mthumb -Wl,--cref -Wl,--check-sections -Wl,--gc-sections -Wl,--entry=Reset_Handler -Wl,--unresolved-symbols=report-all -Wl,--warn-common -Wl,--warn-section-align -Wl,--warn-unresolved-symbols -Wl,--start-group $(TMPDIR)/core/syscalls_sam3.c.o $(MYOBJFILES) $(ADIR)/$(SAM)/variants/arduino_due_x/libsam_sam3x8e_gcc_rel.a $(TMPDIR)/core.a -Wl,--end-group

#copy from the hex to our bin file (why?)
$(TMPDIR)/$(PROJNAME).bin: $(TMPDIR)/$(PROJNAME).elf
	$(GGC_PATH)/bin/arm-none-eabi-objcopy -O binary $< $@

#upload to the arduino by first resetting it (stty) and the running bossac
upload: $(TMPDIR)/$(PROJNAME).bin
	$(BOSSAC) -p $(PORT) -U false -e -w -b $(TMPDIR)\$(PROJNAME).bin -R
