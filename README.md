# ssd1351-spin 
--------------

This is a P8X32A/Propeller, P2X8C4M64P/Propeller 2 driver object for Solomon Systech SSD1351-based OLED displays

## Salient Features

* SPI connection at 20MHz (P1), ~6.5MHz (P2). 4-wire SPI: DIN, CLK, CS, DC, and RESET)
* Integration with the generic bitmap graphics library
* Display mirroring
* Control display visibility (independent of display RAM contents)
* Set subpixel order
* Set color depth (16, 18-bit can be set; currently only 16-bit supported by driver)

## Requirements

* P1/SPIN1: 1 extra core/cog for the PASM SPI driver
* P2/SPIN2: N/A

## Compiler Compatibility

* P1/SPIN1: OpenSpin (tested with 1.00.81)
* P2/SPIN2: FastSpin (tested with 4.1.0-beta)

## Limitations

* Very early in development - may malfunction, or outright fail to build
* P1 has insufficient RAM to buffer the entire display
* Reading from display not currently supported

## TODO

- [ ] Add support for enhanced performance setting
- [x] Port to P2/SPIN2
- [x] Use the 20MHz SPI driver for the P1
- [ ] Add some direct-draw methods to the driver for apps that don't need a full buffered display
- [ ] Test external memory options with driver
