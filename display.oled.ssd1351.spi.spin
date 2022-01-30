{
    --------------------------------------------
    Filename: display.oled.ssd1351.spi.spin
    Author: Jesse Burt
    Description: Driver for Solomon Systech SSD1351 RGB OLED displays
    Copyright (c) 2022
    Started: Mar 11, 2020
    Updated: Jan 30, 2022
    See end of file for terms of use.
    --------------------------------------------
}
#define MEMMV_NATIVE wordmove
#include "lib.gfx.bitmap.spin"

CON

    MAX_COLOR       = 65535
    BYTESPERPX      = 2

' Display power on/off modes
    OFF             = 0
    ON              = 1

' Display visibility modes
    ALL_OFF         = 0
    ALL_ON          = 1
    NORMAL          = 2
    INVERTED        = 3

' Color depth formats
    COLOR_65K       = %00   ' or %01
    COLOR_262K      = %10
    COLOR_262K65K2  = %11

' Address increment mode
    ADDR_HORIZ      = 0
    ADDR_VERT       = 1

' Subpixel order
    RGB             = 0
    BGR             = 1

' OLED command lock
    ALL_UNLOCK      = $12
    ALL_LOCK        = $16
    CFG_LOCK        = $B0
    CFG_UNLOCK      = $B1

' Character attributes
    DRAWBG          = 1 << 0

OBJ

    core    : "core.con.ssd1351"                ' HW-specific constants
    time    : "time"                            ' timekeeping methods
    spi     : "com.spi.fast-nocs"               ' PASM SPI engine (20MHz)

VAR

    long _CS, _DC, _RES
    byte _offs_x, _offs_y

    ' shadow registers
    byte _sh_CLK, _sh_REMAPCOLOR, _sh_PHASE12PER

PUB Null{}
' This is not a top-level object

PUB Startx(CS_PIN, CLK_PIN, DIN_PIN, DC_PIN, RES_PIN, WIDTH, HEIGHT, ptr_dispbuff): status
' Start driver using custom I/O settings
    if lookdown(CS_PIN: 0..31) and lookdown(DC_PIN: 0..31) {
}   and lookdown(DIN_PIN: 0..31) and lookdown(CLK_PIN: 0..31)
        if (status := spi.init(CLK_PIN, DIN_PIN, -1, core#SPI_MODE))
            _DC := DC_PIN
            _RES := RES_PIN
            _CS := CS_PIN
            outa[_CS] := 1
            dira[_CS] := 1
            outa[_DC] := 1
            dira[_DC] := 1
            _disp_width := WIDTH
            _disp_height := HEIGHT
            _disp_xmax := _disp_width - 1
            _disp_ymax := _disp_height - 1
            _buff_sz := (_disp_width * _disp_height) * BYTESPERPX
            _bytesperln := _disp_width * BYTESPERPX

            address(ptr_dispbuff)
            reset{}
            time.usleep(core#T_POR)
            lockdisplay(ALL_UNLOCK)
            lockdisplay(CFG_UNLOCK)
            return
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE

PUB Stop{}

    displayvisibility(ALL_OFF)
    powered(FALSE)
    spi.deinit{}

PUB Defaults{}
' Apply power-on-reset default settings
    displayvisibility(ALL_OFF)
    displaystartline(0)
    displaylines(128)
    clockfreq(3020)
    clockdiv(1)
    contrastabc(138, 81, 138)
    powered(TRUE)
    displaybounds(0, 0, 127, 127)
    clear{}
    displayvisibility(NORMAL)

PUB Preset_ClickC_Away{}
' Preset: MikroE OLED C Click (96x96)
'   (Parallax #64208, MikroE #MIKROE-1585)
'   **Oriented so glass panel is facing away from user user, PCB facing towards
'   origin (upper-left) isn't at 0, 0 on this panel
'   start at 16 pixels in from the left, and add that to the right-hand side
    displaybounds(0, 0, 95, 95)
    addrmode(ADDR_HORIZ)
    subpixelorder(RGB)
    interlaced(FALSE)
    colordepth(COLOR_65K)
    displaystartline(0)
    mirrorh(TRUE)
    mirrorv(TRUE)
    displayoffset(16, 32)
    clockfreq(3020)
    clockdiv(1)
    contrast(127)
    displaylines(96)

    powered(TRUE)
    displayvisibility(NORMAL)

PUB Preset_ClickC_Towards{}
' Preset: MikroE OLED C Click (96x96)
'   (Parallax #64208, MikroE #MIKROE-1585)
'   **Oriented so glass panel is facing towards user, PCB facing away
'   origin (upper-left) isn't at 0, 0 on this panel
'   start at 16 pixels in from the left, and add that to the right-hand side
    displaybounds(0, 0, 95, 95)
    addrmode(ADDR_HORIZ)
    subpixelorder(RGB)
    interlaced(FALSE)
    colordepth(COLOR_65K)
    displaystartline(0)
    mirrorh(FALSE)
    mirrorv(FALSE)
    displayoffset(16, 96)
    clockfreq(3020)
    clockdiv(1)
    contrast(127)
    displaylines(96)

    powered(TRUE)
    displayvisibility(NORMAL)

PUB Preset_128x{}
' Preset: 128px wide, determine settings for height at runtime
    displaybounds(0, 0, _disp_xmax, _disp_ymax)
    addrmode(ADDR_HORIZ)
    subpixelorder(RGB)
    interlaced(FALSE)
    colordepth(COLOR_65K)
    displaystartline(0)
    displayoffset(0, 0)
    clockfreq(3020)
    clockdiv(1)
    contrast(127)
    displaylines(_disp_height)

    powered(TRUE)
    displayvisibility(NORMAL)

PUB Preset_128x128{}
' Preset: 128px wide, 128px high
    displaybounds(0, 0, 127, 127)
    addrmode(ADDR_HORIZ)
    subpixelorder(RGB)
    interlaced(FALSE)
    colordepth(COLOR_65K)
    displaystartline(0)
    displayoffset(0, 0)
    clockfreq(3020)
    clockdiv(1)
    contrast(127)
    displaylines(128)

    powered(TRUE)
    displayvisibility(NORMAL)

PUB Preset_128xHiPerf{}
' Preset: 128px wide, determine settings for height at runtime
'   display osc. set to max clock
    displaybounds(0, 0, _disp_xmax, _disp_ymax)
    addrmode(ADDR_HORIZ)
    subpixelorder(RGB)
    interlaced(FALSE)
    colordepth(COLOR_65K)
    displaystartline(0)
    displayoffset(0, 0)
    clockfreq(3100)
    clockdiv(1)
    contrast(127)
    displaylines(_disp_height)

    powered(TRUE)
    displayvisibility(NORMAL)

PUB Address(addr): curr_addr
' Set framebuffer/display buffer address
    case addr
        $0004..$7FFF-_buff_sz:
            _ptr_drawbuffer := addr
        other:
            return _ptr_drawbuffer

PUB AddrMode(mode): curr_mode
' Set display internal addressing mode
'   Valid values:
'  *ADDR_HORIZ (0): Horizontal addressing mode
'   ADDR_VERT (1): Vertical addressing mode
    curr_mode := _sh_REMAPCOLOR
    case mode
        ADDR_HORIZ, ADDR_VERT:
        other:
            return ((curr_mode >> core#ADDRINC) & 1)

    _sh_REMAPCOLOR := ((_sh_REMAPCOLOR & core#SEGREMAP_MASK) | mode)
    writereg(core#SETREMAP, 1, @_sh_REMAPCOLOR)

#ifdef GFX_DIRECT
PUB Bitmap(ptr_bmap, xs, ys, bm_wid, bm_lns) | offs, nr_pix
' Display bitmap
'   ptr_bmap: pointer to bitmap data
'   (xs, ys): upper-left corner of bitmap
'   bm_wid: width of bitmap, in pixels
'   bm_lns: number of lines in bitmap
    displaybounds(xs, ys, xs+(bm_wid-1), ys+(bm_lns-1))
    outa[_CS] := 0
    outa[_DC] := core#CMD
    spi.wr_byte(core#WRITERAM)

    ' calc total number of pixels to write, based on dims and color depth
    ' clamp to a minimum of 1 to avoid odd behavior
    nr_pix := 1 #> ((xs + bm_wid-1) * (ys + bm_lns-1) * BYTESPERPX)

    outa[_DC] := core#DATA
    spi.wrblock_lsbf(ptr_bmap, nr_pix)
    outa[_CS] := 1
#endif

#ifdef GFX_DIRECT
PUB Box(x1, y1, x2, y2, c, fill) | cmd_pkt[2]
' Draw a box
'   (x1, y1): upper-left corner of box
'   (x2, y2): lower-right corner of box
'   c: color
'   fill: filled flag (0: no fill, nonzero: fill)
    if (x2 < x1) or (y2 < y1)
        return
    if fill
        cmd_pkt.byte[0] := core#SETCOLUMN       ' D/C L
        cmd_pkt.byte[1] := x1+_offs_x           ' D/C H
        cmd_pkt.byte[2] := x2+_offs_x
        cmd_pkt.byte[3] := core#SETROW          ' D/C L
        cmd_pkt.byte[4] := y1                   ' D/C H
        cmd_pkt.byte[5] := y2

        outa[_DC] := core#CMD
        outa[_CS] := 0
        spi.wr_byte(cmd_pkt.byte[0])            ' column cmd
        outa[_DC] := core#DATA
        spi.wrblock_lsbf(@cmd_pkt.byte[1], 2)   ' x0, x1

        outa[_DC] := core#CMD
        spi.wr_byte(cmd_pkt.byte[3])            ' row cmd
        outa[_DC] := core#DATA
        spi.wrblock_lsbf(@cmd_pkt.byte[4], 2)   ' y0, y1

        outa[_DC] := core#CMD
        spi.wr_byte(core#WRITERAM)
        outa[_DC] := core#DATA
        spi.wrwordx_msbf(c, ((y2-y1)+1) * ((x2-x1)+1))
    else
        displaybounds(x1, y1, x2, y1)           ' top
        outa[_CS] := 0
        outa[_DC] := core#CMD
        spi.wr_byte(core#WRITERAM)
        outa[_DC] := core#DATA
        spi.wrwordx_msbf(c, (x2-x1)+1)

        displaybounds(x1, y2, x2, y2)           ' bottom
        outa[_CS] := 0
        outa[_DC] := core#CMD
        spi.wr_byte(core#WRITERAM)
        outa[_DC] := core#DATA
        spi.wrwordx_msbf(c, (x2-x1)+1)

        displaybounds(x1, y1, x1, y2)           ' left
        outa[_CS] := 0
        outa[_DC] := core#CMD
        spi.wr_byte(core#WRITERAM)
        outa[_DC] := core#DATA
        spi.wrwordx_msbf(c, (y2-y1)+1)

        displaybounds(x2, y1, x2, y2)           ' right
        outa[_CS] := 0
        outa[_DC] := core#CMD
        spi.wr_byte(core#WRITERAM)
        outa[_DC] := core#DATA
        spi.wrwordx_msbf(c, (y2-y1)+1)
    outa[_CS] := 1
#endif

#ifdef GFX_DIRECT
PUB Char(ch) | gl_c, gl_r, lastgl_c, lastgl_r
' Draw character from currently loaded font
    lastgl_c := _font_width-1
    lastgl_r := _font_height-1
    case ch
        CR:
            _charpx_x := 0
        LF:
            _charpx_y += _charcell_h
            if _charpx_y > _charpx_xmax
                _charpx_y := 0
        0..127:                                 ' validate ASCII code
            ' walk through font glyph data
            repeat gl_c from 0 to lastgl_c      ' column
                repeat gl_r from 0 to lastgl_r  ' row
                    ' if the current offset in the glyph is a set bit, draw it
                    if byte[_font_addr][(ch << 3) + gl_c] & (|< gl_r)
                        plot((_charpx_x + gl_c), (_charpx_y + gl_r), _fgcolor)
                    else
                    ' otherwise, draw the background color, if enabled
                        if _char_attrs & DRAWBG
                            plot((_charpx_x + gl_c), (_charpx_y + gl_r), _bgcolor)
            ' move the cursor to the next column, wrapping around to the left,
            ' and wrap around to the top of the display if the bottom is reached
            _charpx_x += _charcell_w
            if _charpx_x > _charpx_xmax
                _charpx_x := 0
                _charpx_y += _charcell_h
            if _charpx_y > _charpx_ymax
                _charpx_y := 0
        other:
            return
#endif

#ifdef GFX_DIRECT
PUB Clear{}
' Clear the display directly, bypassing the display buffer
    displaybounds(0, 0, _disp_xmax, _disp_ymax)
    outa[_DC] := core#CMD
    outa[_CS] := 0
    spi.wr_byte(core#WRITERAM)
    outa[_DC] := core#DATA
    spi.wrwordx_msbf(_bgcolor, _buff_sz/2)
    outa[_CS] := 1

#else

PUB Clear{}
' Clear the display buffer
    wordfill(_ptr_drawbuffer, _bgcolor, _buff_sz/2)
#endif

PUB ClockDiv(divider): curr_div
' Set clock frequency divider used by the display controller
'   Valid values: 1..16 (default: 1)
'   Any other value returns the current setting
    curr_div := _sh_CLK
    case divider
        1..16:
            divider -= 1
        other:
            return (curr_div & core#CLK_DIV_BITS) + 1

    _sh_CLK := ((curr_div & core#CLK_DIV_MASK) | divider)
    writereg(core#CLKDIV, 1, @_sh_CLK)

PUB ClockFreq(freq): curr_freq
' Set display internal oscillator frequency, in kHz
'   Valid values: 2500..3100 (default: 3020)
'   Any other value returns the current setting
'   NOTE: Range is interpolated, based on the datasheet min/max values and
'   number of steps, so actual clock frequency may not be accurate.
'   Value set will be rounded to the nearest 40kHz
    curr_freq := _sh_CLK
    case freq
        2500..3100:
            freq := ((freq-2500) / 40) << core#FOSCFREQ
        other:
            curr_freq := (curr_freq >> core#FOSCFREQ) & core#FOSCFREQ_BITS
            return (curr_freq * 40) + 2500

    _sh_CLK := ((curr_freq & core#FOSCFREQ_MASK) | freq)
    writereg(core#CLKDIV, 1, @_sh_CLK)

PUB ColorDepth(format): curr_fmt
' Set expected color format of pixel data
'   Valid values:
'      *COLOR_65K (0): 16-bit/65536 color format 1
'       COLOR_262K (1): 18-bits/262144 color format
'       COLOR_262K65K2 (2): 18-bit/262144 color format, 16-bit/65536 color format 2
'   Any other value returns the current setting
    curr_fmt := _sh_REMAPCOLOR
    case format
        COLOR_65K, COLOR_262K, COLOR_262K65K2:
            format <<= core#COLORFMT
        other:
            return (curr_fmt >> core#COLORFMT)

    _sh_REMAPCOLOR := ((curr_fmt & core#COLORFMT_MASK) | format)
    writereg(core#SETREMAP, 1, @_sh_REMAPCOLOR)

PUB COMHVoltage(level): curr_lvl
' Set logic high level threshold of COM pins rel. to Vcc, in millivolts
'   Valid values: 720..860 (default: 820)
'   Any other value is ignored
'   NOTE: Range is interpolated, based on the datasheet min/max values and number of steps,
'       so actual voltage may not be accurate. Value set will be rounded to the nearest 20mV
    case level
        720..860:
            level := (level - 720) / 20
            writereg(core#VCOMH, 1, @level)
        other:
            return

PUB Contrast(level)
' Set display contrast/brightness of all subpixels to the same value
'   Valid values: 0..255
'   Any other value is ignored
    contrastabc(level, level, level)

PUB ContrastABC(a, b, c) | tmp
' Set contrast/brightness level of subpixels a, b, c
'   Valid values: 0..255 (default a: 138, b: 81, c: 138)
'   Any other value is ignored
    case a
        0..255:
        other:
            return
    case b
        0..255:
        other:
            return
    case c
        0..255:
        other:
            return

    tmp.byte[0] := a
    tmp.byte[1] := b
    tmp.byte[2] := c
    writereg(core#SETCNTRSTABC, 3, @tmp)

PUB DisplayBounds(sx, sy, ex, ey) | tmpx, tmpy
' Set drawable display region for subsequent drawing operations
'   Valid values:
'       sx, ex: 0..127
'       sy, ey: 0..127
'   Any other value will be ignored
    ifnot lookup(sx: 0..127) or lookup(sy: 0..127) or lookup(ex: 0..127) {
}   or lookup(ey: 0..127)
        return

    tmpx.byte[0] := sx+_offs_x
    tmpx.byte[1] := ex+_offs_x
    tmpy.byte[0] := sy
    tmpy.byte[1] := ey

    ' the SSD1351 requires (ex, ey) be greater than (sx, ey)
    ' if they're not, swap them
    if ex < sx
        tmpx.byte[2] := tmpx.byte[0]            ' use byte 2 as a temp var
        tmpx.byte[0] := tmpx.byte[1]            ' since it's otherwise unused
        tmpx.byte[1] := tmpx.byte[2]
    if ey < sy
        tmpy.byte[2] := tmpy.byte[0]
        tmpy.byte[0] := tmpy.byte[1]
        tmpy.byte[1] := tmpy.byte[2]
    writereg(core#SETCOLUMN, 2, @tmpx)
    writereg(core#SETROW, 2, @tmpy)

PUB DisplayLines(lines)
' Set total number of display lines
'   Valid values: 16..128 (default: 128)
'   Any other value is ignored
    case lines
        16..128:
            lines -= 1
            writereg(core#SETMUXRATIO, 1, @lines)
        other:
            return

PUB DisplayInverted(state)
' Invert display colors
'   Valid values: TRUE (-1 or 1), *FALSE (0)
'   Any other value is ignored
    case ||(state)
        0, 1:
            displayvisibility(INVERTED - ||(state))
        other:
            return

PUB DisplayOffset(x, y)
' Set display offset
    _offs_x := 0 #> x <# 127
    y := 0 #> y <# 127
    writereg(core#DISPOFFSET, 1, @y)            ' SSD1351 built-in

PUB DisplayStartLine(disp_line)
' Set display start line
'   Valid values: 0..127 (default: 0)
'   Any other value is ignored
    case disp_line
        0..127:
        other:
            return

    writereg(core#STARTLINE, 1, @disp_line)

PUB DisplayVisibility(mode)
' Set display visibility
'   Valid values:
'       ALL_OFF (0): Turns off all pixels
'       ALL_ON (1): Turns on all pixels (white)
'      *NORMAL (2): Normal display (display graphics RAM contents)
'       INVERTED (3): Like NORMAL, but with inverted colors
'   NOTE: This setting doesn't affect the contents of graphics RAM,
'       only how they are displayed
    case mode
        ALL_OFF, ALL_ON, NORMAL, INVERTED:
            mode := mode + core#DISPALLOFF
            writereg(mode, 0, 0)
        other:
            return

PUB Interlaced(state): curr_state
' Alternate every other display line:
' Lines 0..31 will appear on even rows (starting on row 0)
' Lines 32..63 will appear on odd rows (starting on row 1)
'   Valid values: TRUE (-1 or 1), *FALSE (0)
'   Any other value returns the current setting
    curr_state := _sh_REMAPCOLOR
    case ||(state)
        0, 1:
            state := (||(state) ^ 1) << core#COMSPLIT
        other:
            return (not (((curr_state >> core#COMSPLIT) & 1) == 1))

    _sh_REMAPCOLOR := ((curr_state & core#COMSPLIT_MASK) | state)
    writereg(core#SETREMAP, 1, @_sh_REMAPCOLOR)

#ifdef GFX_DIRECT
PUB Line(x1, y1, x2, y2, c) | sx, sy, ddx, ddy, err, e2
' Draw line from x1, y1 to x2, y2, in color c
    if (x1 == x2)
        displaybounds(x1, y1, x1, y2)           ' vertical
        outa[_CS] := 0
        outa[_DC] := core#CMD
        spi.wr_byte(core#WRITERAM)
        outa[_DC] := core#DATA
        spi.wrwordx_msbf(c, (||(y2-y1))+1)
        outa[_CS] := 1
        return
    if (y1 == y2)
        displaybounds(x1, y1, x2, y1)           ' horizontal
        outa[_CS] := 0
        outa[_DC] := core#CMD
        spi.wr_byte(core#WRITERAM)
        outa[_DC] := core#DATA
        spi.wrwordx_msbf(c, (||(x2-x1))+1)
        outa[_CS] := 1
        return

    ddx := ||(x2-x1)
    ddy := ||(y2-y1)
    err := ddx-ddy

    sx := -1
    if (x1 < x2)
        sx := 1

    sy := -1
    if (y1 < y2)
        sy := 1

    repeat until ((x1 == x2) and (y1 == y2))
        plot(x1, y1, c)
        e2 := err << 1

        if e2 > -ddy
            err -= ddy
            x1 += sx

        if e2 < ddx
            err += ddx
            y1 += sy
#endif

PUB LockDisplay(mode)
' Lock the display controller from executing commands
'   Valid values:
'      *ALL_UNLOCK ($12): Normal operation - OLED display accepts commands
'       LOCK ($16): Locked - OLED will not process any commands, except LockDisplay(ALL_UNLOCK)
'      *CFG_LOCK ($B0): Configuration registers locked
'       CFG_UNLOCK ($B1): Configuration registers unlocked
    case mode
        ALL_UNLOCK, ALL_LOCK, CFG_LOCK, CFG_UNLOCK:
            writereg(core#SETLOCK, 1, @mode)
        other:
            return

PUB MirrorH(state): curr_state
' Mirror the display, horizontally
'   Valid values: TRUE (-1 or 1), *FALSE (0)
'   Any other value returns the current setting
    curr_state := _sh_REMAPCOLOR
    case ||(state)
        0, 1:
            state := (||(state)) << core#SEGREMAP
        other:
            return (((curr_state >> core#SEGREMAP) & 1) == 1)

    _sh_REMAPCOLOR := ((curr_state & core#SEGREMAP_MASK) | state)
    writereg(core#SETREMAP, 1, @_sh_REMAPCOLOR)

PUB MirrorV(state): curr_state
' Mirror the display, vertically
'   Valid values: TRUE (-1 or 1), *FALSE (0)
'   Any other value returns the current setting
    curr_state := _sh_REMAPCOLOR
    case ||(state)
        0, 1:
            state := (||(state)) << core#COMREMAP
        other:
            return (((curr_state >> core#COMREMAP) & 1) == 1)

    _sh_REMAPCOLOR := ((curr_state & core#COMREMAP_MASK) | state)
    writereg(core#SETREMAP, 1, @_sh_REMAPCOLOR)

PUB Phase1Period(clks): curr_per
' Set discharge/phase 1 period, in display clocks
'   Valid values: *5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31
'   Any other value returns the current setting
    curr_per := _sh_PHASE12PER
    case clks
        5..31:
            clks := lookdown(clks: 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31)
        other:
            curr_per &= core#PHASE1_BITS
            return lookup(curr_per: 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31)

    clks := ((curr_per & core#PHASE1_MASK) | clks)
    writereg(core#PRECHG, 1, @_sh_PHASE12PER)

PUB Phase2Period(clks): curr_per
' Set charge/phase 2 period, in display clocks
'   Valid values: 3..15 (default: 8)
'   Any other value returns the current setting
    curr_per := _sh_PHASE12PER
    case clks
        3..15:
            clks <<= core#PHASE2
        other:
            return (curr_per >> core#PHASE2) & core#PHASE2_BITS

    _sh_PHASE12PER := ((curr_per & core#PHASE2_MASK) | clks)
    writereg(core#PRECHG, 1, @_sh_PHASE12PER)

PUB Phase3Period(clks)
' Set second charge/phase 3 period, in display clocks
'   Valid values: 1..15 (default: 8)
'   Any other value is ignored
    case clks
        1..15:
        other:
            return

    writereg(core#SETSECPRECHG, 1, @clks)

#ifdef GFX_DIRECT
PUB Plot(x, y, c) | cmd_pkt[3]
' Draw a pixel at (x, y) (direct to display)
    if (x => 0 and x =< _disp_xmax) and (y => 0 and y =< _disp_ymax)
        cmd_pkt.byte[0] := core#SETCOLUMN       ' D/C L
        cmd_pkt.byte[1] := x+_offs_x            ' D/C H
        cmd_pkt.byte[2] := x+_offs_x
        cmd_pkt.byte[3] := core#SETROW          ' D/C L
        cmd_pkt.byte[4] := y                    ' D/C H
        cmd_pkt.byte[5] := y
        cmd_pkt.byte[6] := core#WRITERAM        ' D/C L
        cmd_pkt.byte[7] := c.byte[1]            ' D/C H
        cmd_pkt.byte[8] := c.byte[0]
        outa[_DC] := core#CMD
        outa[_CS] := 0
        spi.wr_byte(cmd_pkt.byte[0])
        outa[_DC] := core#DATA
        spi.wrblock_lsbf(@cmd_pkt.byte[1], 2)

        outa[_DC] := core#CMD
        spi.wr_byte(cmd_pkt.byte[3])
        outa[_DC] := core#DATA
        spi.wrblock_lsbf(@cmd_pkt.byte[4], 2)

        outa[_DC] := core#CMD
        spi.wr_byte(cmd_pkt.byte[6])
        outa[_DC] := core#DATA
        spi.wrblock_lsbf(@cmd_pkt.byte[7], 2)
        outa[_CS] := 1

#else

PUB Plot(x, y, color)
' Draw a pixel at (x, y) in color (buffered)
    word[_ptr_drawbuffer][x + (y * _disp_width)] := color

#endif

#ifndef GFX_DIRECT
PUB Point(x, y): pix_clr
' Get color of pixel at x, y
    x := 0 #> x <# _disp_xmax
    y := 0 #> y <# _disp_ymax

    return word[_ptr_drawbuffer][x + (y * _disp_width)]
#endif

PUB Powered(state)
' Enable display power
'   Valid values:
'       OFF/FALSE (0): Turn off display power
'       ON/TRUE (-1 or 1): Turn on display power
'   Any other value is ignored
    case ||(state)
        OFF, ON:
            state := lookupz(||(state): core#DISPOFF, core#DISPON)
            writereg(state, 0, 0)
        other:
            return

PUB PrechargeLevel(level)
' Set first pre-charge voltage level (phase 2) of segment pins, in millivolts
'   Valid values: 200..600 (default: 497)
'   Any other value is ignored
'   NOTE: Range is interpolated, based on the datasheet min/max values and number of steps,
'       so actual voltage may not be accurate. Value set will be rounded to the nearest 13mV
    case level
        200..600:
            level := (level-200) / 13
            writereg(core#PRECHGLEVEL, 1, @level)
        other:
            return

PUB SubpixelOrder(order): curr_ord
' Set subpixel color order
'   Valid values:
'      *RGB (0): Red-Green-Blue order
'       BGR (1): Blue-Green-Red order
'   Any other value returns the current setting
    curr_ord := _sh_REMAPCOLOR
    case order
        RGB, BGR:
            order <<= core#SUBPIX_ORDER
        other:
            return ((curr_ord >> core#SUBPIX_ORDER) & 1)

    _sh_REMAPCOLOR := ((curr_ord & core#SUBPIX_ORDER_MASK) | order)
    writereg(core#SETREMAP, 1, @_sh_REMAPCOLOR)

PUB Reset{}
' Reset the display controller
    if lookdown(_RES: 0..31)
        outa[_RES] := 1
        dira[_RES] := 1
        outa[_RES] := 0
        time.usleep(2)
        outa[_RES] := 1

PUB Update{}
' Send the draw buffer to the display
#ifndef GFX_DIRECT
    displaybounds(0, 0, _disp_xmax, _disp_ymax)
    outa[_DC] := core#CMD
    outa[_CS] := 0
    spi.wr_byte(core#WRITERAM)
    outa[_DC] := core#DATA
    spi.wrblock_lsbf(_ptr_drawbuffer, _buff_sz)
    outa[_CS] := 1
#endif

#ifndef GFX_DIRECT
PRI memFill(xs, ys, val, count)
' Fill region of display buffer memory
'   xs, ys: Start of region
'   val: Color
'   count: Number of consecutive memory locations to write
    wordfill(_ptr_drawbuffer + ((xs << 1) + (ys * _bytesperln)), ((val >> 8) & $FF) | ((val << 8) & $FF00), count)
#endif

PRI writeReg(reg_nr, nr_bytes, ptr_buff) | tmp
' Write nr_bytes to device from ptr_buff
    case reg_nr
        $9E, $9F, $A4..$A7, $AD..$AF, $B0, $B9, $D1, $E3:
        ' Single-byte command
            outa[_DC] := core#CMD
            outa[_CS] := 0
            spi.wr_byte(reg_nr)
            outa[_CS] := 1
            return

        $15, $5C, $75, $96, $A0..$A2, $AB, $B1..$B6, $B8, $BB, $BE, $C1, {
}       $C7, $CA, $FD:
        ' Multi-byte command
            outa[_DC] := core#CMD
            outa[_CS] := 0
            spi.wr_byte(reg_nr)
            outa[_DC] := core#DATA
            spi.wrblock_lsbf(ptr_buff, nr_bytes)
            outa[_CS] := 1
            return

        other:
            return

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

