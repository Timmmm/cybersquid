# OLS/SUMP-Compatible FPGA Logic Analyser

This project contains code to turn an iCEStick FPGA development board into a reasonable logic analyser that is compatible with Sigrok / PulseView. Communication is via RS232 which can run at up to 921600 Baud. Fairly slow, but RLE can be used to improve the transfer rate. In any case, continuous mode is not supported by SUMP.


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