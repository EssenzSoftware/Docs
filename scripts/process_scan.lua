local target = ... or "notepad.exe"
local p = open_process(target)
if not p.is_valid() then
    print("failed to open process")
    return
end
local base = p.get_image_base()
print("base " .. string.format("0x%x", base))
local m = p.get_module("kernel32.dll")
if m then
    print("module base " .. string.format("0x%x", m.base()))
    print("module size " .. tostring(m.size()))
end
local buf = p.read_buffer(base, 256)
if buf.is_valid() then
    print("buffer size " .. tostring(buf.size()))
    local bytes = buf.get_bytes(0, 8)
    if bytes then
        for i = 1, #bytes do
            print("byte " .. i .. " " .. string.format("0x%02x", bytes[i]))
        end
    end
end
