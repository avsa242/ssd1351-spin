{
    --------------------------------------------
    Filename: display.oled.ssd1351.spi.spin
    Author: Jesse Burt
    Description: Driver for Solomon Systech SSD1351 RGB OLED displays
    Copyright (c) 2020
    Started: Mar 11, 2020
    Updated: Mar 11, 2020
    See end of file for terms of use.
    --------------------------------------------
}
#define SSD1351
#include "lib.gfx.bitmap.spin"

CON

    _DISP_WIDTH     = 128
    _DISP_HEIGHT    = 64    '128
    _DISP_XMAX      = _DISP_WIDTH-1
    _DISP_YMAX      = _DISP_HEIGHT-1
    _BUFF_SZ        = _DISP_WIDTH * _DISP_HEIGHT * 2
    MAX_COLOR       = 65535

' Transaction type selection
    TRANS_CMD       = 0
    TRANS_DATA      = 1

' Display on/off modes
    OFF             = 0
    ON              = 1

' Color depth formats
    COLOR_65K       = %00   ' or %01
    COLOR_262K      = %10
    COLOR_262K65K2  = %11
' Address increment mode
    ADDR_HORIZ      = 0
    ADDR_VERT       = 1

' Subpixel order
    SUBPIX_RGB      = 0
    SUBPIX_BGR      = 1

' OLED command lock
    UNLOCK          = $12
    LOCK            = $16

OBJ

    core    : "core.con.ssd1351"
    time    : "time"
    spi     : "com.spi.fast"
    io      : "io"

VAR

    long _DC, _RES, _MOSI, _SCK, _CS
    long _draw_buffer
    byte _sh_SETCOLUMN, _sh_SETROW, _sh_SETCONTRAST_A, _sh_SETCONTRAST_B, _sh_SETCONTRAST_C
    byte _sh_MASTERCCTRL, _sh_SECPRECHG[3], _sh_REMAPCOLOR, _sh_DISPSTARTLINE, _sh_DISPOFFSET
    byte _sh_DISPMODE, _sh_MULTIPLEX, _sh_DIM, _sh_MASTERCFG, _sh_DISPONOFF, _sh_POWERSAVE
    byte _sh_PHASE12PER, _sh_CLK, _sh_GRAYTABLE, _sh_PRECHGLEV, _sh_VCOMH, _sh_CMDLOCK
    byte _sh_HVSCROLL, _sh_FILL

PUB Start (CS_PIN, DC_PIN, DIN_PIN, CLK_PIN, RES_PIN, drawbuffer_address): okay

    if lookdown(CS_PIN: 0..31)
        if lookdown(DC_PIN: 0..31)
            if lookdown(DIN_PIN: 0..31)
                if lookdown(CLK_PIN: 0..31)
                    if lookdown(RES_PIN: 0..31)
                        if okay := spi.start (CS_PIN, CLK_PIN, DIN_PIN, -1)
                            _DC := DC_PIN
                            _RES := RES_PIN
                            _MOSI := DIN_PIN
                            _SCK := CLK_PIN
                            _CS := CS_PIN
                            io.High(_DC)
                            io.Output(_DC)
                            io.High(_RES)
                            io.Output(_RES)
                            Reset
                            Powered(TRUE)
                            time.MSleep(300)
                            LockOLED(UNLOCK)
                            return okay
    return FALSE

PUB Stop

    AllPixelsOff
    Powered (FALSE)

PUB Address(addr)

    _draw_buffer := addr

PUB Defaults

    ColorDepth (COLOR_65K)
    MirrorH (FALSE)
    Powered (FALSE)
    AllPixelsOff
    StartLine (0)
    VertOffset (0)
    DispInverted (FALSE)
    DisplayLines (_DISP_HEIGHT)
    Phase1Adj (5)
    Phase2Adj (8)
    ClockFreq (3020)
    ClockDiv (2)
    PrechargeLevel (419)
    VCOMHDeselect (820)
    Contrast (127, 127, 127)
    Powered(TRUE)
    DisplayBounds (0, 0, _DISP_XMAX, _DISP_YMAX)

PUB AddrIncMode(mode) | tmp
' Set display addressing mode
'   Valid values:
'   ADDR_HORZ (0): Horizontal addressing mode
'   ADDR_VERT (1): Vertical addressing mode
    tmp := _sh_REMAPCOLOR
    case mode
        ADDR_HORIZ, ADDR_VERT:
        OTHER:
            return (tmp >> core#FLD_ADDRINC) & %1

    _sh_REMAPCOLOR &= core#MASK_SEGREMAP
    _sh_REMAPCOLOR := (_sh_REMAPCOLOR | mode) & core#SETREMAP_MASK
    writeReg (core#SETREMAP, 1, @_sh_REMAPCOLOR)

PUB AllPixelsOn | tmp
' Turn all pixels on
'   NOTE: Doesn't affect display's RAM contents
    writeReg (core#DISPLAYALLON, 0, 0)

PUB AllPixelsOff | tmp
' Turn all pixels off
'   NOTE: Doesn't affect display's RAM contents
    writeReg (core#DISPLAYALLOFF, 0, 0)

PUB ClearAccel
'

PUB ClockDiv(divider) | tmp
' Set display clock divider
'   Valid values: 1..1024:
'   Any other value returns the current setting
    tmp := _sh_CLK
    case divider
        1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024:
            divider -= 1
        OTHER:
            return 1 << (tmp & core#BITS_CLKDIV)

    _sh_CLK &= core#MASK_CLKDIV
    _sh_CLK := _sh_CLK | divider
    writeReg (core#CLOCKDIV, 1, @_sh_CLK)

PUB ClockFreq(freq) | tmp
' Set display clock frequency, in kHz
'   Valid values: 2500..3100, in steps of 40
'   Any other value returns the current setting
    tmp := _sh_CLK
    case freq
        2500..3100:
            freq := ((freq-2500) / 40) << core#FLD_FOSCFREQ
        OTHER:
            tmp := (tmp >> core#FLD_FOSCFREQ) & core#BITS_FOSCFREQ
            return (tmp * 40) + 2500

    _sh_CLK &= core#MASK_FOSCFREQ
    _sh_CLK := _sh_CLK | freq
    writeReg (core#CLOCKDIV, 1, @_sh_CLK)

PUB ColorDepth(format) | tmp
' Set expected color format of pixel data
'   Valid values:
'       COLOR_65K (0): 16-bit/65536 color format 1
'       COLOR_262K (1): 18-bits/262144 color format
'       COLOR_262K65K2 (2): 18-bit/262144 color format, 16-bit/65536 color format 2
'   Any other value returns the current setting
    tmp := _sh_REMAPCOLOR
    case format
        COLOR_65K, COLOR_262K, COLOR_262K65K2:
            format <<= core#FLD_COLORFORMAT
        OTHER:
            return tmp >> core#FLD_COLORFORMAT

    _sh_REMAPCOLOR &= core#MASK_COLORFORMAT
    _sh_REMAPCOLOR := _sh_REMAPCOLOR | format

    writeReg (core#SETREMAP, 1, @_sh_REMAPCOLOR)

PUB Contrast(a, b, c)
' Set contrast/brightness level of subpixels a, b, c
'   Valid values: 0..255
'   Any other value is ignored
    case a
        0..255:
        OTHER:
            return FALSE
    case b
        0..255:
        OTHER:
            return FALSE
    case c
        0..255:
        OTHER:
            return FALSE

    a.byte[0] := a
    a.byte[1] := b
    a.byte[2] := c 
    writeReg(core#SETCONTRASTABC, 3, @a)

PUB DisplayBounds(sx, sy, ex, ey) | tmp[2]
' Set drawable display region for subsequent drawing operations
'   Valid values:
'       sx, ex: 0..127
'       sy, ey: 0..127
'   Any other value will be ignored
    ifnot lookup(sx: 0..127) or lookup(sy: 0..127) or lookup(ex: 0..127) or lookup(ey: 0..127)
        return

    tmp.byte[0] := sx
    tmp.byte[1] := ex
    tmp.byte[2] := sy
    tmp.byte[3] := ey
    writeReg (core#SETCOLUMN, 2, @tmp)
    writeReg (core#SETROW, 2, @tmp.byte[2])

PUB DisplayLines(lines)
' Set maximum number of display lines
'   Valid values: 16..128
'   Any other value returns the current setting
    case lines
        16..128:
            lines -= 1
        OTHER:
            return FALSE

    writeReg (core#SETMUXRATIO, 1, @lines)

PUB DispInverted(enabled)
' Invert display colors
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value returns the current setting
    case ||enabled
        0, 1:
            enabled := lookupz(||enabled: core#NORMALDISPLAY, core#INVERTDISPLAY)
        OTHER:
            return FALSE

    writeReg (enabled, 0, 0)

PUB Interlaced(enabled) | tmp
' Alternate every other display line:
' Lines 0..31 will appear on even rows (starting on row 0)
' Lines 32..63 will appear on odd rows (starting on row 1)
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value returns the current setting
    tmp := _sh_REMAPCOLOR
    case ||enabled
        0, 1:
            enabled := (||enabled ^ 1) << core#FLD_COMSPLIT
        OTHER:
            return not (((tmp >> core#FLD_COMSPLIT) & %1) * TRUE)

    _sh_REMAPCOLOR &= core#MASK_COMSPLIT
    _sh_REMAPCOLOR := (_sh_REMAPCOLOR | enabled) & core#SETREMAP_MASK
    writeReg (core#SETREMAP, 1, @_sh_REMAPCOLOR)

PUB LockOLED(mode)

    case mode
        UNLOCK, LOCK:
        OTHER:
            return FALSE

    writeReg(core#SETLOCK, 1, @mode)

PUB MirrorH(enabled) | tmp
' Mirror the display, horizontally
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value returns the current setting
    tmp := _sh_REMAPCOLOR
    case ||enabled
        0, 1:
            enabled := (||enabled) << core#FLD_SEGREMAP
        OTHER:
            return ((tmp >> core#FLD_SEGREMAP) & %1) * TRUE

    _sh_REMAPCOLOR &= core#MASK_SEGREMAP
    _sh_REMAPCOLOR := (_sh_REMAPCOLOR | enabled) & core#SETREMAP_MASK
    writeReg (core#SETREMAP, 1, @_sh_REMAPCOLOR)

PUB MirrorV(enabled) | tmp
' Mirror the display, vertically
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value returns the current setting
    tmp := _sh_REMAPCOLOR
    case ||enabled
        0, 1:
            enabled := (||enabled) << core#FLD_COMREMAP
        OTHER:
            return ((tmp >> core#FLD_COMREMAP) & %1) * TRUE

    _sh_REMAPCOLOR &= core#MASK_COMREMAP
    _sh_REMAPCOLOR := (_sh_REMAPCOLOR | enabled) & core#SETREMAP_MASK
    writeReg (core#SETREMAP, 1, @_sh_REMAPCOLOR)

PUB Phase1Adj(clks) | tmp

    tmp := _sh_PHASE12PER
    case clks
        5..31:
            clks := lookdown(clks: 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31)
        OTHER:
            tmp &= core#BITS_PHASE1
            return lookup(tmp: 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31)

    _sh_PHASE12PER &= core#MASK_PHASE1
    _sh_PHASE12PER := (_sh_PHASE12PER | clks)
    writeReg (core#PRECHARGE, 1, @_sh_PHASE12PER)

PUB Phase2Adj(clks) | tmp

    tmp := _sh_PHASE12PER
    case clks
        3..15:
            clks <<= core#FLD_PHASE2
        OTHER:
            return (tmp >> core#FLD_PHASE2) & core#BITS_PHASE2

    _sh_PHASE12PER &= core#MASK_PHASE2
    _sh_PHASE12PER := (_sh_PHASE12PER | clks)
    writeReg (core#PRECHARGE, 1, @_sh_PHASE12PER)

PUB PlotAccel(x, y, rgb) | tmp[2]
' Plot a pixel at x, y in color rgb, using the display's native/accelerated method
    x := 0 #> x <# _disp_width-1
    y := 0 #> y <# _disp_height-1

    DisplayBounds(x, x, y, y)
    time.USleep (5)
    writeReg (core#WRITERAM, 2, @rgb)

PUB Powered(enabled) | tmp
' Enable display power
'   Valid values:
'       OFF/FALSE (0): Turn off display power
'       ON/TRUE (-1 or 1): Turn on display power
'   Any other value returns the current setting
    case ||enabled
        OFF, ON:
            enabled := lookupz(||enabled: core#DISPLAYOFF, core#DISPLAYON)
        OTHER:
            return FALSE

    writeReg (enabled, 0, 0)

PUB PrechargeLevel(mV) | tmp

    case mV
        200..600:
            mV := (mv-200) / 13
        OTHER:
            return FALSE

    writeReg (core#PRECHARGELEVEL, 1, @mV)

PUB SecPrechargePeriod(clocks) | tmp[2]

    case clocks
        1..15:
        OTHER:
            return FALSE

    writeReg (core#SETSECPRECHG, 1, @clocks)

PUB StartLine(disp_line)
' Set display start line
'   Valid values: 0..127
'   Any other value returns the current setting
    case disp_line
        0..127:
        OTHER:
            return FALSE

    writeReg (core#STARTLINE, 1, @disp_line)

PUB SubpixelOrder(order)
' Set subpixel color order
'   Valid values:
'       RGB (0): Red-Green-Blue order
'       BGR (1): Blue-Green-Red order
'   Any other value returns the current setting
    case order
        SUBPIX_RGB, SUBPIX_BGR:
            order <<= core#FLD_SUBPIX_ORDER
        OTHER:
            return (_sh_REMAPCOLOR >> core#FLD_SUBPIX_ORDER) & %1

    _sh_REMAPCOLOR &= core#MASK_SUBPIX_ORDER
    _sh_REMAPCOLOR := (_sh_REMAPCOLOR | order) & core#SETREMAP_MASK
    writeReg (core#SETREMAP, 1, @_sh_REMAPCOLOR)

PUB VCOMHDeselect(mV) | tmp
' Set voltage for COM deselect level, in millivolts
'   Valid values: 440, 520, 610, 710, 830
'   Any other value returns the current setting
    case mV
        720, 743, 767, 790, 813, 837, 860:
            mV := lookdown(mv: 720, 743, 767, 790, 813, 837, 860)
        OTHER:
            return FALSE

    writeReg (core#VCOMH, 1, @mv)

PUB VertOffset(disp_line)
' Set display vertical offset, in lines
'   Valid values: 0..63
'   Any other value is ignored
    case disp_line
        0..127:
        OTHER:
            return FALSE

    writeReg (core#DISPLAYOFFSET, 1, @disp_line)

PUB Reset
' Reset the display controller
    io.High(_RES)
    io.Low(_RES)
    time.USleep (2)
    io.High(_RES)

PUB Update
' Send the draw buffer to the display
    writeReg(core#WRITERAM, _buff_sz, _draw_buffer)

PRI writeReg(reg, nr_bytes, buff_addr) | tmp

    case reg
        $9E, $9F, $A4..$A7, $AD..$AF, $B0, $B9, $D1, $E3:                               ' Single-byte command
            io.Low(_DC)
            spi.Write(TRUE, @reg, 1, TRUE)
            return

        $15, $5C, $75, $96, $A0..$A2, $AB, $B1..$B6, $B8, $BB, $BE, $C1, $C7, $CA, $FD:     ' Multi-byte command
            io.Low(_DC)
            spi.Write(TRUE, @reg, 1, FALSE)
            io.High(_DC)
            spi.Write(TRUE, buff_addr, nr_bytes, TRUE)
            return

        OTHER:
            return

{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}
