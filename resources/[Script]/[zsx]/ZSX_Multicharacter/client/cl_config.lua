function canLogout()
    return true
end

Client = {}
Client.BlackScreen = function(state, slow)
    SendNUIMessage({
        type = 'HANDLE_BLACK_SCREEN',
        state = state,
        slow = slow
    })
    debugPrint('Handling Black Screen to state: ', state)
end

Client.HandlePreWarmup = function()
    if not Config.AwaitShutdownLoadingScreen then
        while not CreatedUIFrame do
            Wait(0)
        end
        Client.BlackScreen(true, true)
        Wait(1000)
        ShutdownLoadingScreen()
        ShutdownLoadingScreenNui()
    else
        debugPrint('Awaiting loading screen [/]')
        while GetIsLoadingScreenActive() do
            Wait(1)
        end
        Client.BlackScreen(true, false)
        debugPrint('Loading screen disabled, continue.')
    end
end