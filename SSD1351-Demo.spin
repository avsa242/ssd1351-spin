{
    --------------------------------------------
    Filename: SSD1351-Demo.spin
    Author: Jesse Burt
    Description: Simple demo of the SSD1351 driver
    Copyright (c) 2020
    Started Mar 11, 2020
    Updated Mar 11, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_CLKMODE
    _xinfreq    = cfg#_XINFREQ

    DIN         = 0
    CLK         = 1
    CS          = 2
    DC          = 3
    RESET       = 4

    LED         = cfg#LED1
    SER_RX      = 31
    SER_TX      = 30
    SER_BAUD    = 115_200

    WIDTH       = 128
    HEIGHT      = 64
    BPP         = 16
    BPL         = WIDTH * (BPP/8)
    BUFFSZ      = (WIDTH * HEIGHT) * 2  'in BYTEs
    XMAX        = WIDTH - 1
    YMAX        = HEIGHT - 1

    BT_FRAME    = 0
    BT_UNIT     = 1

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    io      : "io"
    display : "display.oled.ssd1351.spi.spin"
    int     : "string.integer"
    fnt     : "font.5x8"

VAR

    long _rndseed
    long _bench_iter, _bench_iter_stack[50]
    word _framebuff[BUFFSZ/2]
    byte _ser_cog, _display_cog, _bench_cog, _ser_row
    byte _bench_type

PUB Main

    _bench_iter := 0
    _ser_row := 3
    Setup

    Demo_Text(1024)
    time.Sleep(2)

    Demo_MEMScroller ($0000, $FFFF)
    time.Sleep(2)
    display.ClearAll

    Demo_Circle (100)
    time.Sleep (2)
    display.ClearAll

    Demo_Sine (500)
    time.Sleep (2)
    display.ClearAll

    Demo_LineBitmap (1_000)
    time.Sleep (2)
    display.ClearAll

    Demo_PlotBitmap (1000)
    time.Sleep (2)
    display.ClearAll

    Demo_BoxBitmap(250)
    time.Sleep (2)
    display.ClearAll

    Stop
    FlashLED (LED, 100)

PUB Demo_Text(reps) | r, fg, bg, ch, col, row, maxcol, maxrow
' Draw text with random foreground and background colors
    ser.str(string("Demo_Text"))
    ch := col := row := 0
    maxcol := display.TextCols-1
    maxrow := display.TextRows-1
    fg := cnt                                               ' Seed the color variables
    bg := cnt
    repeat r from 1 to reps
        display.FGColor(?fg)
        display.BGColor(?bg)
        display.Position(col, row)
        display.Char(ch)
        ch++
        if ch > fnt#LASTCHAR
            ch := 0
        col++
        if col > maxcol
            col := 0
            row++
        if row > maxrow
            row := 0
        display.Update
        _bench_iter++
    display.BGColor(0)

PUB Demo_Sine(reps) | r, x, y, modifier, offset, div
' Draw a sine wave the length of the screen, influenced by
'  the system counter
    ser.position(0, _ser_row++)
    ser.str(string("Demo_Sine"))
    div := 2048
    offset := YMAX/2                                        ' Offset for Y axis
    _bench_type := BT_FRAME

    repeat r from 1 to reps
        repeat x from 0 to XMAX
            modifier := (||cnt / 1_000_000)                 ' Use system counter as modifier
            y := offset + sin(x * modifier) / div
            display.Plot (x, y, $FF_FF)
        display.Update
        _bench_iter++
        display.Clear

PUB Demo_Bitmap(reps)
' Draw bitmap
    ser.position(0, _ser_row++)
    ser.str(string("Demo_Bitmap"))
    _bench_type := BT_FRAME
    repeat reps
        display.Bitmap (0, BUFFSZ, 0)
        display.Update
        _bench_iter++

PUB Demo_BoxBitmap(reps) | sx, sy, ex, ey, c
' Draw random filled boxes using the bitmap library's method
    ser.position(0, _ser_row++)
    ser.str(string("Demo_BoxBitmap"))
    _bench_type := BT_UNIT
    repeat reps
        sx := RND (XMAX)
        sy := RND (YMAX)
        ex := RND (XMAX)
        ey := RND (YMAX)
        c := (?_rndseed >> 26) << 11 | (?_rndseed >> 25) << 5 | (?_rndseed >> 26)
        display.Box (sx, sy, ex, ey, c, TRUE)
        display.Update
        _bench_iter++

PUB Demo_Circle(reps) | r, x, y, c
' Draws random circles
    ser.position(0, _ser_row++)
    ser.str(string("Demo_Circle"))
    _rndseed := cnt
    _bench_type := BT_FRAME
    repeat reps
        x := rnd(XMAX)
        y := rnd(YMAX)
        r := rnd(YMAX)
        c := (?_rndseed >> 26) << 11 | (?_rndseed >> 25) << 5 | (?_rndseed >> 26)
        display.Circle (x, y, r, c)
        display.Update
        _bench_iter++

PUB Demo_LineBitmap(reps) | sx, sy, ex, ey, c
' Draw random lines, using the bitmap library's method
    ser.position(0, _ser_row++)
    ser.str(string("Demo_LineBitmap"))
    _bench_type := BT_UNIT
    repeat reps
        sx := RND (XMAX)
        sy := RND (YMAX)
        ex := RND (XMAX)
        ey := RND (YMAX)
        c := (?_rndseed >> 26) << 11 | (?_rndseed >> 25) << 5 | (?_rndseed >> 26)
        display.Line (sx, sy, ex, ey, c)
        display.Update
        _bench_iter++

PUB Demo_MEMScroller(start_addr, end_addr) | pos, st, en
' Dump Propeller Hub RAM (or ROM) to the framebuffer
    ser.position(0, _ser_row++)
    ser.str(string("Demo_MEMScroller"))
    _bench_type := BT_FRAME
    repeat pos from start_addr to end_addr-BUFFSZ step BPL
        wordmove(@_framebuff, pos, BUFFSZ/2)
        display.Update
        _bench_iter++

PUB Demo_PlotBitmap(reps) | x, y, c
' Draw random pixels, using the bitmap library's method
    ser.position(0, _ser_row++)
    ser.str(string("Demo_PlotBitmap"))
    _bench_type := BT_UNIT
    repeat reps
        x := RND (XMAX)
        y := RND (YMAX)
        c := (?_rndseed >> 26) << 11 | (?_rndseed >> 25) << 5 | (?_rndseed >> 26)
        display.Plot(x, y, c)
        display.Update
        _bench_iter++

PUB FPS_mon
' Display to the serial terminal approximate render speed, in frames per second
    repeat
        time.MSleep (1000)
        ser.Position (20, _ser_row-1)
        ser.Str (string("FPS: "))
        ser.Str (int.DecZeroed (_bench_iter, 3))
        _bench_iter := 0

PUB RND(max_val) | i
' Returns a random number between 0 and max_val
    i := ?_rndseed
    i >>= 16
    i *= (max_val + 1)
    i >>= 16

    return i

PUB Sin(angle)
' Sin angle is 13-bit; Returns a 16-bit signed value
    result := angle << 1 & $FFE
    if angle & $800
       result := word[$F000 - result]
    else
       result := word[$E000 + result]
    if angle & $1000
       -result

PUB Setup

    repeat until _ser_cog := ser.StartRXTX (SER_RX, SER_TX, 0, SER_BAUD)
    time.MSleep(100)
    ser.Clear
    ser.Str(string("Serial terminal started", ser#CR, ser#LF))
    if _display_cog := display.Start (CS, DC, DIN, CLK, RESET, WIDTH, HEIGHT, @_framebuff)
        ser.Str(string("SSD1351 driver started", ser#CR, ser#LF))
        display.FontAddress(fnt.BaseAddr)
        display.FontSize(6, 8)
        display.Defaults
    else
        ser.Str(string("SSD1351 driver failed to start - halting"))
        Stop
    _bench_cog := cognew(FPS_mon, @_bench_iter_stack)

PUB Stop

    display.Stop
    time.MSleep (5)
    if _bench_cog
        cogstop(_bench_cog)
    time.MSleep (5)
    ser.Stop

#include "lib.utility.spin"

DAT
{
    --------------------------------------------------------------------------------------------------------
    TERMS OF USE: MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
    associated documentation files (the "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
    following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial
    portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    --------------------------------------------------------------------------------------------------------
}
