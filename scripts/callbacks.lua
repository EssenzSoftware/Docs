print("testing callback system...")

thread_init(2)

local explorer_monitor = register_callback(function()
    local process = open_process("explorer.exe")
    
    if process.is_valid() then
        local base = process.get_image_base()
        
        if base > 0 then
            local mz_signature = process.read.uint16(base)
            print("explorer.exe mz signature: " .. string.format("0x%04x", mz_signature))
            
            if mz_signature == 0x5a4d then
                print("valid pe header detected")
            end
        end
    else
        print("explorer.exe not found")
    end
end, 2000)

local counter_callback = register_callback(function()
    print("counter tick at " .. os.date("%H:%M:%S"))
end, 1000)

print("registered callbacks - explorer monitor: " .. explorer_monitor .. ", counter: " .. counter_callback)
print("active callbacks: " .. get_active_callback_count())

print("running for 10 seconds...")
local start_time = os.time()
while os.time() - start_time < 10 do
    thread_poll(0, 50)
end

print("unregistering counter callback...")
unregister_callback(counter_callback)
print("active callbacks: " .. get_active_callback_count())

print("running for 5 more seconds...")
start_time = os.time()
while os.time() - start_time < 5 do
    thread_poll(0, 50)
end

print("clearing all callbacks...")
clear_all_callbacks()
print("active callbacks: " .. get_active_callback_count())

thread_shutdown()
print("test completed")