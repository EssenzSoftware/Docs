thread_init(4)
local id1 = register_callback(function()
    print("tick 500ms")
end, 500)
local id2 = register_callback(function()
    print("tick 1000ms")
end, 1000)
local t0 = os.time()
while os.difftime(os.time(), t0) < 5 do
    thread_poll(10, 16)
end
unregister_callback(id1)
unregister_callback(id2)
thread_shutdown()
