# An example program to pick a line of input from stdin
use ../btui.tm

_HELP := "
    A simple picker program
"

struct Picker(
    options:[Text],
    prompt=">",
    query="",
    offset:Int=0,
    max_height:Int?=20,
)
    func draw(self:Picker)
        live_options := self.live_options()
        if chosen := self.chosen()
            write("\r\033[33;1m$(self.prompt)\033[m \033[2m$(chosen.replace(self.query, "\033[0;1m$(self.query)\033[0;2m"))\033[m\033[K")
        else
            write("\r\033[33;1m$(self.prompt)\033[m \033[31m$(self.query)\033[m\033[K")

        size := get_size()
        height := (self.max_height or size.y) _min_ size.y
        shown_options := live_options.to(height-1)
        for opt in shown_options
            write("\r\n\033[K$opt")
        clear(Below)
        move_cursor(ScreenVec2(0, -shown_options.length), relative=yes)
        flush()

    func update(self:&Picker)
        key := get_key()
        when key
        is "Ctrl-c"
            write("\r")
            clear(Right)
            clear(Below)
            disable()
            exit(code=1)
        is "Enter"
            write("\r")
            clear(Right)
            clear(Below)
            disable()
            if chosen := self.chosen()
                say(chosen)
                exit(code=0)
            else
                exit(code=1)
        is "Backspace"
            self.query = self.query.to(-2)
        is "Space"
            self.query ++= " "
        is "Up", "Shift-Tab"
            self.offset -= 1
        is "Down", "Tab"
            self.offset += 1
        else if key.length == 1
            self.query ++= key

    func live_options(self:Picker -> [Text])
        return [o for o in self.options if o.has(self.query)]

    func chosen(self:Picker -> Text?)
        live_options := self.live_options()
        if live_options.length > 0
            return live_options[(1 + self.offset) mod1 live_options.length]
        else
            return none

func main(choices:Path=(/dev/stdin), prompt|p=">", query|q="", max_height|H:Int?=20)
    lines := choices.lines() or fail("No such file: $choices")
    lines = [line for line in lines if line.length > 0]
    picker := Picker(
        options=lines,
        prompt=prompt,
        query=query,
        max_height=max_height,
    )
    set_mode(Normal)
    hide_cursor()
    picker.draw()
    repeat
        picker.draw()
        picker.update()
    disable()
