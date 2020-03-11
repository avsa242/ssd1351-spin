{
    --------------------------------------------
    Filename: SSD1351-Demo.spin
    Author: Jesse Burt
    Description: Simple demo for the SSD1351 driver
    Copyright (c) 2020
    Started Nov 3, 2019
    Updated Feb 8, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_CLKMODE
    _xinfreq    = cfg#_XINFREQ

    LED         = cfg#LED1
    SER_RX      = 31
    SER_TX      = 30
    SER_BAUD    = 115_200

    DIN         = 0
    CLK         = 1
    CS          = 2
    DC          = 3
    RESET       = 4

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
    oled    : "display.oled.ssd1351.spi.spin"
    int     : "string.integer"
    fnt     : "font.5x8"

VAR

    long _rndseed
    long _a_min, _a_max, _a_range
    long _b_min, _b_max, _b_range
    long _c_min, _c_max, _c_range
    long _d_min, _d_max, _d_range
    long _bench_iter, _bench_iter_stack[50]
    word _framebuff[BUFFSZ/2]
    byte _ser_cog, _oled_cog, _bench_cog
    byte _bench_type

PUB Main

    Setup

'    Demo_Text(1024)
'    time.Sleep(2)

    Demo_MEMScroller ($0000, $FFFF)
    time.Sleep(2)
    oled.ClearAll

    Demo_Circle (100)
    time.Sleep (2)
    oled.ClearAll

    Demo_Sine (500)
    time.Sleep (2)
    oled.ClearAll

    Demo_LineBitmap (1_000)
    time.Sleep (2)
    oled.ClearAll

    oled.DisplayBounds(0, 0, 95, 63)    'Need to reset this here because PlotAccel changes it

    Demo_PlotBitmap (1000)
    time.Sleep (2)
    oled.ClearAll

    Demo_BoxBitmap(250)
    time.Sleep (2)
    oled.ClearAll

    Demo_FadeOut (1, 30)

    Stop
    FlashLED (LED, 100)

PUB Demo_Text(reps) | r, fg, bg, ch, col, row
' Draw text with random foreground and background colors
    ser.Str(string("Demo_Text", ser#CR, ser#LF))
    ch := col := row := 0
    fg := cnt   ' Seed the color variables
    bg := cnt
    repeat r from 1 to reps
        oled.FGColor(?fg)
        oled.BGColor(?bg)
        oled.Position(col, row)
        oled.Char(ch)
        ch++
        if ch > fnt#LASTCHAR
            ch := 0
        col++
        if col > 15
            col := 0
            row++
        if row > 7
            row := 0
        oled.Update
    oled.BGColor(0)

PUB Demo_Sine(reps) | r, x, y, modifier, offset, div
' Draw a sine wave the length of the screen, influenced by
'  the system counter
    ser.Str(string("Demo_Sine", ser#CR, ser#LF))
    div := 2048
    offset := YMAX/2                                    ' Offset for Y axis
    _bench_type := BT_FRAME

    repeat r from 1 to reps
        repeat x from 0 to XMAX
            modifier := (||cnt / 1_000_000)           ' Use system counter as modifier
            y := offset + sin(x * modifier) / div
            oled.Plot (x, y, $FF_FF)
        oled.Update
        _bench_iter++
        oled.Clear

PUB Demo_Bitmap(reps)
' Draw bitmap
    ser.Str(string("Demo_Bitmap", ser#CR, ser#LF))
    _bench_type := BT_FRAME
    repeat reps
        oled.Bitmap (0, BUFFSZ, 0)
        oled.Update
        _bench_iter++

PUB Demo_BoxBitmap(reps) | sx, sy, ex, ey, c
' Draw random filled boxes using the bitmap library's method
    ser.Str(string("Demo_BoxBitmap", ser#CR, ser#LF))
    _bench_type := BT_UNIT
    repeat reps
        sx := RND (95)
        sy := RND (63)
        ex := RND (95)
        ey := RND (63)
        c := (?_rndseed >> 26) << 11 | (?_rndseed >> 25) << 5 | (?_rndseed >> 26)
        oled.Box (sx, sy, ex, ey, c, TRUE)
        oled.Update
        _bench_iter++

PUB Demo_Circle(reps) | r, x, y, c
'' Draws random circles
    ser.Str(string("Demo_Circle", ser#CR, ser#LF))
    _rndseed := cnt
    _bench_type := BT_FRAME
    repeat reps
        x := rnd(XMAX)
        y := rnd(YMAX)
        r := rnd(YMAX)
        c := (?_rndseed >> 26) << 11 | (?_rndseed >> 25) << 5 | (?_rndseed >> 26)
        oled.Circle (x, y, r, c)
        oled.Update
        _bench_iter++

PUB Demo_FadeIn(reps, delay) | c
' Fade out display
    ser.Str(string("Demo_FadeIn", ser#CR, ser#LF))
    repeat c from 0 to 127
        oled.Contrast (c, c, c)
        time.MSleep (delay)

PUB Demo_FadeOut(reps, delay) | c
' Fade out display
    ser.Str(string("Demo_FadeOut", ser#CR, ser#LF))
    repeat c from 127 to 0
        oled.Contrast (c, c, c)
        time.MSleep (delay)

PUB Demo_LineBitmap(reps) | sx, sy, ex, ey, c
' Draw random lines, using the bitmap library's method
    ser.Str(string("Demo_LineBitmap", ser#CR, ser#LF))
    _bench_type := BT_UNIT
    repeat reps
        sx := RND (95)
        sy := RND (63)
        ex := RND (95)
        ey := RND (63)
        c := (?_rndseed >> 26) << 11 | (?_rndseed >> 25) << 5 | (?_rndseed >> 26)
        oled.Line (sx, sy, ex, ey, c)
        oled.Update
        _bench_iter++

PUB Demo_MEMScroller(start_addr, end_addr) | pos, st, en
' Dump Propeller Hub RAM (or ROM) to the framebuffer
    ser.Str(string("Demo_MEMScroller", ser#CR, ser#LF))
    _bench_type := BT_FRAME
    repeat pos from start_addr to end_addr-BUFFSZ step BPL
        wordmove(@_framebuff, pos, BUFFSZ/2)
        oled.Update
        _bench_iter++

PUB Demo_PlotBitmap(reps) | x, y, c
' Draw random pixels, using the bitmap library's method
    ser.Str(string("Demo_PlotBitmap", ser#CR, ser#LF))
    _bench_type := BT_UNIT
    repeat reps
        x := RND (95)
        y := RND (63)
        c := (?_rndseed >> 26) << 11 | (?_rndseed >> 25) << 5 | (?_rndseed >> 26)
        oled.Plot(x, y, c)
        oled.Update
        _bench_iter++

PUB FPS
' Displays approximation of frame rate on terminal
' Send the _bench_iter value to the terminal once every second, and clear it
    repeat
        time.Sleep (1)
        case _bench_type
            BT_FRAME:
                ser.Position (0, 5)
                ser.Str(string("FPS: "))
                ser.Str (int.DecPadded (_bench_iter, 3))

                ser.Position (0, 6)
                ser.Str(string("Approximate throughput: "))
                ser.Str (int.DecPadded (_bench_iter*12288, 7))
                ser.Str(string("bytes/sec"))

            BT_UNIT:
                ser.Position (0, 5)
                ser.Str(string("Units/sec: "))
                ser.Str (int.DecPadded (_bench_iter, 6))

                ser.Position (0, 6)
                ser.Str(string("Approximate throughput: "))
                ser.Str(string("N/A"))

        _bench_iter := 0

PUB GetColor(val) | red, green, blue, inmax, outmax, divisor, tmp
' Return color from gradient scale, setup by SetColorScale
    inmax := 65535
    outmax := 255
    divisor := inmax / outmax

    case val
        _a_min.._a_max:
            red := 0
            green := 0
            blue := val/divisor
        _b_min.._b_max:
            red := 0
            green := val/divisor
            blue := 255
        _c_min.._c_max:
            red := val/divisor
            green := 255
            blue := 255-(val/divisor)
        _d_min.._d_max:
            red := 255
            green := 255-(val/divisor)
            blue := 0
        OTHER:

' RGB565 format
    return ((red >> 3) << 11) | ((green >> 2) << 5) | (blue >> 3)

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

PUB SetColorScale
' Set up 4-point scale for GetColor
    ser.Str(string("SetColorScale"))
    _a_min := 0
    _a_max := 16383
    _a_range := _a_max - _a_min

    _b_min := _a_max + 1
    _b_max := 32767
    _b_range := _b_max - _b_min

    _c_min := _b_max + 1
    _c_max := 49151
    _c_range := _c_max - _c_min

    _d_min := _c_max + 1
    _d_max := 65535
    _d_range := _d_max - _d_min

PUB Setup

    repeat until _ser_cog := ser.StartRXTX (SER_RX, SER_TX, 0, SER_BAUD)
    time.MSleep(30)
    ser.Clear
    ser.Str(string("Serial terminal started", ser#CR, ser#LF))
    if _oled_cog := oled.Start (CS, DC, DIN, CLK, RESET, @_framebuff)
        ser.Str(string("SSD1351 driver started", ser#CR, ser#LF))
        oled.FontAddress(fnt.BaseAddr)
        oled.FontSize(6, 8)
'        oled.Defaults
    else
        ser.Str(string("SSD1351 driver failed to start - halting"))
        Stop
    SetColorScale
'    _bench_cog := cognew(fps, @_bench_iter_stack)

PUB Stop

    oled.Stop
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
