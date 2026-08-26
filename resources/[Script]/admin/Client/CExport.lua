-- ============================================================
-- DEOBFUSCATED SCRIPT
-- Original: Client/CExport.lua
-- Deobfuscated: 2026-04-09
-- Part: 1 of 1
-- ============================================================

-- [PURPOSE] Export: checks if the local player is an admin via ox_lib async callback
exports("IsAdmin", function()
    local callbackResult = lib.callback.await("adminpanel:isPlayerAdmin")
    return callbackResult
end)

-- [PURPOSE] Export: opens the admin panel by executing the configured command
exports("OpenAdminPanel", function()
    -- Uses Config.AdminCommand if set, otherwise falls back to "adminpanel"
    local command = Config.AdminCommand
    if not command then
        command = "adminpanel"
    end
    ExecuteCommand(command) -- FiveM native: executes a console command on the client
end)
