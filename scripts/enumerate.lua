local function print_object_methods(obj, name)
    print("=== " .. name .. " methods ===")
    
    local methods = {}
    
    for k, v in pairs(getmetatable(obj) or {}) do
        if k ~= "__index" and k ~= "__gc" and type(v) == "function" then
            table.insert(methods, k .. " (metamethod)")
        end
    end
    
    local index = getmetatable(obj) and getmetatable(obj).__index
    if index then
        if type(index) == "table" then
            for k, v in pairs(index) do
                if type(v) == "function" then
                    table.insert(methods, k .. " (function)")
                elseif type(v) == "table" then
                    table.insert(methods, k .. " (property table)")
                    for prop_k, prop_v in pairs(v) do
                        table.insert(methods, "  " .. k .. "." .. prop_k .. " (" .. type(prop_v) .. ")")
                    end
                else
                    table.insert(methods, k .. " (" .. type(v) .. ")")
                end
            end
        end
    end
    
    local success, result = pcall(function()
        for k in pairs(obj) do
            local v = obj[k]
            if type(v) == "function" then
                table.insert(methods, k .. " (direct function)")
            elseif type(v) == "table" then
                table.insert(methods, k .. " (direct table)")
            end
        end
    end)
    
    table.sort(methods)
    for _, method in ipairs(methods) do
        print("  " .. method)
    end
    print()
end

print("=== global functions ===")
for name, value in pairs(_G) do
    if type(value) == "function" and (
        string.match(name, "^open_") or
        string.match(name, "^thread_") or
        string.match(name, "^vec[234]$") or
        name == "membuffer"
    ) then
        print(name .. " (function)")
    end
end

local process = open_process(0)
print_object_methods(process, "process handle")

local mouse = open_mouse()
print_object_methods(mouse, "mouse handle")

local keyboard = open_keyboard()
print_object_methods(keyboard, "keyboard handle")

local buffer = membuffer(16)
print_object_methods(buffer, "membuffer")

local v2 = vec2.new(0, 0)
print_object_methods(v2, "vec2")

local v3 = vec3.new(0, 0, 0)
print_object_methods(v3, "vec3")

local v4 = vec4.new(0, 0, 0, 0)
print_object_methods(v4, "vec4")

thread_init(1)
local pool = thread_pool.new()
print_object_methods(pool, "thread_pool")