# Sigrok SUMP Protocol

This uses the SUMP protocol, as originally described (badly) [here](https://www.sump.org/projects/analyzer/protocol/). Since that description is very incomplete, I just implemented the protocol as expected by Sigrok. The Sigrok implementation is [here](https://sigrok.org/gitweb/?p=libsigrok.git;a=blob;f=src/hardware/openbench-logic-sniffer/protocol.c;h=7be70b3da30153ec50b4421531ef899c443505be;hb=HEAD).

## Overview

All communication is done over a standard serial port. The ICE40 dev board has an FTDI chip that can go up to 921600 Baud (around 100 kB/s. Not particularly fast, however most signals are very repetitive so SUMP uses Run-Length Encoding (RLE) to compress the data.

The only data the device sends to the host is the actual samples in 4-byte blocks (except for the CMD_ID command). The only data the host sends to the device is commands, with no feedback.

Commands are either short or long. A short command is 1 byte, a long command is 5 bytes - a single byte command code and 4 bytes of data. Long commands have the upper bit of their command byte set.

## Acquisition

Sigrok performs acquisition by first setting the channel mask - i.e. which channels is the trigger enabled for. Then it configures the triggers. There are up to 4 trigger "stages". Each stage must match before the next one, and when the final stage matches the trigger actually triggers.

Next it configures the sample rate, the capture size (e.g. 10000 samples), and the trigger delay (e.g. record 200 samples before the trigger).

It sets some flags: RLE encoding, Demux (?), Filter (?).

It enables/disables the channels.

Finally it sends the run command and receives the data.

## Commands

Some commands are extensions for the Pipistrello code [as described here](http://pipistrello.saanlima.com/index.php?title=Pipistrello_as_Logic_Analyzer)

### CMD_RESET (0x00)

This is a short command, sent 5 times in case the device is in the middle of receiving a long command.

Sigrok sends a reset command, and then reconfigures everything before each acquisition.

### CMD_RUN (0x01)

This is a short command which instructs the device to wait for the trigger using its current settings and when has finished getting the data it sends it all to the device.

### CMD_ID (0x02)

This is sent and the device responds with 4 bytes to identify the device. Sigrok checks for `1SLO` or `1ALS` which are apparently for "Pipistrello-OLS".

### CMD_TESTMODE (0x03)


### CMD_METADATA (0x04)

This retrieves a metadata structure. Support is optional - Sigrok uses defaults if the device ignores this command.

The structure is a list of 1-byte keys, and values, terminated by an 0x00 key. The upper 3 bits of the key determine the data type, and the lower 5 bits determine the meaning:

* 0 = Null-terminated string
  * 1 = Device name
  * 2 = FPGA firmware version
  * 3 = Ancillary version
* 1 = 32-bit unsigned integer (Big Endian!)
  * 0 = Number of usable channels.
  * 1 = Amount of sample memory available in bytes.
  * 2 = Amount of dynamic memory available in bytes. Sigrok does not know what this is and ignores it.
  * 3 = Maximum sample rate in Hertz.
  * 4 = Protocol version. Sigrok does not use this as far as I can see.
* 2 = 8-bit unsigned integer
  * 0 = Number of usable channels.
  * 1 = Protocol version.

Subsequent values with the same key override earlier ones.

### CMD_SET_DIVIDER (0x80)

This sets the sample clock divider. Only the first 3 bytes are used, and they are little endian. Also, the value used here is one less than the actual division. I.e. to get no clock division, use `0`. To divide the clock by 2, use `1`. To divide it by 3, use `2` and so on.

A big flaw in this protocol is that the clock rate is hardcoded at 100 MHz. 

### CMD_CAPTURE_SIZE (0x81)

If the number of samples to record is less than or equal to 256 * 1024, this command is used to set the sample length and trigger delay at the same time. The first two bytes set the read count, the next two set the trigger delay (both little endian). Note that both values have 1 subtracted and are measured in units of 4 samples, i.e.

| Param      | Read count | Trigger delay |
|------------|------------|---------------|
| 0x00000000 |          4 |             4 |
| 0x01000000 |          8 |             4 |
| 0x02001000 |         16 |             8 |
| 0x00012000 |       1028 |            16 |

### CMD_SET_FLAGS (0x82)

This sends a 16-bit little-endian value in the first two bytes to set the following flags:

    #define FLAG_DEMUX                 (1 << 0)

If the sample rate is higher than the clock rate (hardcoded at 100 MHz for the Openbench Logic Sniffer), Sigrok sets this. The code says this:

	* In demux mode the OLS is processing two 8-bit or 16-bit samples
	* in parallel and for this to work the lower two bits of the four
	* "channel_disable" bits must be replicated to the upper two bits.

I *think* it's something like using fewer channels to get a higher sample rate. Not sure though.

    #define FLAG_FILTER                (1 << 1)

Enable noise filter. Up to the device exactly what this does.

    #define FLAG_CHANNELGROUP_1        (1 << 2)
    #define FLAG_CHANNELGROUP_2        (1 << 3)
    #define FLAG_CHANNELGROUP_3        (1 << 4)
    #define FLAG_CHANNELGROUP_4        (1 << 5)

These enable or disable the 4 channel groups - 0-7, 8-15, 16-23 and 24-31. This affects how data is received. Note that this appears to be inverted from how you would expect: `1` means the channel group is disabled, `0` means it is enabled.

    #define FLAG_CLOCK_EXTERNAL        (1 << 6)

Enable external clock. Up to the device exactly what this does.

    #define FLAG_SLOPE_FALLING         (1 << 7)

`FLAG_SLOPE_FALLING` is unused by Sigrok

    #define FLAG_RLE                   (1 << 8)

Enable RLE compression. See the section on receiving data for details.

    #define FLAG_SWAP_CHANNELS         (1 << 9)

?

    #define FLAG_EXTERNAL_TEST_MODE    (1 << 10)

Source signal from an external test source. Up to the device exactly what this does.

    #define FLAG_INTERNAL_TEST_MODE    (1 << 11)

Source signal from an internal test source. Up to the device exactly what this does.

The code also says:

    /* 12-13 unused, 14-15 RLE mode (we hardcode mode 0). */


### CMD_CAPTURE_DELAYCOUNT (0x83) - Extension for Pipistrello

If the number of samples to record is greater than 256 * 1024 this command can be used instead of `CMD_CAPTURE_SIZE` to set the trigger delay. It is a 4-byte little endian value.

### CMD_CAPTURE_READCOUNT (0x84) - Extension for Pipistrello

If the number of samples to record is greater than 256 * 1024 this command can be used instead of `CMD_CAPTURE_SIZE` to set the sample length. It is a 4-byte little endian value.

### CMD_SET_TRIGGER_MASK (0xC0)

This is actually a set of 4 commands for the 4 trigger stages:

* CMD_SET_TRIGGER_MASK_0: 0xC0
* CMD_SET_TRIGGER_MASK_1: 0xC4
* CMD_SET_TRIGGER_MASK_2: 0xC8
* CMD_SET_TRIGGER_MASK_3: 0xCC

Each takes a 32-bit bitmask to determine which channels must match for this stage.

### CMD_SET_TRIGGER_VALUE (0xC1)

This is actually a set of 4 commands for the 4 trigger stages:

* CMD_SET_TRIGGER_VALUE_0: 0xC1
* CMD_SET_TRIGGER_VALUE_1: 0xC5
* CMD_SET_TRIGGER_VALUE_2: 0xC9
* CMD_SET_TRIGGER_VALUE_3: 0xCD

Each takes a 32-bit bitmask to determine which the value that the channel must match in this stage in order for the trigger to pass. If any value does not match, and its mask is enabled for this stage, then the trigger resets to stage 0.

### CMD_SET_TRIGGER_CONFIG (0xC2)

This is actually a set of 4 commands for the 4 trigger stages:

* CMD_SET_TRIGGER_CONFIG_0: 0xC2
* CMD_SET_TRIGGER_CONFIG_1: 0xC6
* CMD_SET_TRIGGER_CONFIG_2: 0xCA
* CMD_SET_TRIGGER_CONFIG_3: 0xCE

This configures which stage is the final one. Each stage is set to 0x0000SSTT where SS is the stage number (0-1) - I'm not sure why this is necessary - and TT is 0 for every stage execpt the final one where it is (0x08).

### CMD_SET_TRIGGER_EDGE (0xC3) - Extension for Pipistrello

This is actually a set of 4 commands for the 4 trigger stages:

* CMD_SET_TRIGGER_EDGE_0: 0xC3
* CMD_SET_TRIGGER_EDGE_1: 0xC7
* CMD_SET_TRIGGER_EDGE_2: 0xCB
* CMD_SET_TRIGGER_EDGE_3: 0xCF

This configures edge triggers. I'm not sure exactly how this works.

## Receiving Data

Once the `CMD_RUN` has been sent, we simply wait for our samples. Each sample consists of up to 4 bytes depending on how many channel groups you have enabled. If RLE encoding is used then the very upper bit of each sample is overwritten by a `count` flag. If `count` is set to 1 then it means repeat the previous sample N times, where N is the value of the rest of the sample.

Note that the samples are sent in reverse order. For example suppose you have channel groups 0 and 2 enabled and receive the following samples going forwards in time:

    0x0b45
    0x0b45
    0x0000
    0x0123
    0x0123
    0x0124

With RLE disabled the data would be sent as-is in reverse order:

    0x0124
    0x0123
    0x0123
    0x0000
    0x0b45
    0x0b45

With RLE enabled, "count" samples are added that repeat the *previous sample in time* or the *next sample in reception order*. I.e. in time:

    0x0b45
    0x1002 - Repeat previous sample twice.
    0x0000
    0x0123
    0x1002 - Repeat previous sample twice.
    0x0124

When transmitted:

    0x0124
    0x1002 - Repeat next sample twice.
    0x0123
    0x0000
    0x1002 - Repeat next sample twice.
    0x0b45
