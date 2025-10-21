# API reference

complete reference for the Lua scripting API.

## type system

### numeric types

throughout this API, `TYPE` refers to one of the following numeric types:

| type | description | size | range |
|------|-------------|------|-------|
| `int8` | signed 8-bit integer | 1 byte | -128 to 127 |
| `int16` | signed 16-bit integer | 2 bytes | -32,768 to 32,767 |
| `int32` | signed 32-bit integer | 4 bytes | -2,147,483,648 to 2,147,483,647 |
| `int64` | signed 64-bit integer | 8 bytes | -9,223,372,036,854,775,808 to 9,223,372,036,854,775,807 |
| `uint8` | unsigned 8-bit integer | 1 byte | 0 to 255 |
| `uint16` | unsigned 16-bit integer | 2 bytes | 0 to 65,535 |
| `uint32` | unsigned 32-bit integer | 4 bytes | 0 to 4,294,967,295 |
| `uint64` | unsigned 64-bit integer | 8 bytes | 0 to 18,446,744,073,709,551,615 |
| `float` | 32-bit floating point | 4 bytes | ±3.4e±38 (7 digits) |
| `double` | 64-bit floating point | 8 bytes | ±1.7e±308 (15 digits) |

**example usage:**
```lua
-- read operations
local health = process.read.float(address)
local ammo = process.read.int32(address + 0x10)
local flags = process.read.uint8(address + 0x20)

-- write operations
process.write.float(address, 100.0)
process.write.int32(address + 0x10, 999)
process.write.uint8(address + 0x20, 0xFF)

-- vector operations
local position = process.read_vec3.float(address)
process.write_vec3.float(address, vec3(10, 20, 30))

-- buffer operations
local value = buffer.get.int32(offset)
buffer.set.uint64(offset, value)
```

### vector types

| type | description | fields | size |
|------|-------------|--------|------|
| `vec2` | 2D vector | `x`, `y` | 8 bytes (2 floats) |
| `vec3` | 3D vector | `x`, `y`, `z` | 12 bytes (3 floats) |
| `vec4` | 4D vector | `x`, `y`, `z`, `w` | 16 bytes (4 floats) |

vectors are always stored as floats internally but can be read/written with any numeric type through automatic conversion.

### handle types

| type | description |
|------|-------------|
| `process_handle` | handle to a process for memory operations |
| `mouse_handle` | handle to mouse input device |
| `keyboard_handle` | handle to keyboard input device |
| `window_info` | window information structure |
| `membuffer` | memory buffer for efficient operations |
| `mat2x2` | 2×2 matrix |
| `mat3x3` | 3×3 matrix |
| `mat4x4` | 4×4 matrix |
| `viewport` | screen viewport dimensions |
| `fov` | field of view angle |
| camera types | `source_camera`, `opengl_camera`, `unreal_camera`, `unity_camera`, `iw_camera` |
| view angles | `source_view_angles`, `opengl_view_angles`, `unreal_view_angles`, `unity_view_angles`, `iw_view_angles` |

### memory layout

understanding memory layout is important for pointer arithmetic and struct reading:

```lua
-- example struct layout in memory:
-- struct Player {
--     float health;        // offset 0x00, 4 bytes
--     float armor;         // offset 0x04, 4 bytes
--     int32 ammo;          // offset 0x08, 4 bytes
--     vec3 position;       // offset 0x10, 12 bytes (3 floats)
--     char name[32];       // offset 0x20, 32 bytes
-- };

local player_addr = 0x140001000

local health = process.read.float(player_addr + 0x00)
local armor = process.read.float(player_addr + 0x04)
local ammo = process.read.int32(player_addr + 0x08)
local position = process.read_vec3.float(player_addr + 0x10)

-- or use a buffer for efficiency
local buf = process.read_buffer(player_addr, 0x40)
if buf.is_valid() then
    local health = buf.get.float(0x00)
    local armor = buf.get.float(0x04)
    local ammo = buf.get.int32(0x08)
    local position = buf.get_vec3(0x10)
    local name = buf.get_string(0x20, 32)
end
```

### pointer chains

pointer chains are a common pattern in game memory where you follow multiple levels of pointers to reach your target data:

```lua
-- typical game structure:
-- GameBase -> EntityList -> Player -> Health
-- 0x140001000 -> [+0x10] -> [+0x20] -> [+0x0] = health value

-- manual approach (don't do this):
local base = 0x140001000
local list_ptr = process.read.uint64(base + 0x10)
if list_ptr == 0 then return end
local player_ptr = process.read.uint64(list_ptr + 0x20)
if player_ptr == 0 then return end
local health = process.read.float(player_ptr + 0x0)

-- correct approach using read_chain:
local health_addr = process.read_chain(0x140001000, {0x10, 0x20, 0x0})
if health_addr then
    local health = process.read.float(health_addr)
end
```

`read_chain` automatically validates each pointer in the chain and returns `nil` if any pointer is invalid, making your code safer and cleaner.

### coordinate systems

different game engines use different coordinate systems and rotation conventions:

- **source engine**: left-handed Z-up, pitch/yaw/roll euler angles
- **opengl**: right-handed Y-up, standard perspective projection
- **unreal engine**: left-handed Z-up, rotators with pitch/yaw/roll
- **unity**: left-handed Y-up, quaternion-based rotations
- **IW engine** (call of duty): similar to source but with engine-specific quirks

when using cameras, always match the camera type to your target engine. using the wrong camera type will result in incorrect screen projections.

### threading model

the API uses a thread pool for executing callbacks asynchronously:

```lua
-- initialization creates worker threads
thread_init(4)  -- 4 worker threads

-- callbacks run on worker threads at specified intervals
local callback_id = register_callback(function()
    -- this runs on a worker thread
    -- be careful with shared state
    print("executing on worker thread")
end, 100)  -- every 100ms

-- main thread must poll to process results
while running do
    thread_poll(0, 16)  -- check for callbacks, timeout after 16ms
    -- your main loop logic here
end
```

**important**: callbacks execute on worker threads, not the main thread. if you need to access shared data, use proper synchronization or process results in the main thread after `thread_poll`.

### buffers vs direct reads

buffers are more efficient when reading multiple values from the same memory region:

```lua
-- inefficient: multiple process reads
local health = process.read.float(addr + 0x00)
local armor = process.read.float(addr + 0x04)
local ammo = process.read.int32(addr + 0x08)
-- 3 separate process memory reads

-- efficient: single read into buffer
local buf = process.read_buffer(addr, 0x20)
if buf.is_valid() then
    local health = buf.get.float(0x00)
    local armor = buf.get.float(0x04)
    local ammo = buf.get.int32(0x08)
end
-- 1 process memory read, 3 buffer reads (much faster)
```

use buffers when reading structs or multiple nearby values. use direct reads for single values or values far apart in memory.

---

## process management

### open_process

opens a handle to a process for memory operations.

**signatures:**
```lua
process = open_process(pid)
process = open_process("process_name.exe")
```

**parameters:**
- `pid` (number) - process ID
- `process_name` (string) - process executable name

**returns:** `process_handle` object

**example:**
```lua
local game = open_process("game.exe")
if game.is_valid() then
    local base = game.get_image_base()
end
```

### process handle methods

#### is_valid
```lua
bool = process.is_valid()
```
check if process handle is valid.

#### get_image_base
```lua
address = process.get_image_base()
```
get base address of main executable module.

#### get_module
```lua
module = process.get_module("module.dll")
```
get information about a loaded module.

**returns:** table with `base` and `size` fields.

#### read
```lua
value = process.read.TYPE(address)
```

read typed values from process memory.

**types:** `float`, `double`, `int8`, `int16`, `int32`, `int64`, `uint8`, `uint16`, `uint32`, `uint64`

#### read_vec2, read_vec3, read_vec4
```lua
vec = process.read_vec2.TYPE(address)
vec = process.read_vec3.TYPE(address)
vec = process.read_vec4.TYPE(address)
```

read vector types from memory.

**types:** same as `read`

#### write
```lua
success = process.write.TYPE(address, value)
```

write typed values to process memory.

**types:** same as `read`

#### write_vec2, write_vec3, write_vec4
```lua
success = process.write_vec2.TYPE(address, vec)
success = process.write_vec3.TYPE(address, vec)
success = process.write_vec4.TYPE(address, vec)
```

write vector types to memory.

#### read_buffer
```lua
buffer = process.read_buffer(address, size)
```

read memory region into a buffer.

#### read_chain
```lua
address = process.read_chain(base_address, {offset1, offset2, ...})
```

follow a pointer chain and return final address. returns `nil` if chain is invalid.

**example:**
```lua
local player = process.read_chain(base + 0x1000, {0x10, 0x20, 0x0})
if player then
    local health = process.read.float(player)
end
```

---

## input simulation

### open_mouse

opens a handle to the mouse input device.

```lua
mouse = open_mouse()
```

**returns:** `mouse_handle` object

### mouse handle methods

#### move
```lua
mouse.move(x, y)
```

move mouse by relative offset.

#### click
```lua
mouse.click(button)
```

click a mouse button.

**buttons:** `1` (left), `2` (right), `3` (middle), `4` (X1), `5` (X2)

#### scroll_vertical
```lua
mouse.scroll_vertical(delta)
```

scroll vertically. positive = up, negative = down.

#### scroll_horizontal
```lua
mouse.scroll_horizontal(delta)
```

scroll horizontally. positive = right, negative = left.

### open_keyboard

opens a handle to the keyboard input device.

```lua
keyboard = open_keyboard()
```

**returns:** `keyboard_handle` object

### keyboard handle methods

#### key_down
```lua
keyboard.key_down(vk_code)
```

press a key down.

#### key_up
```lua
keyboard.key_up(vk_code)
```

release a key.

#### key_press
```lua
keyboard.key_press(vk_code, hold_ms)
```

press and release a key with optional hold duration (default: 50ms).

#### type_string
```lua
keyboard.type_string("text", delay_ms)
```

type a string with delay between characters (default: 50ms).

### is_key_down
```lua
down = is_key_down(vk_code)
```

check if a key is currently held down.

### is_key_toggled
```lua
toggled = is_key_toggled(vk_code)
```

check toggle state (caps lock, num lock, etc.).

---

## threading

### thread_init

initialize the thread pool.

```lua
thread_init(num_threads)
```

**parameters:**
- `num_threads` (number) - number of worker threads (default: hardware concurrency)

### thread_shutdown

shutdown the thread pool.

```lua
thread_shutdown()
```

### register_callback

register a function to execute at intervals.

```lua
callback_id = register_callback(function, interval_ms)
```

**parameters:**
- `function` - function to execute
- `interval_ms` (number) - interval in milliseconds

**returns:** callback ID for later removal

**example:**
```lua
thread_init()

local callback_id = register_callback(function()
    print("tick")
end, 1000)

while true do
    thread_poll(0, 16)
end
```

### unregister_callback

remove a registered callback.

```lua
unregister_callback(callback_id)
```

### thread_poll

process queued callbacks.

```lua
processed = thread_poll(min_callbacks, timeout_ms)
```

**parameters:**
- `min_callbacks` (number) - minimum callbacks to process (0 = all available)
- `timeout_ms` (number) - maximum time to wait for callbacks

**returns:** number of callbacks processed

### thread_sleep

sleep for specified milliseconds.

```lua
thread_sleep(milliseconds)
```

---

## window management

### enumerate_windows

get list of all windows.

```lua
windows = enumerate_windows(visible_only)
```

**parameters:**
- `visible_only` (bool) - only return visible windows (default: false)

**returns:** array of `window_info` objects

**window_info fields:**
- `hwnd` (number) - window handle
- `pid` (number) - process ID
- `process_name` (string) - process executable name
- `window_title` (string) - window title
- `class_name` (string) - window class name

### find_window

find a window by title or process name.

```lua
window = find_window(search_string)
```

returns first matching window or `nil`.

### get_foreground_window

get currently focused window.

```lua
window = get_foreground_window()
```

### set_foreground_window

bring window to foreground.

```lua
success = set_foreground_window(hwnd)
```

### minimize_window, maximize_window, restore_window

control window state.

```lua
minimize_window(hwnd)
maximize_window(hwnd)
restore_window(hwnd)
```

### set_window_position

move and resize window.

```lua
success = set_window_position(hwnd, x, y, width, height)
```

### get_window_rect

get window position and size.

```lua
rect = get_window_rect(hwnd)
```

**returns:** table with `x`, `y`, `width`, `height` or `nil`

### set_window_transparency

set window transparency.

```lua
success = set_window_transparency(hwnd, alpha)
```

**parameters:**
- `alpha` (number) - 0 (transparent) to 255 (opaque)

### flash_window

flash window in taskbar.

```lua
success = flash_window(hwnd, count)
```

### close_window

close window.

```lua
success = close_window(hwnd)
```

### exclude_window, include_window

exclude/include window from being captured by software (no exceptions apart from hardware i.e capture cards)

```lua
success = exclude_window(hwnd)
success = include_window(hwnd)
```

returns `true` if successful, `false` otherwise.

---

## data types

### vec2

2D vector.

```lua
v = vec2(x, y)
v = vec2()  -- zero vector
```

**fields:** `x`, `y`

**operations:** `+`, `-`, `*`, `/`

### vec3

3D vector.

```lua
v = vec3(x, y, z)
v = vec3()  -- zero vector
```

**fields:** `x`, `y`, `z`

**operations:** `+`, `-`, `*`, `/`

### vec4

4D vector.

```lua
v = vec4(x, y, z, w)
v = vec4()  -- zero vector
```

**fields:** `x`, `y`, `z`, `w`

**operations:** `+`, `-`, `*`, `/`

### membuffer

memory buffer for efficient operations.

```lua
buffer = membuffer(size)
```

#### buffer methods

##### get
```lua
value = buffer.get.TYPE(offset)
```

read typed value at offset.

##### set
```lua
buffer.set.TYPE(offset, value)
```

write typed value at offset.

##### get_string
```lua
str = buffer.get_string(offset, max_length)
```

read null-terminated string.

##### get_vec2, get_vec3, get_vec4
```lua
vec = buffer.get_vec2(offset)
vec = buffer.get_vec3(offset)
vec = buffer.get_vec4(offset)
```

read vector from buffer (as floats).

##### size
```lua
size = buffer.size()
```

get buffer size.

##### is_valid
```lua
valid = buffer.is_valid()
```

check if buffer is valid.

---

## math library

### matrices

#### creating matrices

```lua
m2 = mat2x2.row_major()
m2 = mat2x2.col_major()

m3 = mat3x3.row_major()
m3 = mat3x3.col_major()

m4 = mat4x4.row_major()
m4 = mat4x4.col_major()
```

row major for DirectX, column major for OpenGL.

#### matrix methods

##### get, set
```lua
value = matrix.get(row, col)
matrix.set(row, col, value)
```

access or modify individual matrix elements.

##### clear
```lua
matrix.clear()
```

set all elements to zero.

##### transposed
```lua
transposed = matrix.transposed()
```

returns a new matrix that is the transpose of the original (rows and columns swapped).

##### inverted
```lua
result = matrix.inverted()

if result then
    inverted_matrix = result
else
    -- matrix is not invertible (determinant is zero)
end
```

returns the inverted matrix if it exists, or `nil` if the matrix is singular (non-invertible).

##### determinant
```lua
det = matrix.determinant()
```

calculate the determinant of the matrix.

##### operations
```lua
-- matrix multiplication
m3 = m1 * m2

-- scalar multiplication
m2 = m1 * 2.5
```

**note:** addition (+) and subtraction (-) operators are not supported.

### trigonometry

#### radians_to_degrees, degrees_to_radians
```lua
deg = radians_to_degrees(radians)
rad = degrees_to_radians(degrees)
```

#### horizontal_fov_to_vertical, vertical_fov_to_horizontal
```lua
v_fov = horizontal_fov_to_vertical(h_fov, aspect_ratio)
h_fov = vertical_fov_to_horizontal(v_fov, aspect_ratio)
```

#### wrap_angle
```lua
wrapped = wrap_angle(angle, min, max)
```

normalize angle to specified range.

### projection

#### viewport
```lua
vp = viewport()
vp.width = 1920
vp.height = 1080
aspect = vp.aspect_ratio
```

#### fov
```lua
camera_fov = fov()
camera_fov = fov.from_degrees(90.0)
camera_fov = fov.from_radians(1.5708)

-- get current value
deg = camera_fov.as_degrees()
rad = camera_fov.as_radians()

-- trigonometric functions
s = camera_fov.sin()
c = camera_fov.cos()
t = camera_fov.tan()
```

field of view angle (clamped between 0° and 180°).

### camera

engine-specific camera implementations for world-to-screen projection.

#### supported engines

```lua
cam = source_camera(position, angles, viewport, fov, near, far)
cam = opengl_camera(position, angles, viewport, fov, near, far)
cam = unreal_camera(position, angles, viewport, fov, near, far)
cam = unity_camera(position, angles, viewport, fov, near, far)
cam = iw_camera(position, angles, viewport, fov, near, far)
```

#### view angles

```lua
-- create view angles
angles = source_view_angles()
angles = source_view_angles(pitch_deg, yaw_deg, roll_deg)

-- access angle components (returns Angle objects)
pitch = angles.pitch
yaw = angles.yaw
roll = angles.roll

-- get values in degrees or radians
pitch_deg = angles.pitch.as_degrees()
pitch_rad = angles.pitch.as_radians()
```

each engine has its own view angles type: `source_view_angles`, `opengl_view_angles`, `unreal_view_angles`, `unity_view_angles`, `iw_view_angles`

#### camera methods

##### world_to_screen
```lua
result = cam.world_to_screen(world_position)

if result.has_value() then
    screen_pos = result.value()
    print(screen_pos.x, screen_pos.y)
end
```

convert 3D world position to 2D screen coordinates.

##### screen_to_world
```lua
result = cam.screen_to_world(screen_position)

if result.has_value() then
    world_pos = result.value()
end
```

convert 2D screen position to 3D world coordinates.

##### look_at
```lua
cam.look_at(target_position)
```

point camera at target.

##### property getters/setters
```lua
cam.set_field_of_view(fov(110.0))
cam.set_near_plane(0.5)
cam.set_far_plane(5000.0)
cam.set_origin(vec3(0, 0, 100))
cam.set_view_angles(angles)
cam.set_view_port(viewport)

current_fov = cam.get_field_of_view()
current_near = cam.get_near_plane()
current_far = cam.get_far_plane()
current_origin = cam.get_origin()
current_angles = cam.get_view_angles()
```

##### get_view_projection_matrix
```lua
matrix = cam.get_view_projection_matrix()
```

get combined view-projection matrix for the camera.

### engine utilities

engine-specific mathematical utility functions for each game engine.

#### available engines

all functions are available for each engine:
- `source_engine` - source engine (valve games)
- `opengl_engine` - opengl-based engines
- `unreal_engine` - unreal engine
- `unity_engine` - unity engine
- `iw_engine` - infinity ward engine (call of duty)

#### forward_vector, right_vector, up_vector

```lua
forward = source_engine.forward_vector(angles)
right = source_engine.right_vector(angles)
up = source_engine.up_vector(angles)
```

get direction vectors from view angles.

**parameters:**
- `angles` - view angles for the specific engine

**returns:**
- `vec3` - direction vector

#### rotation_matrix

```lua
rot_matrix = source_engine.rotation_matrix(angles)
```

get rotation matrix from view angles.

**parameters:**
- `angles` - view angles for the specific engine

**returns:**
- `mat4x4` - rotation matrix

#### calc_view_matrix

```lua
view_matrix = source_engine.calc_view_matrix(angles, origin)
```

calculate view matrix from camera angles and position.

**parameters:**
- `angles` - camera view angles
- `origin` (vec3) - camera position

**returns:**
- `mat4x4` - view matrix

#### calc_perspective_projection_matrix

```lua
proj_matrix = source_engine.calc_perspective_projection_matrix(fov, aspect, near, far)
```

calculate perspective projection matrix.

**parameters:**
- `fov` (float) - field of view in degrees
- `aspect` (float) - aspect ratio (width/height)
- `near` (float) - near plane distance
- `far` (float) - far plane distance

**returns:**
- `mat4x4` - projection matrix

**example:**
```lua
-- source engine example
local angles = source_view_angles(0, 90, 0)
local origin = vec3(0, 0, 100)

-- get direction vectors
local forward = source_engine.forward_vector(angles)
local right = source_engine.right_vector(angles)
local up = source_engine.up_vector(angles)

-- calculate matrices
local view_mat = source_engine.calc_view_matrix(angles, origin)
local proj_mat = source_engine.calc_perspective_projection_matrix(90, 16/9, 1, 1000)
```

### triangle

3D triangle type for geometric calculations.

```lua
tri = triangle(v1, v2, v3)
tri = triangle()
```

**parameters:**
- `v1`, `v2`, `v3` (vec3) - triangle vertices

#### triangle properties

```lua
tri.v1 = vec3(0, 0, 0)
tri.v2 = vec3(1, 0, 0)
tri.v3 = vec3(0, 1, 0)
```

#### triangle methods

##### calculate_normal
```lua
normal = tri.calculate_normal()
```

calculate surface normal vector.

##### side_a_length, side_b_length
```lua
len_a = tri.side_a_length()
len_b = tri.side_b_length()
```

get length of triangle sides.

##### side_a_vector, side_b_vector
```lua
vec_a = tri.side_a_vector()
vec_b = tri.side_b_vector()
```

get direction vectors for triangle sides.

##### hypot
```lua
hypot_len = tri.hypot()
```

get hypotenuse length (distance from v1 to v3).

##### is_rectangular
```lua
is_right = tri.is_rectangular()
```

check if triangle is a right triangle.

##### mid_point
```lua
center = tri.mid_point()
```

get center point of triangle.

### 3d primitives

functions to create 3D geometric primitives as triangle arrays.

#### create_box

```lua
triangles = create_box(top, bottom, dir_forward, dir_right, ratio)
triangles = create_box(top, bottom, dir_forward, dir_right)
```

create a 3D box from top and bottom points.

**parameters:**
- `top` (vec3) - top center point of box
- `bottom` (vec3) - bottom center point of box
- `dir_forward` (vec3) - forward direction vector
- `dir_right` (vec3) - right direction vector
- `ratio` (float, optional) - size ratio, default is 4.0

**returns:**
- array of 12 triangles forming the box

**example:**
```lua
local top = vec3(0, 0, 10)
local bottom = vec3(0, 0, 0)
local forward = vec3(1, 0, 0)
local right = vec3(0, 1, 0)

local box = create_box(top, bottom, forward, right, 5.0)
```

#### create_plane

```lua
triangles = create_plane(vertex_a, vertex_b, direction, size)
```

create a 2D plane from two vertices.

**parameters:**
- `vertex_a` (vec3) - first vertex of plane
- `vertex_b` (vec3) - second vertex of plane
- `direction` (vec3) - direction to extend plane
- `size` (float) - size of plane

**returns:**
- array of 2 triangles forming the plane

**example:**
```lua
local v1 = vec3(0, 0, 0)
local v2 = vec3(10, 0, 0)
local dir = vec3(0, 0, 1)

local plane = create_plane(v1, v2, dir, 10.0)
```

### projectile prediction

ballistics and projectile trajectory prediction for moving targets.

#### projectile

```lua
proj = projectile()
proj.origin = vec3(0, 0, 0)
proj.launch_speed = 1000.0
proj.gravity_scale = 1.0
```

projectile configuration for trajectory calculations.

**properties:**
- `origin` (vec3) - launch position
- `launch_speed` (float) - initial velocity
- `gravity_scale` (float) - gravity multiplier

#### target

```lua
tgt = target()
tgt.origin = vec3(100, 50, 0)
tgt.velocity = vec3(10, 0, 0)
tgt.is_airborne = false
```

target configuration for prediction.

**properties:**
- `origin` (vec3) - current position
- `velocity` (vec3) - current velocity vector
- `is_airborne` (bool) - whether target is in air

#### projectile predictors

engine-specific projectile prediction systems.

```lua
predictor = source_projectile_predictor(gravity, time_step, max_time, tolerance)
predictor = opengl_projectile_predictor(gravity, time_step, max_time, tolerance)
predictor = unreal_projectile_predictor(gravity, time_step, max_time, tolerance)
predictor = unity_projectile_predictor(gravity, time_step, max_time, tolerance)
```

**parameters:**
- `gravity` (float) - gravity constant for simulation
- `time_step` (float) - simulation step size (smaller = more accurate)
- `max_time` (float) - maximum prediction time
- `tolerance` (float) - distance tolerance for hit detection

##### calculate_aim_point

```lua
result = predictor.calculate_aim_point(proj, tgt)

if result then
    aim_point = result
    print(aim_point.x, aim_point.y, aim_point.z)
else
    print("no solution found")
end
```

calculate where to aim to hit a moving target.

**parameters:**
- `proj` (projectile) - projectile configuration
- `tgt` (target) - target configuration

**returns:**
- `vec3` if solution found, `nil` otherwise

**example:**
```lua
local proj = projectile()
proj.origin = vec3(0, 0, 10)
proj.launch_speed = 800
proj.gravity_scale = 1.0

local tgt = target()
tgt.origin = vec3(200, 100, 10)
tgt.velocity = vec3(15, 5, 0)
tgt.is_airborne = false

local predictor = source_projectile_predictor(800, 0.01, 5.0, 1.0)
local aim = predictor.calculate_aim_point(proj, tgt)

if aim then
    print("aim at:", aim.x, aim.y, aim.z)
end
```

---

## utilities

### get_clipboard
```lua
text = get_clipboard()
```

get clipboard text content.

### set_clipboard
```lua
success = set_clipboard("text")
```

set clipboard text content.

---

## best practices

### memory operations

use `read_chain` for pointer chains:
```lua
local player = process.read_chain(base, {0x10, 0x20})
if player then
    local health = process.read.float(player)
end
```

use buffers for multiple reads:
```lua
local buf = process.read_buffer(address, 256)
if buf.is_valid() then
    local val1 = buf.get.float(0)
    local val2 = buf.get.int32(4)
end
```

### threading

always call `thread_poll` in your main loop:
```lua
thread_init()

register_callback(function()
    -- callback code
end, 100)

while true do
    thread_poll(0, 16)  -- process callbacks every 16ms
end
```

match poll timeout to callback frequency for efficiency.

### error handling

use `pcall` for error recovery:
```lua
local ok, err = pcall(function()
    local game = open_process("game.exe")
    local value = game.read.uint64(0x140001000)
end)

if not ok then
    print("error: " .. err)
end
```

### cleanup

always cleanup resources:
```lua
thread_init()
local callbacks = {}

table.insert(callbacks, register_callback(function() end, 100))

-- ... do work ...

for _, id in ipairs(callbacks) do
    unregister_callback(id)
end
thread_shutdown()
```
