# lua bindings documentation

## table of contents
- [global functions](#global-functions)
- [process manipulation](#process-manipulation)
- [input simulation](#input-simulation)  
- [threading system](#threading-system)
- [data types](#data-types)
- [memory operations](#memory-operations)

## global functions

### core system functions

initialize and manage the scripting system components.

```lua
local process = open_process(1234)
local process = open_process("notepad.exe")

local mouse = open_mouse()
local keyboard = open_keyboard()

thread_init(4)
thread_shutdown()
```

### thread management functions

control threading behavior and monitor thread pool status.

```lua
thread_init(8)

local active_threads = thread_get_count()
local queued_tasks = thread_get_queue_size()

thread_sleep(1000)

local processed = thread_poll(10)

thread_shutdown()
```

### callback registration functions

register functions to be executed at regular intervals using dedicated timer threads.

```lua
local callback_id = register_callback(function()
    print("executed every 100ms")
end, 100)

local monitor_id = register_callback(function()
    local process = open_process("notepad.exe")
    if process.is_valid() then
        local base = process.get_image_base()
        print("base address: " .. string.format("0x%x", base))
    end
end, 1000)

unregister_callback(callback_id)

local count = get_active_callback_count()
print("active callbacks: " .. count)

clear_all_callbacks()
```

### utility functions

additional utility functions for enhanced scripting capabilities including bitwise operations, enhanced math, string processing, and table manipulation.

## bitwise operations

complete bitwise manipulation functions for memory and data processing.

```lua
local value = 0xFF00

local left_shifted = bit.lshift(value, 8)
local right_shifted = bit.rshift(value, 8)
local arith_shifted = bit.arshift(-1024, 2)

local masked = bit.band(value, 0xF0F0)
local combined = bit.bor(value, 0x0F0F)
local xored = bit.bxor(value, 0xFFFF)
local inverted = bit.bnot(value)
local rotated_right = bit.rotr(value, 4)
local rotated_left = bit.rotl(value, 4)

print("original: " .. string.format("0x%08x", value))
print("left shift <<8: " .. string.format("0x%08x", left_shifted))
print("right shift >>8: " .. string.format("0x%08x", right_shifted))
print("arithmetic shift: " .. string.format("0x%08x", arith_shifted))
print("bitwise and: " .. string.format("0x%08x", masked))
print("bitwise or: " .. string.format("0x%08x", combined))
print("bitwise xor: " .. string.format("0x%08x", xored))
print("bitwise not: " .. string.format("0x%08x", inverted))
print("rotate right 4: " .. string.format("0x%016x", rotated_right))
print("rotate left 4: " .. string.format("0x%016x", rotated_left))

-- rotation examples with 32-bit safe values
local safe_32bit = 0x12345678
local rotr_safe = bit.rotr(safe_32bit, 8)
local rotl_safe = bit.rotl(safe_32bit, 8)
print("32-bit safe rotation:")
print("original: " .. string.format("0x%08x", safe_32bit))
print("rotr 8: " .. string.format("0x%08x", rotr_safe))
print("rotl 8: " .. string.format("0x%08x", rotl_safe))

-- important: lua 5.1/luajit uses double-precision floating point for numbers
-- this means values larger than 2^53 (9,007,199,254,740,992) may lose precision
-- bitwise operations work correctly but very large 64-bit values may not roundtrip perfectly
-- for guaranteed precision, use values within the 32-bit range (0x00000000 to 0xFFFFFFFF)
-- or construct large values using bit operations: bit.bor(bit.lshift(high32, 32), low32)
```

## enhanced math functions

additional math utilities for number type checking and conversion.

```lua
local float_val = 42.5
local int_val = 42

local converted = math.tointeger(float_val)
local int_converted = math.tointeger(int_val)

print("math.tointeger(42.5): " .. tostring(converted))
print("math.tointeger(42): " .. tostring(int_converted))

print("math.type(42.5): " .. math.type(float_val))
print("math.type(42): " .. math.type(int_val))

print("math.ult(10, 20): " .. tostring(math.ult(10, 20)))
print("math.ult(20, 10): " .. tostring(math.ult(20, 10)))

print("max integer: " .. tostring(math.maxinteger))
print("min integer: " .. tostring(math.mininteger))
```

## string pack and unpack

binary data serialization and deserialization with format specifiers.

```lua
local packed_data = string.pack("bBhHiIlLjJfd", 
    -128, 255, -32768, 65535, 
    -2147483648, 4294967295, 
    -2147483648, 4294967295,
    -9223372036854775808, 18446744073709551615,
    3.14159, 2.718281828)

print("packed size: " .. #packed_data .. " bytes")

local unpacked = string.unpack("bBhHiIlLjJfd", packed_data)
for i = 1, #unpacked - 1 do
    print("value " .. i .. ": " .. tostring(unpacked[i]))
end
print("next position: " .. unpacked[#unpacked])
```

## table manipulation

efficient table operations for data movement and management.

```lua
local source_table = {10, 20, 30, 40, 50}
local destination_table = {1, 2, 3, 4, 5, 6, 7, 8}

table.move(source_table, 2, 4, 3, destination_table)

print("after table.move(src, 2, 4, 3, dst):")
for i, v in ipairs(destination_table) do
    print("dst[" .. i .. "] = " .. v)
end

local copy_table = {}
table.move(source_table, 1, #source_table, 1, copy_table)
print("copied table length: " .. #copy_table)
```

## utf8 string processing

unicode text handling and manipulation functions.

```lua
local text = "hello world"
local unicode_text = "café"

local char_count = utf8.len(text)
local unicode_count = utf8.len(unicode_text)

print("utf8.len('hello world'): " .. char_count)
print("utf8.len('café'): " .. unicode_count)

local smiley = utf8.char(0x1F600)
local heart = utf8.char(0x2764)
local combined = utf8.char(0x1F600, 0x2764, 0x1F60D)

print("smiley emoji: " .. smiley)
print("combined emojis: " .. combined)

local codepoints = utf8.codepoint("hello")
print("first codepoint of 'hello': " .. codepoints[1])

local h_codepoint = utf8.codepoint("hello", 1)
local e_codepoint = utf8.codepoint("hello", 2)
print("h codepoint: " .. h_codepoint[1])
print("e codepoint: " .. e_codepoint[1])
```

## format specifiers reference

string.pack and string.unpack format characters:

- b: signed 8-bit integer
- B: unsigned 8-bit integer  
- h: signed 16-bit integer
- H: unsigned 16-bit integer
- i/l: signed 32-bit integer
- I/L: unsigned 32-bit integer
- j: signed 64-bit integer
- J: unsigned 64-bit integer
- f: 32-bit float
- d: 64-bit double

## process manipulation

### opening processes

open a process by process id or name to interact with its memory space.

```lua
local process = open_process(1234)
local process = open_process("notepad.exe")
```

### process validation

check if a process handle is valid before performing operations.

```lua
local process = open_process("notepad.exe")
if process.is_valid() then
    print("process opened successfully")
end
```

### getting process information

retrieve the base address of the main module and specific module information.

```lua
local process = open_process("notepad.exe")
local base_address = process.get_image_base()
print("base address: " .. string.format("0x%x", base_address))

local module = process.get_module("kernel32.dll")
if module then
    print("module base: " .. string.format("0x%x", module.base()))
    print("module size: " .. module.size())
end
```

### reading memory

read different data types from process memory using typed read operations.

```lua
local process = open_process("game.exe")
local address = 0x140001000

local health = process.read.float(address)
local player_id = process.read.int32(address + 0x10)
local position_x = process.read.double(address + 0x20)
local flag = process.read.uint8(address + 0x30)

print("health: " .. health)
print("player id: " .. player_id)
```

### reading strings

read null-terminated strings and wide strings from memory.

```lua
local process = open_process("game.exe")
local name_address = 0x140002000

local player_name = process.read_string(name_address)
local player_name_limited = process.read_string(name_address, 32)

local wide_name = process.read_wstring(name_address + 0x100)
```

### reading vectors

read 2d, 3d, and 4d vectors with different data types.

```lua
local process = open_process("game.exe")
local vector_address = 0x140003000

local position = process.read_vec3.float(vector_address)
print("x: " .. position.x .. ", y: " .. position.y .. ", z: " .. position.z)

local velocity = process.read_vec2.double(vector_address + 0x20)
local color = process.read_vec4.uint8(vector_address + 0x40)
```

### reading raw data

read raw bytes from memory into lua tables.

```lua
local process = open_process("game.exe")
local data = process.read_raw(0x140001000, 64)

if data then
    for i = 1, #data do
        print("byte " .. i .. ": " .. data[i])
    end
end
```

### writing memory

write different data types to process memory.

```lua
local process = open_process("game.exe")
local address = 0x140001000

local success = process.write.float(address, 100.0)
process.write.int32(address + 0x10, 9999)
process.write.uint8(address + 0x20, 255)

if success then
    print("memory write successful")
end
```

### writing raw data

write raw byte arrays to memory.

```lua
local process = open_process("game.exe")
local data = {0x90, 0x90, 0x90, 0x90}
local success = process.write_raw(0x140001000, data)
```

### memory buffers

use memory buffers for efficient reading and writing operations.

```lua
local process = open_process("game.exe")
local buffer = process.read_buffer(0x140001000, 256)

if buffer.is_valid() then
    print("buffer size: " .. buffer.size())
    
    local value = buffer.get.float(0)
    local position = buffer.get_vec3(16)
    local name = buffer.get_string(64, 32)
end

local new_buffer = membuffer(1024)
local read_success = process.read_into_buffer(0x140001000, new_buffer, 512)
local write_success = process.write_from_buffer(0x140001000, buffer)
```

### advanced buffer operations

read into specific buffer regions and handle partial data.

```lua
local process = open_process("game.exe")
local buffer = membuffer(1024)

local success = process.read_into_buffer_region(0x140001000, buffer, 64, 256)

if success then
    local data_chunk = buffer.get_bytes(64, 128)
    for i, byte_val in ipairs(data_chunk) do
        print("byte " .. i .. ": " .. byte_val)
    end
end
```

### complete process method reference

all available process handle methods for memory manipulation.

```lua
local process = open_process("game.exe")

if process.is_valid() then
    local base = process.get_image_base()
    local module = process.get_module("kernel32.dll")
    
    local raw_data = process.read_raw(base, 256)
    local buffer = process.read_buffer(base, 512)
    
    process.read_into_buffer(base, buffer)
    process.read_into_buffer_region(base, buffer, 128, 256)
    
    local name = process.read_string(base + 0x100)
    local wide_name = process.read_wstring(base + 0x200)
    
    local pos2d = process.read_vec2.float(base + 0x300)
    local pos3d = process.read_vec3.float(base + 0x310)
    local color = process.read_vec4.uint8(base + 0x320)
    
    process.write_raw(base, {0x90, 0x90})
    process.write_from_buffer(base, buffer)
end
```

## input simulation

### mouse operations

simulate mouse movements, clicks, and scrolling.

```lua
local mouse = open_mouse()

if mouse.is_valid() then
    mouse.mouse_move(100, 50)
    
    mouse.mouse_button(1)
    
    mouse.scroll_vertical(120)
    mouse.scroll_horizontal(-120)
end
```

### keyboard operations

simulate key presses, character input, and string typing.

```lua
local keyboard = open_keyboard()

if keyboard.is_valid() then
    keyboard.key_down(0x41)
    keyboard.key_up(0x41)
    
    keyboard.key_press(0x0d, 100)
    
    keyboard.char_press("a", 50)
    
    keyboard.type_string("hello world", 50)
end
```

### virtual key codes

common virtual key codes for keyboard simulation:

- enter: 0x0d
- space: 0x20
- escape: 0x1b
- tab: 0x09
- shift: 0x10
- ctrl: 0x11
- alt: 0x12
- a-z: 0x41-0x5a
- 0-9: 0x30-0x39

## threading system

### thread pool initialization

initialize the thread pool with a specific number of threads.

```lua
thread_init(4)

local thread_count = thread_get_count()
print("active threads: " .. thread_count)
```

### task submission

submit tasks to the thread pool for background execution.

```lua
thread_init()

local pool = thread_pool.new()

pool.submit_task(function()
    thread_sleep(1000)
    print("background task completed")
end)

local queue_size = pool.get_queue_size()
local thread_count = pool.get_thread_count()
print("tasks in queue: " .. queue_size)
print("worker threads: " .. thread_count)
```

### polling and cleanup

poll for completed tasks and shutdown the thread system.

```lua
while true do
    local processed = thread_poll(10)
    if processed == 0 then
        thread_sleep(16)
    end
end

thread_shutdown()
```

### interval callbacks

register callbacks for continuous monitoring and automation tasks.

```lua
thread_init()

local health_monitor = register_callback(function()
    local process = open_process("game.exe")
    if process.is_valid() then
        local health = process.read.float(0x12345678)
        if health < 50 then
            print("low health detected: " .. health)
        end
    end
end, 500)

local position_tracker = register_callback(function()
    local process = open_process("game.exe")
    if process.is_valid() then
        local pos = process.read_vec3.float(0x87654321)
        print("position: " .. pos.x .. ", " .. pos.y .. ", " .. pos.z)
    end
end, 1000)

while get_active_callback_count() > 0 do
    thread_poll()
    thread_sleep(16)
end
```

## data types

### vec2 operations

2d vector for position, velocity, and direction calculations.

```lua
local pos = vec2.new(10.0, 20.0)
local vel = vec2.new(1.5, -2.0)

local new_pos = pos + vel
local scaled = pos * 2.0
local distance = pos.distance(vel)
local length = pos.length()
local length_sq = pos.length_squared()

pos.normalize()
local normalized = pos.normalized()

local dot_product = pos.dot(vel)

print("x: " .. pos.x .. ", y: " .. pos.y)
```

### vec3 operations

3d vector with additional z-component and cross product support.

```lua
local pos = vec3.new(1.0, 2.0, 3.0)
local dir = vec3.new(0.0, 1.0, 0.0)

local result = pos + dir
local scaled = pos * 0.5
local length = pos.length()
local length_sq = pos.length_squared()
local distance = pos.distance(dir)

local cross = pos.cross(dir)
local dot = pos.dot(dir)

pos.normalize()
local normalized = pos.normalized()

print("position: " .. pos.x .. ", " .. pos.y .. ", " .. pos.z)
```

### vec4 operations

4d vector for colors, quaternions, and homogeneous coordinates.

```lua
local color = vec4.new(1.0, 0.5, 0.2, 1.0)
local quat = vec4.new(0.0, 0.0, 0.0, 1.0)

local mixed = color + quat
local scaled = color * 0.8
local length = color.length()
local length_sq = color.length_squared()
local distance = color.distance(quat)
local dot = color.dot(quat)

color.normalize()
local normalized = color.normalized()

print("rgba: " .. color.x .. ", " .. color.y .. ", " .. color.z .. ", " .. color.w)
```

### memory buffer operations

efficient memory management for reading and parsing data.

```lua
local buffer = membuffer(1024)

if buffer.is_valid() then
    local health = buffer.get.float(0)
    local player_id = buffer.get.int32(4)
    local position = buffer.get_vec3(16)
    local name = buffer.get_string(64)
    local wide_text = buffer.get_wstring(128, 64)
    
    buffer.resize(2048)
    buffer.clear()
end
```

### buffer vector operations

read vector data directly from memory buffers.

```lua
local buffer = membuffer(256)

local pos2d = buffer.get_vec2(0)
local pos3d = buffer.get_vec3(8)
local color = buffer.get_vec4(20)

print("2d position: " .. pos2d.x .. ", " .. pos2d.y)
print("3d position: " .. pos3d.x .. ", " .. pos3d.y .. ", " .. pos3d.z)
```

### buffer byte operations

extract raw byte sequences from buffers.

```lua
local buffer = membuffer(512)

local header_bytes = buffer.get_bytes(0, 16)
local data_chunk = buffer.get_bytes(64, 128)

for i, byte_val in ipairs(header_bytes) do
    print("header byte " .. i .. ": " .. string.format("0x%02x", byte_val))
end
```

### buffer string operations

read strings and wide strings with optional length limits.

```lua
local buffer = membuffer(1024)

local player_name = buffer.get_string(0)
local player_name_limited = buffer.get_string(0, 32)

local wide_name = buffer.get_wstring(64)
local wide_name_limited = buffer.get_wstring(64, 16)
```

## memory operations

### data type sizes

understanding memory layout for proper offset calculations:

- int8/uint8: 1 byte
- int16/uint16: 2 bytes  
- int32/uint32: 4 bytes
- int64/uint64: 8 bytes
- float: 4 bytes
- double: 8 bytes
- vec2: 8 bytes (2 floats)
- vec3: 12 bytes (3 floats)
- vec4: 16 bytes (4 floats)

### pointer following

reading addresses and following pointer chains.

```lua
local process = open_process("game.exe")
local base = process.get_image_base()

local ptr1 = process.read.uint64(base + 0x1000)
local ptr2 = process.read.uint64(ptr1 + 0x10)
local final_value = process.read.float(ptr2 + 0x20)
```

### structure reading

reading complex data structures from memory.

```lua
local process = open_process("game.exe")
local player_base = 0x140001000

local player = {
    health = process.read.float(player_base + 0x00),
    armor = process.read.float(player_base + 0x04),
    position = process.read_vec3.float(player_base + 0x10),
    velocity = process.read_vec3.float(player_base + 0x1c),
    name = process.read_string(player_base + 0x28, 32)
}

print("health: " .. player.health)
print("position: " .. player.position.x .. ", " .. player.position.y .. ", " .. player.position.z)
```

### batch operations

efficiently reading multiple values using buffers.

```lua
local process = open_process("game.exe")
local buffer = process.read_buffer(0x140001000, 256)

if buffer.is_valid() then
    local stats = {
        health = buffer.get.float(0),
        mana = buffer.get.float(4),
        experience = buffer.get.int32(8),
        level = buffer.get.int16(12),
        position = buffer.get_vec3(16),
        name = buffer.get_string(32, 64)
    }
end
```