{
    --------------------------------------------
    Filename: SSD1351-MinimalDemo.spin
    Description: Demo of the SSD1351 driver
        * minimal code example
    Author: Jesse Burt
    Copyright (c) 2024
    Started: Jan 3, 2024
    Updated: Jan 3, 2024
    See end of file for terms of use.
    --------------------------------------------
}
CON

    _clkmode    = xtal1 + pll16x
    _xinfreq    = 5_000_000

OBJ

    fnt:    "font.5x8"
    disp:   "display.oled.ssd1351" | WIDTH=96, HEIGHT=96, CS=0, SCK=1, MOSI=2, DC=3, RST=4


PUB main()

    { start the driver }
    disp.start()

    { configure the display with the minimum required setup:
        1. Set the display WIDTH and HEIGHT in the OBJ line above
        2. Use a common settings preset (uncomment one below) }
    { the following presets can only operate in unbuffered mode (draw directly to the display)
        on the P1, due to memory constraints; uncomment the #define and #pragma lines before
        building }
'#define GFX_DIRECT
'#pragma exportdef(GFX_DIRECT)
'    disp.preset_128x128()                      ' 128x128 panels
'    disp.preset_128x()                         ' 128x other vertical resolutions
'    disp.preset_128xhiperf()                   '   same, but max display clock

    { the following presets can operate either buffered or unbuffered on the P1 }
    disp.preset_clickc_towards()               ' MikroE OLED #1585 96x96, glass panel towards user
'    disp.preset_clickc_away()                  '   same, but glass panel away from user

    disp.set_font(fnt.ptr(), fnt.setup())
    disp.clear()

    { draw some text }
    disp.pos_xy(0, 0)
    disp.fgcolor($ffff)
    disp.strln(@"Testing 12345")
    disp.show()                               ' send the buffer to the display

    { draw one pixel at the center of the screen }
    {   disp.plot(x, y, color) }
    disp.plot(disp.CENTERX, disp.CENTERY, $ffff)
    disp.show()

    { draw a box at the screen edges }
    {   disp.box(x_start, y_start, x_end, y_end, color, filled) }
    disp.box(0, 0, disp.XMAX, disp.YMAX, $ffff, false)
    disp.show()

    repeat


DAT
{
Copyright 2024 Jesse Burt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

