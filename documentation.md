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

https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes
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