window.addEventListener('message', e=> {
    var NUI = e.data
    if (NUI.type == 'INIT') {
        base.show(NUI.state)
    }
    if (NUI.type == 'ADJUST_MUSIC') music.adjustState(NUI.state)
    if (NUI.type == 'HANDLE_SCREEN') screens.showScreen(NUI.screen, NUI.init)
    if (NUI.type == 'ADD_CHARACTERS') base.setData(NUI.data)
    if (NUI.type == 'AWAITER_INIT') awaiter.show(NUI.state, NUI.noMusic)
    if (NUI.type == 'UPDATE_ENTITY') base.updateEntity(NUI.data, NUI.id)
    if (NUI.type == 'SET_SLOTS') base.setSlotsAmount(NUI.data)
    if (NUI.type == 'WELCOME_SCREEN') welcomeScreen.init(NUI.state)
    if (NUI.type == 'FX_PLAY') music[NUI.data.fx].play()
    if (NUI.type == 'INFO_TEXT') infoText.show(NUI.state, NUI.text)
    if (NUI.type == 'SEND_USER_CONFIG') base.setConfigUserSettings(NUI.data)
    if (NUI.type == 'SEND_CONFIG') base.setConfig(NUI.data)
    if (NUI.type == 'SET_IS_LOGOUT') base.setIsLogout(NUI.state)
    if (NUI.type == 'SEND_DEFAULT_MUSIC') music.setDefaultMusicData(NUI.data)
    if (NUI.type == 'UPDATE_LOCATION') locations.updateLocation(NUI.data)
    if (NUI.type == 'LOCATIONS_INIT') locations.init(NUI.state, NUI.locations)
    if (NUI.type == 'SET_PLAYER_LOCATIONS_MANUALLY') locations.setLocations(NUI.locations)
    if (NUI.type == 'OVERRIDE_LOCATIONS_STATE') locations.setLocationsDisabled(NUI.state)
    if (NUI.type == 'PLAY_SFX') {
        if (music[NUI.sfx]) music[NUI.sfx].play()
    }
    if (NUI.type == 'SEND_DEFAULT_SETTIGNS') base.setDefaultSettings(NUI.data)
    if (NUI.type == 'SET_KEYDOWN_ARE_USABLE') base.setKeydownsUsable(NUI.state)
    if (NUI.type == 'CINEMATICS_INIT') cinematics.show(NUI.state)
    if (NUI.type == 'CINEMATICS_TEXT_BOX') cinematics.setText(NUI.state, NUI.text)
    if (NUI.type == 'SHOW_IDENTITY') creator.show()
    if (NUI.type == 'INITIAL_SCREEN_INIT') initial.init(NUI.state, NUI.text)
    if (NUI.type == 'CREATE_CLOTHING_TIMER') timer.start(NUI.time, NUI.text)
    if (NUI.type == 'HANDLE_BLACK_SCREEN') {
        NUI.state ? $('.black-screen-override').fadeIn(NUI.slow ? 1000 : 1) : $('.black-screen-override').fadeOut(NUI.slow ? 1000 : 1)
    }
    if (NUI.type == 'SET_SPAWN_LOCATION_VISIBILITY') {
        base.setSpawnLocationVisibility(NUI.state)
    }
    if (NUI.type == 'SET_COLOR') {
        document.documentElement.style.setProperty('--main-color', `rgb(${NUI.data.color.r}, ${NUI.data.color.g}, ${NUI.data.color.b})`);
    }
    if (NUI.type == 'SET_SLIDER_EFFECT') {
        welcomeScreen.slider()
    }
})



window.addEventListener('keydown', e=> {
    if (!base.canUseKeydowns()) return
    if (e.code == 'Enter') {
        if (!screens.current && !creator.isActive) {
            $.post(`https://${GetParentResourceName()}/selectedCharacter`, JSON.stringify({
                id: base.getCurrentCharId()
            }))
        } 
        if (locations.active) {
            $.post(`https://${GetParentResourceName()}/locationsDisable`, JSON.stringify({key: locations.activeKey}))
        }
        
    }

    if (e.code == 'Escape') {
        console.log(screens.current);
        
        if (screens.current != false) {
            if (settings.getCurrentScreen() == 'game') return settings.handleNavbar('music')
            $.post(`https://${GetParentResourceName()}/screenShown`, JSON.stringify({screen: screens.current, alignment: screens.transitions[screens.current]['final'].alignment, init: false}))
        } else if (locations.active) {
            $.post(`https://${GetParentResourceName()}/locationsDisable`, JSON.stringify({key: "noneSelected"}))
        } else if (creator.isActive) {
            $.post(`https://${GetParentResourceName()}/goBackFromIdentity`, JSON.stringify({}), cb=> {
                if (!cb) return
                creator.hide()
            })
        }
        
    }
})

document.addEventListener('keydown', function (e) {
    if (e.key === 'Tab') e.preventDefault();
});
