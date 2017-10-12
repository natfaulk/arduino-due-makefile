# A makefile for the Arduino Due
A makefile for the Arduino Due to give more flexibility than the Arduino IDE. Based on the makefile by Paul Dreik at https://github.com/pauldreik/arduino-due-makefile but with removed dependencies on GNU utilities to make it more windows friendly.

## Required
- [GCC arm compiler](https://developer.arm.com/open-source/gnu-toolchain/gnu-rm)
- [Arduino due](https://github.com/arduino/ArduinoCore-sam)
- [Bossac](https://github.com/shumatech/BOSSA/releases)
- [Make](https://www.gnu.org/software/make/)

## To compile and upload
To compile only `make compile`
To compile and upload `make upload`

## TODO:
- test portability
- make cross platform
