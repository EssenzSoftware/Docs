local k = open_keyboard()
local m = open_mouse()
if k.is_valid() then
    k.type_string("hello world", 50)
    k.key_press(0x0d, 100)
end
if m.is_valid() then
    m.mouse_move(100, 50)
    m.mouse_button(1)
    m.scroll_vertical(120)
    m.scroll_horizontal(-120)
end
