# A tomo library for Terminal User Interfaces
use ./btui.c

enum Color(Normal, Black, Red, Green, Yellow, Blue, Magenta, Cyan, White, Color256(n:Byte), RGB(r,g,b:Byte))
    func is_dark(c:Color -> Bool)
        when c is Black
            return yes
        is Color256(n)
            return n == 0 or n == 16 or n == 17 or (232 <= n and n <= 237)
        is RGB(r,g,b)
            return Int(r)+Int(g)+Int(b) < 127*3
        else
            return no

    func is_light(c:Color -> Bool)
        when c is White
            return yes
        is Color256, RGB
            return not c.is_dark()
        else
            return no

struct ScreenVec2(x,y:Int)
    func divided_by(v:ScreenVec2, divisor:Int -> ScreenVec2)
        return ScreenVec2(v.x/divisor, v.y/divisor)
    func scaled_by(v:ScreenVec2, scale:Int -> ScreenVec2)
        return ScreenVec2(v.x*scale, v.y*scale)
    func plus(a,b:ScreenVec2 -> ScreenVec2)
        return ScreenVec2(a.x+b.x, a.y+b.y)
    func minus(a,b:ScreenVec2 -> ScreenVec2)
        return ScreenVec2(a.x-b.x, a.y-b.y)

enum BTUIMode(Disabled, Normal, TUI)

func set_mode(mode:BTUIMode)
    when mode is Disabled
        C_code `btui_set_mode(BTUI_MODE_DISABLED);`
    is Normal
        C_code `btui_set_mode(BTUI_MODE_NORMAL);`
    is TUI
        C_code `btui_set_mode(BTUI_MODE_TUI);`

func disable()
    C_code `btui_disable();`

func force_close()
    C_code `btui_force_close();`

enum ClearMode(Screen, Above, Below, Line, Left, Right)

func clear(mode:ClearMode=Screen, pos:ScreenVec2?=none)
    if pos
        move_cursor(pos)

    when mode is Screen then C_code `btui_clear(BTUI_CLEAR_SCREEN);`
    is Above then C_code `btui_clear(BTUI_CLEAR_ABOVE);`
    is Below then C_code `btui_clear(BTUI_CLEAR_BELOW);`
    is Line then C_code `btui_clear(BTUI_CLEAR_LINE);`
    is Left then C_code `btui_clear(BTUI_CLEAR_LEFT);`
    is Right then C_code `btui_clear(BTUI_CLEAR_RIGHT);`

enum TextAlign(Left, Center, Right)

func write(text:Text, pos:ScreenVec2?=none, align:TextAlign=Left)
    if pos
        when align is Left then pass
        is Center then pos -= ScreenVec2(text.width()/2, 0)
        is Right then pos -= ScreenVec2(text.width(), 0)
        move_cursor(pos)

    C_code `
        btui_puts(@(text.as_c_string()));
        btui_flush();
    `

enum CursorMode(Default, BlinkingBlock, SteadyBlock, BlinkingUnderline, SteadyUnderline, BlinkingBar, SteadyBar)

func set_cursor(cursor:CursorMode)
    when cursor is Default then C_code`btui_set_cursor(CURSOR_DEFAULT);`
    is BlinkingBlock then C_code`btui_set_cursor(CURSOR_BLINKING_BLOCK);`
    is SteadyBlock then C_code`btui_set_cursor(CURSOR_STEADY_BLOCK);`
    is BlinkingUnderline then C_code`btui_set_cursor(CURSOR_BLINKING_UNDERLINE);`
    is SteadyUnderline then C_code`btui_set_cursor(CURSOR_STEADY_UNDERLINE);`
    is BlinkingBar then C_code`btui_set_cursor(CURSOR_BLINKING_BAR);`
    is SteadyBar then C_code`btui_set_cursor(CURSOR_STEADY_BAR);`

func move_cursor(pos:ScreenVec2, relative=no)
    if relative
        C_code `btui_move_cursor_relative(@(Int32(pos.x)), @(Int32(pos.y)));`
    else
        C_code `btui_move_cursor(@(Int32(pos.x)), @(Int32(pos.y)));`

func hide_cursor()
    C_code `btui_hide_cursor();`

func show_cursor()
    C_code `btui_show_cursor();`

func get_size(->ScreenVec2)
    return ScreenVec2(
        Int(C_code:Int32`bt.width`),
        Int(C_code:Int32`bt.height`),
    )

func get_key(mouse_pos:&ScreenVec2?=none, timeout:Int?=none -> Text)
    timeout_i32 := if timeout then Int32(timeout) else Int32(-1)
    mouse_x : Int32
    mouse_y : Int32
    key := C_code:Text `
        int key = btui_getkey(@timeout_i32, &@mouse_x, &@mouse_y);
        char buf[256];
        char *end = btui_keyname(key, buf);
        Text$from_strn(buf, (int64_t)(end - buf));
    `
    if mouse_pos
        mouse_pos[] = ScreenVec2(Int(mouse_x), Int(mouse_y))

    return key

func flush()
    C_code `btui_flush();`

func draw_linebox(pos:ScreenVec2, size:ScreenVec2)
    C_code `btui_draw_linebox(@(Int32(pos.x)), @(Int32(pos.y)), @(Int32(size.x)), @(Int32(size.y)));`

func draw_shadow(pos:ScreenVec2, size:ScreenVec2)
    C_code `btui_draw_shadow(@(Int32(pos.x)), @(Int32(pos.y)), @(Int32(size.x)), @(Int32(size.y)));`


func fill_box(pos:ScreenVec2, size:ScreenVec2)
    C_code `btui_fill_box(@(Int32(pos.x)), @(Int32(pos.y)), @(Int32(size.x)), @(Int32(size.y)));`

func scroll(first_line:Int, last_line:Int, scroll_amount:Int)
    C_code `btui_scroll(@(Int32(first_line)), @(Int32(last_line)), @(Int32(scroll_amount)));`

func style(
    fg:Color?=none, bg:Color?=none,
    normal:Bool?=none, bold:Bool?=none, faint:Bool?=none, italic:Bool?=none,
    underline:Bool?=none, blink_slow:Bool?=none, blink_fast:Bool?=none,
    reverse:Bool?=none, conceal:Bool?=none, strikethrough:Bool?=none,
    fraktur:Bool?=none, double_underline:Bool?=none, framed:Bool?=none,
    encircled:Bool?=none, overlined:Bool?=none,
)
    if fg
        when fg is RGB(r,g,b) then C_code `btui_set_fg(@r, @g, @b);`
        is Color256(n) then C_code `btui_set_fg256(@n);`
        is Normal then C_code `btui_set_attributes(BTUI_FG_NORMAL);`
        is Black then C_code `btui_set_attributes(BTUI_FG_BLACK);`
        is Red then C_code `btui_set_attributes(BTUI_FG_RED);`
        is Green then C_code `btui_set_attributes(BTUI_FG_GREEN);`
        is Yellow then C_code `btui_set_attributes(BTUI_FG_YELLOW);`
        is Blue then C_code `btui_set_attributes(BTUI_FG_BLUE);`
        is Magenta then C_code `btui_set_attributes(BTUI_FG_MAGENTA);`
        is Cyan then C_code `btui_set_attributes(BTUI_FG_CYAN);`
        is White then C_code `btui_set_attributes(BTUI_FG_WHITE);`

    if bg
        when bg is RGB(r,g,b) then C_code `btui_set_bg(@r, @g, @b);`
        is Color256(n) then C_code `btui_set_bg256(@n);`
        is Normal then C_code `btui_set_attributes(BTUI_BG_NORMAL);`
        is Black then C_code `btui_set_attributes(BTUI_BG_BLACK);`
        is Red then C_code `btui_set_attributes(BTUI_BG_RED);`
        is Green then C_code `btui_set_attributes(BTUI_BG_GREEN);`
        is Yellow then C_code `btui_set_attributes(BTUI_BG_YELLOW);`
        is Blue then C_code `btui_set_attributes(BTUI_BG_BLUE);`
        is Magenta then C_code `btui_set_attributes(BTUI_BG_MAGENTA);`
        is Cyan then C_code `btui_set_attributes(BTUI_BG_CYAN);`
        is White then C_code `btui_set_attributes(BTUI_BG_WHITE);`

    C_code `uint64_t attr = 0;`

    # Disable attributes
    if bold == no or faint then C_code `attr |= BTUI_NO_BOLD_OR_FAINT;`
    if italic == no or fraktur == no then C_code `attr |= BTUI_NO_ITALIC_OR_FRAKTUR;`
    if underline == no then C_code `attr |= BTUI_NO_UNDERLINE;`
    if blink_slow == no or blink_fast == no then C_code `attr |= BTUI_NO_BLINK;`
    if reverse == no then C_code `attr |= BTUI_NO_REVERSE;`
    if conceal == no then C_code `attr |= BTUI_NO_CONCEAL;`
    if strikethrough == no then C_code `attr |= BTUI_NO_STRIKETHROUGH;`
    if framed == no or encircled == no then C_code `attr |= BTUI_NO_FRAMED_OR_ENCIRCLED;`
    if overlined == no then C_code `attr |= BTUI_NO_OVERLINED;`

    # Turn on attributes
    if normal == yes then C_code `attr |= BTUI_NORMAL;`
    if bold == yes then C_code `attr |= BTUI_BOLD;`
    if faint == yes then C_code `attr |= BTUI_FAINT;`
    if italic == yes then C_code `attr |= BTUI_ITALIC;`
    if underline == yes then C_code `attr |= BTUI_UNDERLINE;`
    if blink_slow == yes then C_code `attr |= BTUI_BLINK_SLOW;`
    if blink_fast == yes then C_code `attr |= BTUI_BLINK_FAST;`
    if reverse == yes then C_code `attr |= BTUI_REVERSE;`
    if conceal == yes then C_code `attr |= BTUI_CONCEAL;`
    if strikethrough == yes then C_code `attr |= BTUI_STRIKETHROUGH;`
    if fraktur == yes then C_code `attr |= BTUI_FRAKTUR;`
    if double_underline == yes then C_code `attr |= BTUI_DOUBLE_UNDERLINE;`
    if framed == yes then C_code `attr |= BTUI_FRAMED;`
    if encircled == yes then C_code `attr |= BTUI_ENCIRCLED;`
    if overlined == yes then C_code `attr |= BTUI_OVERLINED;`

    C_code `if (attr) btui_set_attributes(attr);`

func get_bg(->Color?)
    no_color : Color? = none
    response := C_code:Text`
        const char *query_bg = "\\x1b]11;?\\x07";
        write(fileno(bt.out), query_bg, strlen(query_bg));

        char buf[256] = {};
        ssize_t n = read(fileno(bt.in), buf, sizeof(buf)-1);
        if (n < 0) {
            return @(no_color);
        }
        const char *response_prefix = "\\x1b]11;";
        size_t prefix_len = strlen(response_prefix);
        if ((size_t)n < prefix_len || strncmp(buf, response_prefix, prefix_len) != 0) {
            return @(no_color);
        }

        Text$from_strn(buf + prefix_len, n - prefix_len)
    `
    value : Text
    if response.starts_with("rgb:", &value) or response.starts_with("rgba:", &value)
        rgb := value.split("/")
        r := Byte.parse("0x"++rgb[1]!.to(2)) or return none
        g := Byte.parse("0x"++rgb[2]!.to(2)) or return none
        b := Byte.parse("0x"++rgb[3]!.to(2)) or return none
        return Color.RGB(r,g,b)
    else if response.starts_with("#", &value)
        r := Byte.parse("0x"++value.from(1).to(2)) or return none
        g := Byte.parse("0x"++value.from(3).to(4)) or return none
        b := Byte.parse("0x"++value.from(5).to(6)) or return none
        return Color.RGB(r, g, b)
    else if response.starts_with("rgb(", &value) or response.starts_with("rgba(", &value)
        value = value.without_suffix(")")
        rgb := value.split(",")
        r := Byte.parse(rgb[1] or return none) or return none
        g := Byte.parse(rgb[2] or return none) or return none
        b := Byte.parse(rgb[3] or return none) or return none
        return Color.RGB(r,g,b)
    else
        return none

func suspend()
    C_code `btui_suspend();`

func main()
    set_mode(TUI)
    size := get_size()
    style(bold=yes)
    write("Welcome to BTUI", size/2, Center)
    style(bold=no, faint=yes)
    write("Press 'q' or 'Ctrl-c' to quit", size/2 + ScreenVec2(0,1), Center)
    bg := get_bg()
    write("BG: $bg (dark=$((bg or Color.Normal).is_dark()))", size/2 + ScreenVec2(0,3), Center)
    style(bold=no)
    repeat
        key := get_key()
        pos := size/2 + ScreenVec2(0,2)
        clear(Line, pos=pos)
        style(Magenta)
        write("Your input: $key", pos, Center)
        if key == "q" or key == "Ctrl-c"
            stop

    disable()
