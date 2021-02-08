# OLS/SUMP-Compatible FPGA Logic Analyser

This project contains code to turn an iCEStick FPGA development board into a reasonable logic analyser that is compatible with Sigrok / PulseView. Communication is via RS232 which can run at up to 921600 Baud. Fairly slow, but RLE can be used to improve the transfer rate. In any case, continuous mode is not supported by SUMP.

## Status

I mostly did this as a learning project. I got pretty far. It works, except for one bug where every other capture doesn't work for some reason. I have stopped working on it though for two reasons:

1. The OLS/SUMP protocol assumes a clock of 100 MHz which you can't achieve with the iCEStick dev board (closest you can get is 100.5 MHz). That kind of sucks.
2. You can get really cheap Salaea Logic clones that work really well. They're exactly the same as the official Salaea Logic which costs £300, but the one I bought only cost £9. They have a lower sample rate (only 24 MHz) but support continuous capture, which was much better for the use case I had in mind (capturing HDMI DDC/CI signals).

## Misc

Subfolder content:
1. source contains the demo source files 
2. impl contains the iCEcube project
3. constraint contains constraint file

How to regenerate bit file:
1. launch iCEcube
2. open project impl_sbt.project under \impl
3. run through the flow to generate bit file
4. the generated bit files are under \impl\impl_Implmnt\sbt\outputs\bitmap