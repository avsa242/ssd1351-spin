# ssd1351-spin 
--------------

This is a P8X32A/Propeller, P2X8C4M64P/Propeller 2 driver object for Solomon Systech SSD1351-based OLED displays

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P). Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.

## Salient Features

* SPI connection at fixed 20MHz (P1), up to 20MHz (P2); 4-wire: DIN, CLK, CS, DC (and optionally RESET)
* Integration with the generic bitmap graphics library, as well as some support for unbuffered, direct-to-display operations
* Display mirroring
* Control display visibility (independent of display RAM contents)
* Set subpixel order
* Set color depth (16, 18-bit can be set; currently only 16-bit supported by driver)
* Set contrast/brightness
* Low-level display configuration settings: Precharge periods and levels, Oscillator freq and divider, logic levels


## Requirements

P1/SPIN1:
* spin-standard-library
* P1/SPIN1: 1 extra core/cog for the PASM SPI engine
* graphics.common.spinh (provided by spin-standard-library)

P2/SPIN2:
* p2-spin-standard-library
* graphics.common.spin2h (provided by p2-spin-standard-library)


## Compiler Compatibility

| Processor | Language | Compiler               | Backend      | Status                |
|-----------|----------|------------------------|--------------|-----------------------|
| P1        | SPIN1    | FlexSpin (6.8.0)       | Bytecode     | OK                    |
| P1        | SPIN1    | FlexSpin (6.8.0)       | Native/PASM  | OK                    |
| P2        | SPIN2    | FlexSpin (6.8.0)       | NuCode       | OK (Untested)         |
| P2        | SPIN2    | FlexSpin (6.8.0)       | Native/PASM2 | OK                    |

(other versions or toolchains not listed are __not supported__, and _may or may not_ work)


## Limitations

* Maximum display resolution is limited when using buffered mode with the P1 driver, due to memory usage (doesn't apply when built #defining `GFX_DIRECT`)
* Reading from display not currently supported

