# lua bindings documentation

## table of contents
- [global functions](#global-functions)
- [process manipulation](#process-manipulation)
- [input simulation](#input-simulation)  
- [threading system](#threading-system)
- [windows api](#windows-api)
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

register functions to be executed at regular intervals using dedicated timer threads. callbacks are fully thread-safe and support upvalue captures.

**execution model:**

1. a background scheduler thread monitors registered callbacks and their intervals
2. when a callback's interval expires, it's posted to the main queue
3. the callback executes on the main thread when `thread_poll()` is called
4. this ensures thread-safe access to the lua state and upvalues

```lua
local callback_id = register_callback(function()
    print("executed every 100ms")
end, 100)

local tick_count = 0
local last_report = os.time()

local monitor_id = register_callback(function()
    tick_count = tick_count + 1
    
    local process = open_process("notepad.exe")
    if process.is_valid() then
        local base = process.get_image_base()
        
        if os.time() - last_report >= 1 then
            print("ticks: " .. tick_count .. ", base: " .. string.format("0x%x", base))
            last_report = os.time()
        end
    end
end, 1)

unregister_callback(callback_id)

local count = get_active_callback_count()
print("active callbacks: " .. count)

clear_all_callbacks()
```

**callback intervals:**

the interval parameter specifies how often the callback should execute in milliseconds. the scheduler posts callbacks to the queue at these intervals, but actual execution depends on how frequently you call `thread_poll()`. see the polling section for details on balancing responsiveness and efficiency.

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

local safe_32bit = 0x12345678
local rotr_safe = bit.rotr(safe_32bit, 8)
local rotl_safe = bit.rotl(safe_32bit, 8)
print("32-bit safe rotation:")
print("original: " .. string.format("0x%08x", safe_32bit))
print("rotr 8: " .. string.format("0x%08x", rotr_safe))
print("rotl 8: " .. string.format("0x%08x", rotl_safe))
```

**important note on precision:** lua 5.1/luajit uses double-precision floating point for all numbers. values larger than 2^53 (9,007,199,254,740,992) may lose precision. bitwise operations work correctly, but very large 64-bit values may not roundtrip perfectly. for guaranteed precision, use values within the 32-bit range (0x00000000 to 0xFFFFFFFF) or construct large values using bit operations: `bit.bor(bit.lshift(high32, 32), low32)`

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

## clipboard operations

read and write text data to the system clipboard.

### get_clipboard_text

**signature:** `get_clipboard_text()`

get the current text content from the clipboard.

**parameters:** none

**returns:**
- string - clipboard text content, or nil if clipboard is empty or inaccessible

```lua
local text = get_clipboard_text()
if text then
    print("clipboard contains: " .. text)
else
    print("clipboard is empty or inaccessible")
end
```

### set_clipboard_text

**signature:** `set_clipboard_text(text)`

set the clipboard to contain the specified text.

**parameters:**
- `text` (string) - text to copy to clipboard

**returns:**
- boolean - true if successful

```lua
local success = set_clipboard_text("hello from lua!")
if success then
    print("text copied to clipboard")
end
```

### clear_clipboard

**signature:** `clear_clipboard()`

clear all content from the clipboard.

**parameters:** none

**returns:**
- boolean - true if successful

```lua
if clear_clipboard() then
    print("clipboard cleared")
end
```

### clipboard examples

**automatic data logging:**

```lua
local function log_to_clipboard(data)
    local existing = get_clipboard_text() or ""
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local new_content = existing .. "\n[" .. timestamp .. "] " .. data
    set_clipboard_text(new_content)
end

log_to_clipboard("player health: 100")
log_to_clipboard("position: 123.45, 678.90")
```

**clipboard monitor:**

```lua
thread_init(2)

local last_clipboard = get_clipboard_text()

local monitor = register_callback(function()
    local current = get_clipboard_text()
    
    if current and current ~= last_clipboard then
        print("clipboard changed to: " .. current)
        last_clipboard = current
    end
end, 500)

for i = 1, 120 do
    thread_poll(0, 500)
end

unregister_callback(monitor)
thread_shutdown()
```

**process data to clipboard:**

```lua
local proc = open_process("game.exe")
if proc and proc.is_valid() then
    local base = proc.get_image_base()
    local health = proc.read.float(base + 0x1000)
    local position = proc.read_vec3.float(base + 0x2000)
    
    local report = string.format(
        "Game Stats\n" ..
        "Health: %.2f\n" ..
        "Position: %.2f, %.2f, %.2f\n" ..
        "Base Address: 0x%X",
        health,
        position.x, position.y, position.z,
        base
    )
    
    if set_clipboard_text(report) then
        print("stats copied to clipboard")
        play_sound("sounds/success.wav")
    end
end
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

### reading pointer chains

automatically follow pointer chains to resolve final addresses. returns the final address after following all pointers, or nil if any pointer in the chain is null or invalid.

**signature:** `process.read_chain(base_address, offsets)`

**parameters:**
- `base_address` (number) - starting address to begin the chain
- `offsets` (table) - array of offsets to apply at each step

**returns:**
- number - final address after following the chain, or nil if chain is invalid

**behavior:**
1. reads pointer at `base_address`
2. adds first offset to that pointer
3. reads pointer at resulting address
4. adds next offset and repeats
5. returns final address (does not read value at final address)

```lua
local process = open_process("game.exe")
local base = process.get_image_base()

-- follow chain: [base+0x1000] + 0x10 -> [result] + 0x20 -> final address
local player_addr = process.read_chain(base + 0x1000, {0x10, 0x20})

if player_addr then
    -- now read typed values from the resolved address
    local health = process.read.float(player_addr)
    local mana = process.read.float(player_addr + 0x4)
    local position = process.read_vec3.float(player_addr + 0x10)
else
    print("pointer chain is broken or null")
end
```

**caching example:**

```lua
-- resolve chain once and cache for performance
local entity_manager = process.read_chain(base + 0x5000, {0x8, 0x18, 0x0})

if entity_manager then
    -- use cached address multiple times
    while true do
        local entity_count = process.read.int32(entity_manager)
        print("entities: " .. entity_count)
        sleep(1000)
    end
end
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

**note on lua syntax:** for typed operations like `buffer.get.float` or `process.read.int32`, both dot notation and bracket notation are equivalent in lua:
- `buffer.get.float(0)` is the same as `buffer.get["float"](0)`
- `process.read.int32(addr)` is the same as `process.read["int32"](addr)`
- `process.write.uint64(addr, val)` is the same as `process.write["uint64"](addr, val)`

dot notation is the recommended lua convention and used throughout this documentation.

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
    
    -- pointer chain resolution
    local final_addr = process.read_chain(base + 0x1000, {0x10, 0x20, 0x8})
    
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

### keystate checking

check the current state of keyboard keys and mouse buttons without simulating input.

**is_key_down**

**signature:** `is_key_down(vk_code)`

returns true while the key is currently held (level-triggered). useful for continuous actions.

**parameters:**
- `vk_code` (number) - virtual key code to check

**returns:**
- boolean - true while the key is held down

```lua
local VK_SPACE = 0x20

while true do
    if is_key_down(VK_SPACE) then
        print("space is being held (fires every frame)")
    end
    
    thread_sleep(1)
end
```

**is_key_toggled**

**signature:** `is_key_toggled(vk_code)`

returns true when a key's toggle state is active (e.g., caps lock, num lock, scroll lock).

**parameters:**
- `vk_code` (number) - virtual key code to check

**returns:**
- boolean - true if the toggle state is active

```lua
local VK_CAPITAL = 0x14
local VK_NUMLOCK = 0x90
local VK_SCROLL = 0x91

if is_key_toggled(VK_CAPITAL) then
    print("caps lock is ON")
end

if is_key_toggled(VK_NUMLOCK) then
    print("num lock is ON")
end
```

**checking mouse buttons:**

mouse buttons use the same `is_key_down` function since they are also virtual key codes.

```lua
local VK_LBUTTON = 0x01
local VK_RBUTTON = 0x02
local VK_MBUTTON = 0x04

while true do
    if is_key_down(VK_LBUTTON) then
        print("left mouse button is being held")
    end
    
    if is_key_down(VK_RBUTTON) then
        print("right mouse button is being held")
    end
    
    if is_key_down(VK_MBUTTON) then
        print("middle mouse button is being held")
    end
    
    thread_sleep(1)
end
```

**input state examples:**

```lua
local VK_SHIFT = 0x10
local VK_CTRL = 0x11
local VK_SPACE = 0x20
local VK_LBUTTON = 0x01
local VK_RBUTTON = 0x02

thread_init(2)

local input_callback = register_callback(function()
    if is_key_down(VK_SPACE) then
        print("space is being held")
    end
    
    if is_key_down(VK_CTRL) and is_key_down(VK_SHIFT) then
        print("ctrl+shift held together")
    end
    
    if is_key_down(VK_LBUTTON) and is_key_down(VK_CTRL) then
        print("ctrl+left mouse button held")
    end
    
    if is_key_down(VK_LBUTTON) and is_key_down(VK_RBUTTON) then
        print("both mouse buttons held")
    end
end, 1)

for i = 1, 1000 do
    thread_poll(0, 10)
end

unregister_callback(input_callback)
thread_shutdown()
```
```

### virtual key codes

https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes
common virtual key codes for keyboard simulation and state checking:

- enter: 0x0d
- space: 0x20
- escape: 0x1b
- tab: 0x09
- shift: 0x10
- ctrl: 0x11
- alt: 0x12
- caps lock: 0x14
- num lock: 0x90
- scroll lock: 0x91
- a-z: 0x41-0x5a
- 0-9: 0x30-0x39
- f1-f12: 0x70-0x7b
- numpad 0-9: 0x60-0x69
- arrow keys: left 0x25, up 0x26, right 0x27, down 0x28
- mouse buttons: left 0x01, right 0x02, middle 0x04

## threading system

### thread pool initialization

initialize the thread pool with a specific number of threads.

```lua
thread_init(4)

local thread_count = thread_get_count()
print("active threads: " .. thread_count)
```

### async execution with callbacks

the primary way to execute code asynchronously is through the callback system. callbacks are scheduled by a background thread and executed thread-safely on the main thread.

```lua
thread_init(4)

local callback_id = register_callback(function()
    print("async execution every 100ms")
end, 100)

local counter = 0
local data_callback = register_callback(function()
    counter = counter + 1
    print("counter: " .. counter)
end, 50)

thread_sleep(5000)
unregister_callback(callback_id)
unregister_callback(data_callback)
```

**note:** the thread pool is used internally by the callback scheduler. direct task submission via `thread_pool` is reserved for internal use.

### polling and cleanup

`thread_poll(max_callbacks, timeout_ms)` processes callbacks from the main queue. both parameters are optional.

**parameters:**
- `max_callbacks` - maximum number of callbacks to process (0 = unlimited, default = 0)
- `timeout_ms` - milliseconds to wait for callbacks before returning (0 = no wait, default = 0)

**how it works:**

the callback system uses a three-component architecture for thread-safe execution. a background scheduler thread continuously monitors all registered callbacks and their timing intervals. when a callback's next execution time arrives, the scheduler posts it to a thread-safe queue on the main thread. your application must call `thread_poll()` regularly to drain this queue and execute the waiting callbacks.

the timeout parameter controls how long `thread_poll()` will wait for callbacks to arrive. it uses a condition variable internally, which allows the main thread to sleep efficiently until the scheduler posts new callbacks or the timeout expires. this prevents the cpu-intensive busy-waiting pattern where the thread continuously checks for work.

**thread safety guarantee:** all callback code executes on the main thread where the lua state lives. this is a fundamental requirement because lua states are not thread-safe for concurrent access. the background scheduler never executes lua code directly - it only handles timing and queueing. this architecture allows callbacks to safely capture and modify upvalues, access the lua state, and call any lua api functions without synchronization concerns.

**batching behavior:**

the system intentionally batches callbacks for improved cpu efficiency and cache locality. when the scheduler thread checks for ready callbacks, it collects all callbacks whose execution time has passed and posts them to the queue together. additionally, any callbacks that become ready during your `thread_poll()` timeout period will be included in the same batch.

this batching mechanism significantly reduces context switching overhead and improves performance. consider a scenario with a 1ms callback interval and a 50ms poll timeout: approximately 50 callback invocations will queue up and execute together when `thread_poll()` is called. while each individual callback may execute slightly later than its exact scheduled time, the overall execution rate remains accurate (1000 executions per second), just delivered in efficient batches rather than individually.

the trade-off is straightforward: shorter poll timeouts provide lower latency for individual callback executions but increase cpu overhead from frequent polling. longer timeouts improve efficiency through batching but increase the maximum delay before a callback executes.

**example patterns:**

non-blocking poll processes all queued callbacks immediately and returns:
```lua
thread_poll()
```

poll with timeout waits up to 16ms for callbacks before returning (ideal for 60 FPS game loops):
```lua
thread_poll(0, 16)
```

limited batch with timeout processes maximum 10 callbacks and waits up to 50ms (useful when interleaving callback processing with other work):
```lua
thread_poll(10, 50)
```

high-frequency pattern provides minimal latency for time-critical operations (callbacks execute within 1-2ms, higher cpu usage):
```lua
while true do
    thread_poll(0, 1)
end
```

balanced pattern for efficient 60 FPS execution (callbacks batch into groups for efficiency while maintaining good responsiveness):
```lua
while true do
    thread_poll(0, 16)
end
```

efficiency pattern maximizes battery life and minimizes cpu usage (suitable for background monitoring, callbacks may execute up to 100ms after scheduled time):
```lua
while true do
    thread_poll(0, 100)
end

thread_shutdown()
```

**choosing the right timeout:**

the timeout parameter fundamentally controls the latency-efficiency trade-off in your application:

**1-5ms timeouts:** use for real-time game features requiring immediate response such as aimbots, esp rendering, or input handling. callbacks execute within milliseconds of their scheduled time. expect increased cpu usage from frequent polling, but latency will be minimal. suitable when frame-perfect timing matters more than power efficiency.

**16ms timeout:** optimal for typical game loop patterns operating at 60 frames per second. provides excellent balance between responsiveness and efficiency. callbacks batch naturally into frame-sized groups, reducing overhead while maintaining smooth operation. recommended as the default choice for most game hacking scenarios.

**50-100ms timeouts:** ideal for background monitoring, periodic checks, and non-time-critical automation. dramatically reduces cpu usage and power consumption. callbacks execute in large batches with higher latency but maintain correct average execution rates. perfect for process scanning, stat tracking, or idle monitoring.

**0ms (no wait):** special case for event-driven architectures where you need non-blocking callback processing. poll returns immediately whether callbacks are available or not. use when integrating with other event loops or when you want explicit control over blocking behavior.

understanding latency vs accuracy: the timeout controls maximum latency before callback execution, not the callback scheduling accuracy. a 1ms interval callback with a 50ms timeout still executes 1000 times per second on average - the scheduler remains accurate. the difference is execution happens in batches of approximately 50 callbacks at once, rather than individually. this batching improves performance significantly while maintaining the correct overall execution rate.

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
    thread_poll(0, 16)
end
```

### practical examples

**example 1: high-frequency monitoring (maximum responsiveness)**

use case: real-time aimbot, esp updates, input handling

this pattern prioritizes latency over efficiency. the 1ms poll timeout ensures callbacks execute within 1-2ms of becoming ready. cpu usage will be higher due to frequent wake-ups, but for competitive gaming features where split-second timing matters, this overhead is acceptable.

```lua
thread_init(4)

local esp_callback = register_callback(function()
    local proc = open_process("game.exe")
    if proc.is_valid() then
        local player_pos = proc.read_vec3.float(0x12345678)
        local enemy_pos = proc.read_vec3.float(0x23456789)
        update_overlay(player_pos, enemy_pos)
    end
end, 1)

while true do
    thread_poll(0, 1)
end
```

**example 2: balanced game loop (recommended)**

use case: general game hacking, automation, typical use cases

this is the recommended pattern for most applications. the 16ms poll timeout matches standard 60 FPS timing, providing smooth operation while efficiently batching callbacks. multiple callbacks with different intervals coexist well, each executing at their scheduled rate but batched into frame-sized groups.

```lua
thread_init(4)

local health_cb = register_callback(function()
    local proc = open_process("game.exe")
    if proc.is_valid() then
        local health = proc.read.float(0x1000)
        if health < 30 then
            trigger_health_warning()
        end
    end
end, 10)

local position_cb = register_callback(function()
    local proc = open_process("game.exe")
    if proc.is_valid() then
        local pos = proc.read_vec3.float(0x2000)
        log_position(pos)
    end
end, 50)

local stats_cb = register_callback(function()
    update_ui_stats()
end, 1000)

while true do
    thread_poll(0, 16)
end
```

**example 3: low-frequency monitoring (maximum efficiency)**

use case: process scanning, periodic checks, background monitoring

this pattern maximizes cpu efficiency and minimizes power consumption. suitable for background tasks where latency is not critical. the 100ms poll timeout means the thread sleeps efficiently between checks, waking only 10 times per second regardless of how many callbacks are registered.

```lua
thread_init(4)

local scanner = register_callback(function()
    local proc = open_process("game.exe")
    if proc.is_valid() then
        local base = proc.get_image_base()
        print("process found at base: " .. string.format("0x%x", base))
        scan_for_patterns(proc, base)
    else
        print("waiting for game process...")
    end
end, 5000)

while true do
    thread_poll(0, 100)
end
```

**example 4: event-driven with callbacks**

use case: non-blocking loops with other events

this pattern integrates callback processing with other event-driven code. the zero timeout ensures `thread_poll()` never blocks, allowing your main loop to handle other events promptly. useful when building guis, handling input, or integrating with other event loops.

```lua
thread_init(4)

local monitor = register_callback(function()
    local proc = open_process("game.exe")
    if proc.is_valid() then
        check_game_state(proc)
    end
end, 100)

while running do
    thread_poll(0, 0)
    
    process_keyboard_input()
    update_overlay_window()
    handle_network_packets()
    
    thread_sleep(1)
end
```

## windows api

access windows system features, window management, and process information.

### window_info type

struct containing comprehensive window and process information.

**fields:**
- `hwnd` (number) - window handle as 64-bit integer
- `pid` (number) - process id as 32-bit integer  
- `process_name` (string) - executable name (e.g., "notepad.exe")
- `window_title` (string) - current window title text
- `class_name` (string) - window class name

```lua
local win = find_window("Calculator")
if win then
    print("hwnd: " .. win.hwnd)
    print("pid: " .. win.pid)
    print("process: " .. win.process_name)
    print("title: " .. win.window_title)
    print("class: " .. win.class_name)
end
```

### enumerate_windows

**signature:** `enumerate_windows([visible_only])`

get list of all windows on the system.

**parameters:**
- `visible_only` (boolean, optional) - if true (default), only return visible windows

**returns:**
- array of window_info structs

```lua
local all_windows = enumerate_windows()
print("total visible windows: " .. #all_windows)

for i, win in ipairs(all_windows) do
    if win.window_title ~= "" then
        print(win.process_name .. " - " .. win.window_title)
    end
end

local all_including_hidden = enumerate_windows(false)
print("total windows (including hidden): " .. #all_including_hidden)
```

### get_window_info

**signature:** `get_window_info(hwnd)`

get detailed information about a specific window handle.

**parameters:**
- `hwnd` (number) - window handle obtained from other functions

**returns:**
- window_info struct or nil if window doesn't exist

```lua
local win = find_window("notepad")
if win then
    local info = get_window_info(win.hwnd)
    if info then
        print("refreshed info for hwnd " .. info.hwnd)
        print("current title: " .. info.window_title)
    end
end
```

### find_window

**signature:** `find_window([title], [class_name])`

find a single window by title and/or class name. both parameters are optional but at least one should be provided.

**parameters:**
- `title` (string, optional) - exact window title to match
- `class_name` (string, optional) - window class name to match

**returns:**
- window_info struct or nil if not found

```lua
local notepad = find_window("Untitled - Notepad")
if notepad then
    print("found notepad, pid: " .. notepad.pid)
end

local by_class = find_window(nil, "CalcFrame")
if by_class then
    print("found calculator by class")
end

local both = find_window("Calculator", "CalcFrame")
if both then
    print("found by both title and class")
end
```

### find_windows_by_process

**signature:** `find_windows_by_process(process_name)`

find all visible windows belonging to processes with matching names. this solves the multiple-process problem by returning window information you can use to select the correct instance.

**parameters:**
- `process_name` (string) - partial or full process name (case-insensitive)

**returns:**
- array of window_info structs for all matching visible windows

**practical use case:**

when multiple instances of a game are running, you can't use `open_process("game.exe")` directly because it would attach to the first one found. instead, use windows to identify the correct instance:

```lua
local game_windows = find_windows_by_process("game.exe")

if #game_windows == 0 then
    print("no game instances running")
elseif #game_windows == 1 then
    print("found single instance")
    local proc = open_process(game_windows[1].pid)
else
    print("multiple instances found:")
    for i, win in ipairs(game_windows) do
        print(i .. ". " .. win.window_title .. " (pid: " .. win.pid .. ")")
    end
    
    print("select which instance (1-" .. #game_windows .. "): ")
    local choice = tonumber(io.read())
    
    if choice and choice >= 1 and choice <= #game_windows then
        local selected = game_windows[choice]
        print("connecting to pid " .. selected.pid)
        local proc = open_process(selected.pid)
        
        if proc and proc.is_valid() then
            print("connected successfully!")
        end
    end
end
```

**automatic selection example:**

```lua
local function find_game_window_by_title(search_text)
    local windows = find_windows_by_process("game.exe")
    
    for _, win in ipairs(windows) do
        if win.window_title:find(search_text) then
            return win
        end
    end
    
    return nil
end

local main_menu_window = find_game_window_by_title("Main Menu")
if main_menu_window then
    local proc = open_process(main_menu_window.pid)
end
```

**getting process from window handle:**

```lua
local win = find_window("Calculator")
if win then
    local proc = open_process(win.pid)
    
    if proc and proc.is_valid() then
        print("attached to process: " .. win.process_name)
        print("pid: " .. win.pid)
    end
end

local hwnd = 0x12345678
local info = get_window_info(hwnd)
if info then
    local proc = open_process(info.pid)
end
```

### get_system_uptime

**signature:** `get_system_uptime()`

get system uptime in milliseconds since boot.

**parameters:** none

**returns:**
- number (uint64) - milliseconds since system started

```lua
local uptime_ms = get_system_uptime()
local uptime_seconds = uptime_ms / 1000
local uptime_minutes = uptime_seconds / 60
local uptime_hours = uptime_minutes / 60
local uptime_days = uptime_hours / 24

print(string.format("system uptime: %d days, %02d:%02d:%02d",
    math.floor(uptime_days),
    math.floor(uptime_hours % 24),
    math.floor(uptime_minutes % 60),
    math.floor(uptime_seconds % 60)))
```

### post_window_message

**signature:** `post_window_message(hwnd, msg, wparam, lparam)`

post a windows message to a window. useful for sending input or control messages.

**parameters:**
- `hwnd` (number) - target window handle
- `msg` (number) - windows message id (e.g., 0x0010 for WM_CLOSE)
- `wparam` (number) - message-specific parameter
- `lparam` (number) - message-specific parameter

**returns:**
- boolean - true if message was posted successfully

**common message ids:**

```lua
local WM_CLOSE = 0x0010
local WM_KEYDOWN = 0x0100
local WM_KEYUP = 0x0101
local WM_CHAR = 0x0102
local WM_LBUTTONDOWN = 0x0201
local WM_LBUTTONUP = 0x0202
local WM_RBUTTONDOWN = 0x0204
local WM_RBUTTONUP = 0x0205

local win = find_window("notepad")
if win then
    local success = post_window_message(win.hwnd, WM_CLOSE, 0, 0)
    if success then
        print("sent close message to notepad")
    end
end
```

**sending keypresses:**

```lua
local function send_char_to_window(hwnd, char_code)
    post_window_message(hwnd, 0x0100, char_code, 0)
    thread_sleep(10)
    post_window_message(hwnd, 0x0101, char_code, 0)
end

local win = find_window("notepad")
if win then
    local VK_RETURN = 0x0D
    send_char_to_window(win.hwnd, VK_RETURN)
end
```

### play_sound

**signature:** `play_sound(file_path)`

play a sound file asynchronously. supports wav and mp3 formats.

**parameters:**
- `file_path` (string) - absolute or relative path to sound file

**returns:**
- boolean - true if sound started playing successfully

```lua
local success = play_sound("C:\\Windows\\Media\\notify.wav")
if success then
    print("playing sound")
end

play_sound("sounds/achievement.wav")
play_sound("sounds/error.mp3")
```

**sound manager example:**

```lua
local sounds = {
    click = "sounds/click.wav",
    success = "sounds/success.wav",
    error = "sounds/error.wav",
    notification = "sounds/notify.wav"
}

local function play_ui_sound(sound_name)
    local path = sounds[sound_name]
    if path then
        play_sound(path)
    else
        print("unknown sound: " .. sound_name)
    end
end

play_ui_sound("click")
play_ui_sound("success")
```

### window state functions

check the visibility and state of windows.

**is_window_visible**

**signature:** `is_window_visible(hwnd)`

check if a window is currently visible.

**parameters:**
- `hwnd` (number) - window handle

**returns:**
- boolean - true if window is visible

```lua
local win = find_window("Calculator")
if win and is_window_visible(win.hwnd) then
    print("calculator is visible")
end
```

**is_window_minimized**

**signature:** `is_window_minimized(hwnd)`

check if a window is minimized (iconic).

**parameters:**
- `hwnd` (number) - window handle

**returns:**
- boolean - true if window is minimized

```lua
local win = find_window("notepad")
if win and is_window_minimized(win.hwnd) then
    print("notepad is minimized")
end
```

**is_window_maximized**

**signature:** `is_window_maximized(hwnd)`

check if a window is maximized.

**parameters:**
- `hwnd` (number) - window handle

**returns:**
- boolean - true if window is maximized

```lua
local win = find_window("chrome")
if win and is_window_maximized(win.hwnd) then
    print("chrome is maximized")
end
```

### window manipulation functions

control window position, size, and visibility state.

**set_window_foreground**

**signature:** `set_window_foreground(hwnd)`

bring a window to the foreground and activate it.

**parameters:**
- `hwnd` (number) - window handle

**returns:**
- boolean - true if successful

```lua
local win = find_window("Calculator")
if win then
    set_window_foreground(win.hwnd)
end
```

**show_window**

**signature:** `show_window(hwnd, cmd)`

show, hide, minimize, maximize, or restore a window.

**parameters:**
- `hwnd` (number) - window handle
- `cmd` (number) - show window command

**returns:**
- boolean - true if successful

**common show window commands:**
- `0` (SW_HIDE) - hide the window
- `1` (SW_SHOWNORMAL) - show and activate normally
- `2` (SW_SHOWMINIMIZED) - show minimized
- `3` (SW_SHOWMAXIMIZED) - show maximized
- `4` (SW_SHOWNOACTIVATE) - show without activating
- `5` (SW_SHOW) - show at current state
- `6` (SW_MINIMIZE) - minimize the window
- `7` (SW_SHOWMINNOACTIVE) - show minimized without activating
- `8` (SW_SHOWNA) - show at current state without activating
- `9` (SW_RESTORE) - restore from minimized/maximized

```lua
local SW_HIDE = 0
local SW_SHOW = 1
local SW_MINIMIZE = 6
local SW_MAXIMIZE = 3
local SW_RESTORE = 9

local win = find_window("notepad")
if win then
    show_window(win.hwnd, SW_MINIMIZE)
    thread_sleep(1000)
    show_window(win.hwnd, SW_RESTORE)
end
```

**set_window_position**

**signature:** `set_window_position(hwnd, x, y, width, height)`

move and resize a window.

**parameters:**
- `hwnd` (number) - window handle
- `x` (number) - left position in pixels
- `y` (number) - top position in pixels
- `width` (number) - window width in pixels
- `height` (number) - window height in pixels

**returns:**
- boolean - true if successful

```lua
local win = find_window("Calculator")
if win then
    set_window_position(win.hwnd, 100, 100, 800, 600)
end
```

**get_window_rect**

**signature:** `get_window_rect(hwnd)`

get the position and size of a window.

**parameters:**
- `hwnd` (number) - window handle

**returns:**
- table with fields: `x`, `y`, `width`, `height`, or nil if window doesn't exist

```lua
local win = find_window("notepad")
if win then
    local rect = get_window_rect(win.hwnd)
    if rect then
        print("position: " .. rect.x .. ", " .. rect.y)
        print("size: " .. rect.width .. " x " .. rect.height)
    end
end
```

**get_foreground_window**

**signature:** `get_foreground_window()`

get information about the currently active foreground window.

**parameters:** none

**returns:**
- window_info struct for the foreground window, or nil

```lua
local active = get_foreground_window()
if active then
    print("active window: " .. active.window_title)
    print("process: " .. active.process_name)
    print("pid: " .. active.pid)
end
```

**flash_window**

**signature:** `flash_window(hwnd, [count])`

flash a window's taskbar button to get user attention.

**parameters:**
- `hwnd` (number) - window handle
- `count` (number, optional) - number of times to flash (default: 5)

**returns:**
- boolean - true if successful

```lua
local win = find_window("Discord")
if win then
    flash_window(win.hwnd, 10)
end
```

**set_window_transparency**

**signature:** `set_window_transparency(hwnd, alpha)`

set window transparency level.

**parameters:**
- `hwnd` (number) - window handle
- `alpha` (number) - transparency level (0-255, where 0 is fully transparent, 255 is opaque)

**returns:**
- boolean - true if successful

```lua
local win = find_window("notepad")
if win then
    set_window_transparency(win.hwnd, 200)
    
    thread_sleep(2000)
    
    set_window_transparency(win.hwnd, 255)
end
```

**close_window**

**signature:** `close_window(hwnd)`

send a close message to a window (equivalent to clicking the X button).

**parameters:**
- `hwnd` (number) - window handle

**returns:**
- boolean - true if message was sent successfully

```lua
local win = find_window("Untitled - Notepad")
if win then
    close_window(win.hwnd)
end
```

### window manipulation examples

**monitor active window:**

```lua
thread_init(2)

local last_active = nil

local monitor = register_callback(function()
    local active = get_foreground_window()
    
    if active and (not last_active or last_active.hwnd ~= active.hwnd) then
        print("switched to: " .. active.window_title .. " (" .. active.process_name .. ")")
        last_active = active
    end
end, 100)

for i = 1, 100 do
    thread_poll(0, 100)
end

unregister_callback(monitor)
thread_shutdown()
```

**auto-arrange windows:**

```lua
local function arrange_windows_grid()
    local windows = find_windows_by_process("chrome")
    
    if #windows == 0 then
        print("no chrome windows found")
        return
    end
    
    local screen_width = 1920
    local screen_height = 1080
    local cols = math.ceil(math.sqrt(#windows))
    local rows = math.ceil(#windows / cols)
    local win_width = math.floor(screen_width / cols)
    local win_height = math.floor(screen_height / rows)
    
    for i, win in ipairs(windows) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local x = col * win_width
        local y = row * win_height
        
        show_window(win.hwnd, 1)
        set_window_position(win.hwnd, x, y, win_width, win_height)
    end
    
    print("arranged " .. #windows .. " windows in " .. rows .. "x" .. cols .. " grid")
end

arrange_windows_grid()
```

**window state manager:**

```lua
local WindowManager = {}

function WindowManager:save_state(hwnd)
    local rect = get_window_rect(hwnd)
    if not rect then
        return nil
    end
    
    return {
        hwnd = hwnd,
        x = rect.x,
        y = rect.y,
        width = rect.width,
        height = rect.height,
        visible = is_window_visible(hwnd),
        minimized = is_window_minimized(hwnd),
        maximized = is_window_maximized(hwnd)
    }
end

function WindowManager:restore_state(state)
    if not state then
        return false
    end
    
    if state.maximized then
        show_window(state.hwnd, 3)
    elseif state.minimized then
        show_window(state.hwnd, 6)
    else
        show_window(state.hwnd, 1)
        set_window_position(state.hwnd, state.x, state.y, state.width, state.height)
    end
    
    if not state.visible then
        show_window(state.hwnd, 0)
    end
    
    return true
end

local win = find_window("notepad")
if win then
    local saved = WindowManager:save_state(win.hwnd)
    
    set_window_position(win.hwnd, 0, 0, 640, 480)
    thread_sleep(2000)
    
    WindowManager:restore_state(saved)
end
```

**focus game window automatically:**

```lua
local function ensure_game_focused(process_name, interval_ms)
    interval_ms = interval_ms or 1000
    
    return register_callback(function()
        local active = get_foreground_window()
        
        if not active or not active.process_name:find(process_name) then
            local windows = find_windows_by_process(process_name)
            
            if #windows > 0 then
                local game_win = windows[1]
                
                if is_window_minimized(game_win.hwnd) then
                    show_window(game_win.hwnd, 9)
                end
                
                set_window_foreground(game_win.hwnd)
                print("refocused game window")
            end
        end
    end, interval_ms)
end

thread_init(2)
local focus_cb = ensure_game_focused("game.exe", 5000)

for i = 1, 60 do
    thread_poll(0, 1000)
end

unregister_callback(focus_cb)
thread_shutdown()
```

### complete example: multi-instance game selector

this example shows how to handle multiple game instances and let the user select which one to attach to:

```lua
local process_name = "game.exe"

local function format_uptime()
    local ms = get_system_uptime()
    local seconds = math.floor(ms / 1000)
    local minutes = math.floor(seconds / 60)
    local hours = math.floor(minutes / 60)
    return string.format("%02d:%02d:%02d", hours % 24, minutes % 60, seconds % 60)
end

local function select_game_instance()
    print("scanning for game instances...")
    local windows = find_windows_by_process(process_name)
    
    if #windows == 0 then
        print("no game instances found")
        return nil
    end
    
    if #windows == 1 then
        print("found single instance: " .. windows[1].window_title)
        return windows[1]
    end
    
    print("\nfound " .. #windows .. " game instances:")
    for i, win in ipairs(windows) do
        print(string.format("%d. %s (pid: %d, hwnd: 0x%X)", 
            i, win.window_title, win.pid, win.hwnd))
    end
    
    print("\nselect instance (1-" .. #windows .. "): ")
    local choice = tonumber(io.read())
    
    if choice and choice >= 1 and choice <= #windows then
        return windows[choice]
    end
    
    print("invalid selection")
    return nil
end

local function main()
    print("system uptime: " .. format_uptime())
    print("searching for game...")
    
    local selected = select_game_instance()
    if not selected then
        return
    end
    
    print("\nconnecting to pid " .. selected.pid .. "...")
    local proc = open_process(selected.pid)
    
    if not proc or not proc.is_valid() then
        print("failed to open process")
        play_sound("sounds/error.wav")
        return
    end
    
    print("connected successfully!")
    play_sound("sounds/success.wav")
    
    local callback_id = register_callback(function()
        local info = get_window_info(selected.hwnd)
        if not info then
            print("window closed, stopping...")
            return false
        end
        
        print("monitoring: " .. info.window_title)
        
        return true
    end, 1000)
    
    print("press ctrl+c to stop...")
    
    thread_init(2)
    for i = 1, 60 do
        thread_poll(0, 1000)
    end
    
    unregister_callback(callback_id)
    thread_shutdown()
    
    print("shutdown complete")
end

local ok, err = pcall(main)
if not ok then
    print("error: " .. tostring(err))
    play_sound("sounds/error.wav")
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

#### manual chain following

```lua
local process = open_process("game.exe")
local base = process.get_image_base()

local ptr1 = process.read.uint64(base + 0x1000)
local ptr2 = process.read.uint64(ptr1 + 0x10)
local final_value = process.read.float(ptr2 + 0x20)
```

#### automatic chain resolution

use `read_chain` to follow pointer chains automatically. returns the final address, or nil if any pointer in the chain is invalid.

```lua
local process = open_process("game.exe")
local base = process.get_image_base()

-- follow a chain: base+0x1000 -> [ptr]+0x10 -> [ptr]+0x20
local final_address = process.read_chain(base + 0x1000, {0x10, 0x20})

if final_address then
    local health = process.read.float(final_address)
    local mana = process.read.float(final_address + 0x4)
    print("health: " .. health .. ", mana: " .. mana)
else
    print("pointer chain is invalid")
end
```

#### caching resolved addresses

cache pointer chains for better performance:

```lua
local process = open_process("game.exe")
local base = process.get_image_base()

-- resolve once
local player_address = process.read_chain(base + 0x2000, {0x8, 0x10, 0x0})

if player_address then
    -- read multiple values from cached address
    while true do
        local health = process.read.float(player_address + 0x0)
        local position = process.read_vec3.float(player_address + 0x10)
        
        print("health: " .. health)
        sleep(100)
    end
end
```

#### deep pointer chains

handle complex multi-level pointer chains:

```lua
local process = open_process("game.exe")
local base = process.get_image_base()

-- 5-level deep chain
local entity_list = process.read_chain(base + 0x5000, {0x18, 0x28, 0x0, 0x10, 0x8})

if entity_list then
    -- read entity count at resolved address
    local entity_count = process.read.int32(entity_list)
    print("found " .. entity_count .. " entities")
end
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

## math

### matrices

matrix types for linear algebra operations commonly used in game development.

#### creating matrices

```lua
local m2 = mat2x2.row_major()
local m3 = mat3x3.row_major()
local m4 = mat4x4.row_major()

local m2_col = mat2x2.col_major()
local m3_col = mat3x3.col_major()
local m4_col = mat4x4.col_major()
```

#### accessing matrix elements

```lua
local m = mat4x4.row_major()

m.set(0, 0, 1.0)
m.set(0, 1, 2.0)
m.set(1, 0, 3.0)
m.set(1, 1, 4.0)

local value = m.get(0, 0)
print("element at [0,0]: " .. value)
```

#### matrix operations

```lua
local m1 = mat3x3.row_major()
local m2 = mat3x3.row_major()

m1.identity()
m2.identity()
m2.set(0, 0, 2.0)

local m3 = m1 + m2
local m4 = m1 - m2
local m5 = m1 * m2
local m6 = m1 * 2.0

local transposed = m1.transpose()
local inverted = m1.inverse()
local det = m1.determinant()
```

#### matrix properties

```lua
local m = mat4x4.row_major()

print("rows: " .. m.rows)
print("columns: " .. m.columns)

m.clear()
m.identity()
```

#### storage ordering

row major stores elements row-by-row in memory, column major stores column-by-column. the choice affects how matrices interact with graphics apis:

```lua
local row_major = mat4x4.row_major()
row_major.identity()

local col_major = mat4x4.col_major()
col_major.identity()
```

both orderings provide the same operations and interface, only the internal memory layout differs.

#### practical example

```lua
local view_matrix = mat4x4.row_major()
view_matrix.identity()

view_matrix.set(0, 3, 10.0)
view_matrix.set(1, 3, 5.0)
view_matrix.set(2, 3, 20.0)

local projection_matrix = mat4x4.row_major()
projection_matrix.identity()

local view_projection = projection_matrix * view_matrix

for row = 0, 3 do
    for col = 0, 3 do
        local val = view_projection.get(row, col)
        print(string.format("[%d,%d] = %.2f", row, col, val))
    end
end
```

### trigonometry

angle conversion and field of view utilities.

#### angle conversions

```lua
local rad = degrees_to_radians(90.0)
print("90 degrees = " .. rad .. " radians")

local deg = radians_to_degrees(1.5708)
print("1.5708 radians = " .. deg .. " degrees")
```

#### field of view conversions

```lua
local aspect_ratio = 16.0 / 9.0

local h_fov = 90.0
local v_fov = horizontal_fov_to_vertical(h_fov, aspect_ratio)
print("horizontal fov " .. h_fov .. " = vertical fov " .. v_fov)

local v_fov = 60.0
local h_fov = vertical_fov_to_horizontal(v_fov, aspect_ratio)
print("vertical fov " .. v_fov .. " = horizontal fov " .. h_fov)
```

#### angle wrapping

```lua
local angle = 450.0
local wrapped = wrap_angle(angle, 0.0, 360.0)
print("450 degrees wrapped to [0, 360] = " .. wrapped)

local yaw = -185.0
local normalized = wrap_angle(yaw, -180.0, 180.0)
print("-185 degrees normalized to [-180, 180] = " .. normalized)
```

#### practical example

```lua
local player_yaw = 370.0
local target_yaw = -10.0

player_yaw = wrap_angle(player_yaw, -180.0, 180.0)
target_yaw = wrap_angle(target_yaw, -180.0, 180.0)

local delta = target_yaw - player_yaw

if delta > 180.0 then
    delta = delta - 360.0
elseif delta < -180.0 then
    delta = delta + 360.0
end

print("shortest rotation: " .. delta .. " degrees")
```

### projection

viewport management and field of view control.

#### viewport

screen dimensions and aspect ratio.

```lua
local vp = viewport()
vp.width = 1920
vp.height = 1080

local aspect = vp.aspect_ratio
print("aspect ratio: " .. aspect)
```

#### field of view

fov angles with clamping to valid range (0-180 degrees).

```lua
local camera_fov = fov(90.0)
print("fov: " .. camera_fov.degrees .. " degrees")
print("fov: " .. camera_fov.radians .. " radians")

camera_fov.set_degrees(110.0)

camera_fov.set_radians(1.5708)

local current_degrees = camera_fov.degrees
local current_radians = camera_fov.radians
```

#### error codes

projection operations can fail with specific error codes.

```lua
local errors = {
    world_position_out_of_bounds = projection_error.world_position_out_of_bounds,
    inv_view_proj_det_zero = projection_error.inv_view_proj_det_zero
}
```

### camera

engine-specific camera implementations with world-to-screen projection.

#### supported engines

```lua
local source_cam = source_camera(position, angles, viewport, fov, near_plane, far_plane)
local opengl_cam = opengl_camera(position, angles, viewport, fov, near_plane, far_plane)
local unreal_cam = unreal_camera(position, angles, viewport, fov, near_plane, far_plane)
local unity_cam = unity_camera(position, angles, viewport, fov, near_plane, far_plane)
local iw_cam = iw_camera(position, angles, viewport, fov, near_plane, far_plane)
```

#### view angles

each engine has its own view angles type with pitch, yaw, and roll.

```lua
local source_angles = source_view_angles(0.0, 90.0, 0.0)
print("pitch: " .. source_angles.pitch)
print("yaw: " .. source_angles.yaw)
print("roll: " .. source_angles.roll)

local opengl_angles = opengl_view_angles()
opengl_angles.pitch = 45.0
opengl_angles.yaw = 180.0
opengl_angles.roll = 0.0
```

#### creating a camera

```lua
local position = vec3(100.0, 200.0, 300.0)
local angles = source_view_angles(0.0, 90.0, 0.0)
local vp = viewport()
vp.width = 1920
vp.height = 1080
local camera_fov = fov(90.0)
local near = 0.1
local far = 10000.0

local cam = source_camera(position, angles, vp, camera_fov, near, far)
```

#### world to screen

convert 3D world coordinates to 2D screen coordinates.

```lua
local cam = source_camera(position, angles, vp, camera_fov, near, far)

local world_pos = vec3(500.0, 600.0, 700.0)
local result = cam.world_to_screen(world_pos)

if result.has_value() then
    local screen_pos = result.value()
    print("screen x: " .. screen_pos.x)
    print("screen y: " .. screen_pos.y)
else
    print("position is off-screen or behind camera")
end
```

#### screen to world

convert 2D screen coordinates back to 3D world space.

```lua
local screen_pos = vec2(960.0, 540.0)
local result = cam.screen_to_world(screen_pos)

if result.has_value() then
    local world_pos = result.value()
    print("world position: " .. world_pos.x .. ", " .. world_pos.y .. ", " .. world_pos.z)
end
```

#### camera properties

```lua
cam.set_field_of_view(fov(110.0))
cam.set_near_plane(0.5)
cam.set_far_plane(5000.0)
cam.set_origin(vec3(0.0, 0.0, 100.0))

local new_angles = source_view_angles(10.0, 45.0, 0.0)
cam.set_view_angles(new_angles)

local vp = viewport()
vp.width = 2560
vp.height = 1440
cam.set_view_port(vp)

local current_fov = cam.get_field_of_view()
local current_near = cam.get_near_plane()
local current_far = cam.get_far_plane()
local current_origin = cam.get_origin()
local current_angles = cam.get_view_angles()
```

#### look at target

point the camera at a specific world position.

```lua
local cam = source_camera(position, angles, vp, camera_fov, near, far)

local target_position = vec3(1000.0, 2000.0, 500.0)
cam.look_at(target_position)
```

#### view projection matrix

```lua
local view_proj = cam.get_view_projection_matrix()

for row = 0, 3 do
    for col = 0, 3 do
        local val = view_proj.get(row, col)
        print(string.format("[%d,%d] = %.2f", row, col, val))
    end
end
```

#### practical esp example

```lua
local process = open_process("game.exe")

local cam_pos = process.read_vec3.float(camera_address)
local cam_angles = source_view_angles(
    process.read.float(camera_address + 0x10),
    process.read.float(camera_address + 0x14),
    0.0
)

local vp = viewport()
vp.width = 1920
vp.height = 1080

local cam = source_camera(cam_pos, cam_angles, vp, fov(90.0), 0.1, 10000.0)

local entity_pos = process.read_vec3.float(entity_address)
local result = cam.world_to_screen(entity_pos)

if result.has_value() then
    local screen = result.value()
    print("draw box at: " .. screen.x .. ", " .. screen.y)
end
```

## best practices

### callback design patterns

capture and modify upvalues safely:
```lua
local counter = 0
local last_check = os.time()

register_callback(function()
    counter = counter + 1
    
    if os.time() - last_check >= 1 then
        print("ticks per second: " .. counter)
        counter = 0
        last_check = os.time()
    end
end, 1)
```

understand callback execution timing:

callbacks do not execute automatically in the background. registering a callback schedules it for execution, but the actual execution only occurs when your code explicitly calls `thread_poll()`. the scheduler thread handles timing and queueing, but callback code runs synchronously during `thread_poll()` calls.

incorrect example (callback never executes because thread_poll is not called):
```lua
thread_init()
register_callback(function()
    print("this runs every 10ms")
end, 10)

while true do
end
```

correct example (callback executes during thread_poll):
```lua
thread_init()
register_callback(function()
    print("this runs every 10ms")
end, 10)

while true do
    thread_poll(0, 16)
end
```

match poll timeout to your needs:

different polling strategies suit different use cases. understanding the trade-offs helps optimize your application's performance characteristics.

high-frequency monitoring (1ms callback with 1ms poll timeout) executes almost immediately after becoming ready with 1-2ms latency. cpu usage is higher due to constant wake-ups, but latency is minimal. use for aimbots, esp systems, real-time input handling, and frame-perfect timing:
```lua
thread_init()
local monitor = register_callback(function() end, 1)
while true do
    thread_poll(0, 1)
end
```

balanced approach (1ms callback with 16ms poll timeout) accumulates callbacks for up to 16ms, then executes as a batch of approximately 16 invocations. significantly more efficient than 1ms polling while maintaining good responsiveness. the callback still executes 1000 times per second, just in groups of 16. use for general game hacking, automation, and typical monitoring scenarios:
```lua
thread_init()
local monitor = register_callback(function() end, 1)
while true do
    thread_poll(0, 16)
end
```

low-frequency monitoring (100ms callback with 100ms poll timeout) executes once per poll since intervals match. minimal cpu overhead with maximum power efficiency. suitable for non-time-critical tasks where 100ms latency is acceptable. use for process scanning, periodic stat updates, and background monitoring:
```lua
thread_init()
local monitor = register_callback(function() end, 100)
while true do
    thread_poll(0, 100)
end
```

check validity before operations:
```lua
register_callback(function()
    local proc = open_process("game.exe")
    if proc.is_valid() then
        local value = proc.read.uint64(0x140001000)
    end
end, 100)
```

avoid calling get_active_callback_count from within callbacks as it can cause deadlocks.

### performance optimization

use appropriate intervals:
- high-frequency monitoring: 1-10ms
- normal updates: 50-100ms  
- periodic checks: 500-1000ms

batch memory reads with buffers:
```lua
local buf = proc.read_buffer(base, 12)
if buf.is_valid() then
    local health = buf.get.float(0)
    local armor = buf.get.float(4)
    local ammo = buf.get.int32(8)
end
```

### error handling

use pcall for error recovery:
```lua
local callback_id = register_callback(function()
    local ok, err = pcall(function()
        local proc = open_process("game.exe")
        local value = proc.read.uint64(0x140001000)
        process_value(value)
    end)
    
    if not ok then
        print("callback error: " .. tostring(err))
    end
end, 100)
```

### cleanup and shutdown

always cleanup resources:
```lua
thread_init(4)
local callbacks = {}

table.insert(callbacks, register_callback(function() end, 100))
table.insert(callbacks, register_callback(function() end, 200))

for i = 1, 1000 do
    thread_poll(0, 10)
end

for _, id in ipairs(callbacks) do
    unregister_callback(id)
end
thread_shutdown()
```