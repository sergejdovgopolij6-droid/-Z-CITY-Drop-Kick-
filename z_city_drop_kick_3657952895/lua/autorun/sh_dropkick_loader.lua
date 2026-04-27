if SERVER then
    AddCSLuaFile("autorun/client/cl_fake.lua")

    -- Ждем секунду, чтобы база Homigrad загрузилась первой, 
    -- а потом "накрываем" её своим кодом.
    hook.Add("Initialize", "ZCity_Priority_Loader", function()
        timer.Simple(1, function()
            include("autorun/server/sv_control.lua")
            print("[Z-city Drop&Kick] ПРИОРИТЕТ УСТАНОВЛЕН!")
        end)
    end)
end