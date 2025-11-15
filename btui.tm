
use ./btui.c

enum Color(Normal, Black, Red, Green, Yellow, Blue, Magenta, Cyan, White, RGB(r,g,b:Byte))

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

func move_cursor(pos:ScreenVec2)
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

func set_fg(color:Color)
    when color is RGB(r,g,b) then C_code `btui_set_fg(@r, @g, @b);`
    is Normal then C_code `btui_set_attributes(BTUI_FG_NORMAL);`
    is Black then C_code `btui_set_attributes(BTUI_FG_BLACK);`
    is Red then C_code `btui_set_attributes(BTUI_FG_RED);`
    is Green then C_code `btui_set_attributes(BTUI_FG_GREEN);`
    is Yellow then C_code `btui_set_attributes(BTUI_FG_YELLOW);`
    is Blue then C_code `btui_set_attributes(BTUI_FG_BLUE);`
    is Magenta then C_code `btui_set_attributes(BTUI_FG_MAGENTA);`
    is Cyan then C_code `btui_set_attributes(BTUI_FG_CYAN);`
    is White then C_code `btui_set_attributes(BTUI_FG_WHITE);`

func set_bg(color:Color)
    when color is RGB(r,g,b) then C_code `btui_set_bg(@r, @g, @b);`
    is Normal then C_code `btui_set_attributes(BTUI_BG_NORMAL);`
    is Black then C_code `btui_set_attributes(BTUI_BG_BLACK);`
    is Red then C_code `btui_set_attributes(BTUI_BG_RED);`
    is Green then C_code `btui_set_attributes(BTUI_BG_GREEN);`
    is Yellow then C_code `btui_set_attributes(BTUI_BG_YELLOW);`
    is Blue then C_code `btui_set_attributes(BTUI_BG_BLUE);`
    is Magenta then C_code `btui_set_attributes(BTUI_BG_MAGENTA);`
    is Cyan then C_code `btui_set_attributes(BTUI_BG_CYAN);`
    is White then C_code `btui_set_attributes(BTUI_BG_WHITE);`

func suspend()
    C_code `btui_suspend();`

struct TextAttributes(
    Normal=no, Bold=no, Faint=no, Italic=no, Underline=no, BlinkSlow=no,
    BlinkFast=no, Reverse=no, Conceal=no, Strikethrough=no, Fraktur=no,
    DoubleUnderline=no, Framed=no, Encircled=no, Overlined=no,
)

func enable_attributes(attributes:TextAttributes)
    C_code `uint64_t attr = 0;`
    if attributes.Normal then C_code `attr |= BTUI_NORMAL;`
    if attributes.Bold then C_code `attr |= BTUI_BOLD;`
    if attributes.Faint then C_code `attr |= BTUI_FAINT;`
    if attributes.Italic then C_code `attr |= BTUI_ITALIC;`
    if attributes.Underline then C_code `attr |= BTUI_UNDERLINE;`
    if attributes.BlinkSlow then C_code `attr |= BTUI_BLINK_SLOW;`
    if attributes.BlinkFast then C_code `attr |= BTUI_BLINK_FAST;`
    if attributes.Reverse then C_code `attr |= BTUI_REVERSE;`
    if attributes.Conceal then C_code `attr |= BTUI_CONCEAL;`
    if attributes.Strikethrough then C_code `attr |= BTUI_STRIKETHROUGH;`
    if attributes.Fraktur then C_code `attr |= BTUI_FRAKTUR;`
    if attributes.DoubleUnderline then C_code `attr |= BTUI_DOUBLE_UNDERLINE;`
    if attributes.Framed then C_code `attr |= BTUI_FRAMED;`
    if attributes.Encircled then C_code `attr |= BTUI_ENCIRCLED;`
    if attributes.Overlined then C_code `attr |= BTUI_OVERLINED;`
    C_code `btui_set_attributes(attr);`

func disable_attributes(attributes:TextAttributes)
    C_code `uint64_t attr = 0;`
    if attributes.Bold or attributes.Faint then C_code `attr |= BTUI_NO_BOLD_OR_FAINT;`
    if attributes.Italic or attributes.Fraktur then C_code `attr |= BTUI_NO_ITALIC_OR_FRAKTUR;`
    if attributes.Underline then C_code `attr |= BTUI_NO_UNDERLINE;`
    if attributes.BlinkSlow or attributes.BlinkFast then C_code `attr |= BTUI_NO_BLINK;`
    if attributes.Reverse then C_code `attr |= BTUI_NO_REVERSE;`
    if attributes.Conceal then C_code `attr |= BTUI_NO_CONCEAL;`
    if attributes.Strikethrough then C_code `attr |= BTUI_NO_STRIKETHROUGH;`
    if attributes.Framed or attributes.Encircled then C_code `attr |= BTUI_NO_FRAMED_OR_ENCIRCLED;`
    if attributes.Overlined then C_code `attr |= BTUI_NO_OVERLINED;`
    C_code `btui_set_attributes(attr);`

func main()
    set_mode(TUI)
    size := get_size()
    enable_attributes(TextAttributes(Bold=yes))
    write("Hello world!", size/2, Center)
    disable_attributes(TextAttributes(Bold=yes))
    repeat
        key := get_key()
        pos := size/2 + ScreenVec2(0,1)
        clear(Line, pos=pos)
        set_fg(Magenta)
        write("Your input: $key", pos, Center)
        if key == "q"
            stop

    disable()
