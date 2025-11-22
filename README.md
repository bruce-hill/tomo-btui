# BTUI - Bruce's Terminal User Interface

This is an extremely lightweight, but powerful Tomo library for making terminal
user interfaces based on the C library [BTUI](https://github.com/bruce-hill/btui).

## Usage

Add this to your `modules.ini`:

```
[btui]
version=v1.1
git=https://github.com/bruce-hill/tomo-btui
```

## Example program

```
use btui

func main()
    set_mode(TUI)
    size := get_size()
    style(bold=yes)
    write("Welcome to BTUI", size/2, Center)
    style(bold=no, faint=yes)
    write("Press 'q' or 'Ctrl-c' to quit", size/2 + ScreenVec2(0,1), Center)
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
```

A more complex example program can be found at [examples/picker.tm](examples/picker.tm)

## License

This code is licensed under the MIT license with the Commons Clause.
See [LICENSE.md](LICENSE.md) for full details.
