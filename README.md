# ssd1351-spin 
--------------

This is a P8X32A/Propeller, P2X8C4M64P/Propeller 2 driver object for Solomon Systech SSD1351-based OLED displays

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P). Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.

## Salient Features

* SPI connection at 20MHz. 4-wire SPI: DIN, CLK, CS, DC (and optionally RESET)
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
* lib.gfx.bitmap.spin (provided by spin-standard-library)

P2/SPIN2:
* p2-spin-standard-library
* lib.gfx.bitmap.spin2 (provided by p2-spin-standard-library)

## Compiler Compatibility

| Processor | Language | Compiler               | Backend     | Status                |
|-----------|----------|------------------------|-------------|-----------------------|
| P1        | SPIN1    | FlexSpin (5.9.14-beta) | Bytecode    | OK                    |
| P1        | SPIN1    | FlexSpin (5.9.14-beta) | Native code | OK                    |
| P1        | SPIN1    | OpenSpin (1.00.81)     | Bytecode    | Untested (deprecated) |
| P2        | SPIN2    | FlexSpin (5.9.14-beta) | NuCode      | Untested              |
| P2        | SPIN2    | FlexSpin (5.9.14-beta) | Native code | OK                    |
| P1        | SPIN1    | Brad's Spin Tool (any) | Bytecode    | Unsupported           |
| P1, P2    | SPIN1, 2 | Propeller Tool (any)   | Bytecode    | Unsupported           |
| P1, P2    | SPIN1, 2 | PNut (any)             | Bytecode    | Unsupported           |

## Limitations

* P1 driver limited to less than maximum resolution when built using a display buffer, as it has insufficient RAM to buffer the entire display (doesn't apply when built #defining GFX_DIRECT)
* Reading from display not currently supported

