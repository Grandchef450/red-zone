const base = {
    characters: [],
    currentCharacterId: -1,
    isActive: false,
    isLogout: false,
    filters: {
        index: 0,
        data: {},
        name: 'GAME_FILTERS'
    },
    cameras: {
        index: 0,
        data: {},
        name: 'CAMERA_ANIMATION',
    },
    settingsSet: false,
    configSet: false,
    settingsDisabled: false,
    defaultSettings: {},
    canChangeSetting: true,
    canUseLocationsOnLogout: null,
    keydownsUsable: true,
    loader: function(state) {
        state ? $('.loader-content').css({display: 'flex'}).hide().fadeIn() : $('.loader-content').fadeOut()
    },
    show: function(state) {
        if (state == this.isActive) return
        state ? $('.multicharacter-container').css({display: 'flex'}).hide().fadeIn() : $('.multicharacter-container').fadeOut()
        anime({
            targets: [".center-name-box", ".user-job", ".x-marks"],
            translateX: state ? ['5vw', '0vw'] : ['0vw', '5vw'],
            easing: 'cubicBezier(0.075, 0.82, 0.165, 1)',
            duration: 2250,
        })

        anime({
            targets: [".bottom-content"],
            translateY: state ? ['5vw', '0vw'] : ['0vw', '5vw'],
            easing: 'cubicBezier(0.075, 0.82, 0.165, 1)',
            duration: 3250,
        })
        
        this.isActive = state
    },
    setLocationsDisabled: function(state) {
        $('.spawn-location-button').css({display: state ? 'none' : 'flex'})
    },
    setIsLogout: function(state) {
        this.isLogout = state
        if (state && !this.canUseLocationsOnLogout) return $('.spawn-location-button').css({display: 'none'})
        $('.spawn-location-button').css({display: 'flex'})
    },
    setSlotsAmount: function(amount) {
        $('.character-navs').empty()
        let totalCharacters = amount
        if (totalCharacters == 0) totalCharacters = 1
        for(let charNumbers=1; charNumbers<=totalCharacters; charNumbers++) {
            $('.character-navs').append(`<div class="character character-new" data-key="${charNumbers}">
                <div class="icon"><i class="fas fa-plus"></i></div>
                <div class="text">${ZSX.Translations.Interface['NEW_CHAR']}</div>
            </div>`)
        }
    },
    isSettingsDisabled: function() {
        return this.settingsDisabled
    },
    setData: function(data) {
        this.characters = data
        for(const[_, char] of Object.entries(this.characters)) {
            let charId = Number(char.id)
            let characterDiv = $('.character').eq(charId - 1)
            $(characterDiv).data('key', charId)
            $(characterDiv).removeClass('character-new')
            $(characterDiv).html(`<div class="icon">${charId}</div>
            <div class="text">${char.firstname + ' ' + char.lastname}</div>`)
        }
    },
    setDefaultSettings: function(settings) {
        if (!this.settingsSet) {
            this.defaultSettings = settings
            this.settingsSet = true
            storage.prepare()
        }
    },
    isSettingsSet: function() {
        return this.settingsSet
    },
    getDefaultSettings: function() {
        return this.defaultSettings
    },
    updateEntity: async function(data, id) {
        const multicharacterContainer = document.querySelector('.multicharacter-container');
        const checkOpacity = () => {
            return new Promise(resolve => {
                const opacity = window.getComputedStyle(multicharacterContainer).getPropertyValue('opacity');
                if (parseFloat(opacity) !== 1.0) {
                    resolve();
                } else {
                    setTimeout(() => checkOpacity().then(resolve), 100);
                }
            });
        };
        await checkOpacity();
        $('.remove-box-user-name').html(data.firstname + ' ' + data.lastname)
        const userName = new TextScramble(document.querySelector('.name-box-user-name'))
        userName.setText(data.firstname + ' ' + data.lastname)
        const userNameStroked = new TextScramble(document.querySelector('.stroked-user-name'))
        userNameStroked.setText(data.firstname + ' ' + data.lastname)
        
        $('.user-job').html(data.job.name != 'unemployed' ? ('<span>' + data.job.label + ' ' + data.job.grade_label) : data.job.label)
        this.currentCharacterId = id
    },
    setSpawnLocationVisibility: function(state) {
        $('.spawn-location-button').css({display: state ? 'flex' : 'none'})
    },
    getCurrentCharId: function() {return this.currentCharacterId},

    getCharacterData: function(key) {
        return this.characters[key]
    },
    isConfigSet: function() {
        return this.configSet
    },
    setConfig: function(Config) {
        !Config.UI['settings'] && $('.settings-button').remove()
        !Config.UI['spawn_selector'] && $('.spawn-location-button').remove()
        !Config.UI['discord'] ? $('.discord-content-button').remove() : $('.discord-content-button').attr('data-url', Config.UI['discord'])
        !Config.UI['youtube'] ? $('.youtube-content-button').remove() : $('.youtube-content-button').attr('data-url', Config.UI['youtube'])
        !Config.UI['website'] ? $('.website-content-button').remove() : $('.website-content-button').attr('data-url', Config.UI['website'])
        !Config.UI['delete_character'] && $('.remove-content-button').remove()
        this.settingsDisabled = !Config.UI['settings']
        this.canUseLocationsOnLogout = Config.CanSwapLocationOnLogout
        this.dateFormat = Config.DateFormat
        
        this.useUIV2Music = Config.UseMusicFromUIV2
        this.useIdentityDupeCheck = Config.IdentityDuplicateCheck
        
        if (this.useUIV2Music) {
            $('.nav-settings[data-type="music"]').removeClass('active').hide()
            $('.nav-settings[data-type="interface"]').addClass('active')
            $('.child-settings-screen[data-type="music"]').css({top: '-100%'})
            $('.child-settings-screen[data-type="interface"]').css({top: '0%'})
            $.post(`https://${GetParentResourceName()}/UIReady`, JSON.stringify({}))
        }
        let dateFormatString = 'DD / MM / YYYY'
        
        if (this.dateFormat == 1) {
            dateFormatString = 'DD / MM / YYYY'
        } else if (this.dateFormat == 2) {
            dateFormatString = 'MM / DD / YYYY'
        } else if (this.dateFormat == 3) {
            dateFormatString = 'YYYY / DD / MM'
        } else if (this.dateFormat == 4) {
            dateFormatString = 'YYYY / MM / DD'
        }
        
        $('.identity-input-date').attr('placeholder', dateFormatString)
        $('.server-logo').attr('src', Config.ServerLogo)
        this.configSet = true
    },

    setConfigUserSettings: async function(Config) {
        this.filters.data = Config.Filters
        this.cameras.data = Config.Cameras
        let filtersSettings = storage.getUserSettings('filters')
        for(let i=0; i<this.filters.data.length; i++) {
            if (filtersSettings && filtersSettings.name) {
                if (this.filters.data[i].name == filtersSettings.name) {
                    this.filters.index = i
                    $(`.slider-name[data-content="${this.filters.name}"]`).html(this.filters.data[i].label)
                    break
                }
            }
        }
        let camerasSettings = storage.getUserSettings('cameras')
        for(let i=0; i<this.cameras.data.length; i++) {
            if (camerasSettings && camerasSettings.name) {
                if (this.cameras.data[i].name == camerasSettings.name) {
                    this.cameras.index = i
                    $(`.slider-name[data-content="${this.cameras.name}"]`).html(this.cameras.data[i].label)
                    break
                }
            }
        }

        this.applyBaseUserSetting('filters')
        this.applyBaseUserSetting('cameras')
    },
    updateUserSetting: function(setting, increment) {
        if (increment) {
            this[setting].index += 1
        } else {
            this[setting].index -= 1
        }
        this.animateChangeOfUserSetting(setting, this[setting].index)
        this.adjustUserSettingState(setting)
        storage.updateUserSettings(setting, this[setting].data[this[setting].index])
        $.post(`https://${GetParentResourceName()}/updatedUserSetting`, JSON.stringify({
            setting: setting,
            index: this[setting].index,
            settingData: this[setting].data[this[setting].index]
        }))
    },

    setUserSetting: function(setting, value) {
        this[setting].index = value
        storage.updateUserSettings(setting, this[setting].data[this[setting].index])
        this.animateChangeOfUserSetting(setting, this[setting].index)
        this.adjustUserSettingState(setting)
        $.post(`https://${GetParentResourceName()}/updatedUserSetting`, JSON.stringify({
            setting: setting,
            index: this[setting].index,
            settingData: this[setting].data[this[setting].index]
        }))
    },
    
    animateChangeOfUserSetting: function(setting, currIndex) {
        this.canChangeSetting = false
        let currentSetting = this[setting].data[currIndex]
        anime({
            targets: `.slider-name[data-content="${this[setting].name}"]`,
            left: ['0%', '-100%'],
            easing: 'cubicBezier(0.075, 0.82, 0.165, 1)',
            duration: 300,
            complete: ()=> {
                $(`.slider-name[data-content="${this[setting].name}"]`).html(currentSetting.label)
                anime({
                    targets: `.slider-name[data-content="${this[setting].name}"]`,
                    left: ['100%', '0%'],
                    easing: 'cubicBezier(0.075, 0.82, 0.165, 1)',
                    duration: 300,
                    complete: ()=> {
                        this.canChangeSetting = true
                    },
                })
            },
        })
    },

    adjustUserSettingState: function(setting) {
        if (this[setting].data[this[setting].index + 1] == undefined) {
            $(`.control-button[data-content="${this[setting].name}"][data-action="NEXT"]`).addClass('disabled')
        }
        if (this[setting].data[this[setting].index - 1] == undefined) {
            $(`.control-button[data-content="${this[setting].name}"][data-action="PREV"]`).addClass('disabled')
        }

        if (this[setting].data[this[setting].index + 1] != undefined) {
            $(`.control-button[data-content="${this[setting].name}"][data-action="NEXT"]`).removeClass('disabled')
        }

        if (this[setting].data[this[setting].index - 1] != undefined) {
            $(`.control-button[data-content="${this[setting].name}"][data-action="PREV"]`).removeClass('disabled')
        }
    },
    applyBaseUserSetting: function(setting) {
        if (this[setting].data[this[setting].index + 1] == undefined || this[setting].data[this[setting].index - 1] == undefined) {
            $(`.control-button[data-content="${this[setting].name}"][data-action="${this[setting].data[this[setting].index + 1] == undefined ? 'NEXT' : 'PREV'}"]`).addClass('disabled')
        } else if (this[setting].data[this[setting].index + 1] != undefined || this[setting].data[this[setting].index - 1] != undefined) {
            $(`.control-button[data-content="${this[setting].name}"][data-action="${this[setting].data[this[setting].index + 1] == undefined ? 'NEXT' : 'PREV'}"]`).removeClass('disabled')
        }
    },

    canUseKeydowns: function() {
        return this.keydownsUsable
    }, 
    setKeydownsUsable: function(state) {
        this.keydownsUsable = state
    }
}

const storage = {
    videoId: false,
    dropTick: 0,
    darkMode: false,
    userSettings: {},
    storageSet: false,
    isStorageSet: function() {
        return this.storageSet
    },
    prepare: async function() {
        this.videoId = localStorage.getItem('videoID')
        this.dropTick = localStorage.getItem('dropTick')
        this.darkMode = localStorage.getItem('darkMode') == 'false' ? false : true
        if (base.isSettingsDisabled()) {
            this.userSettings = base.getDefaultSettings()
        } else {
            this.userSettings = localStorage.getItem('userSettings') != null ? JSON.parse(localStorage.getItem('userSettings')) : base.getDefaultSettings()
        }
        settings.setThemeMode(this.darkMode) 
        $.post(`https://${GetParentResourceName()}/gatherStorage`, JSON.stringify({
            videoId: this.videoId,
            dropTick: this.dropTick,
            darkMode: this.darkMode,
            userSettings: this.userSettings
        }))
    },

    getUserSettings: function(key) {
        return this.userSettings[key]
    },

    updateDropTick: function(tick) {
        tick = tick - 3
        localStorage.setItem('dropTick', tick)
        settings.saver('UPDATE_DROP')
        this.dropTick = tick
        $.post(`https://${GetParentResourceName()}/updateStorage`, JSON.stringify({
            key: 'dropTick',
            data: this.dropTick
        }))
    },
    updateVideoId: function(id) {
        localStorage.setItem('videoID', id)
        settings.saver('UPDATE_URL')
        this.videoId = id
        $.post(`https://${GetParentResourceName()}/updateStorage`, JSON.stringify({
            key: 'videoId',
            data: this.videoId
        }))
    },
    updateDarkMode: function() {
        this.darkMode = !this.darkMode
        localStorage.setItem('darkMode', this.darkMode)
        $.post(`https://${GetParentResourceName()}/updateStorage`, JSON.stringify({
            key: 'darkMode',
            data: this.darkMode
        }))
        settings.saver('UPDATE_THEME')
    },
    settingsToTranslate: {
        ['filters']: 'GAME_FILTERS',
        ['cameras']: 'CAMERA_ANIMATION',
        ['cartoon_anims']: 'CARTOON_ANIMATIONS',
    },
    updateUserSettings: function(setting, value) {
        settings.saver(this.settingsToTranslate[setting])
        this.userSettings[setting] = value
        localStorage.setItem('userSettings', JSON.stringify(this.userSettings))
        $.post(`https://${GetParentResourceName()}/updateStorage`, JSON.stringify({
            key: 'userSettings',
            data: this.userSettings
        }))
    }
}

const infoText = {
    isActive: false,
    show: function(state, text) {
        $('.loading-information').stop().animate({opacity: state ? 1 : 0})
        if (!text) {
            $('.loading-information .text').addClass('no-text')
        } else {
            $('.loading-information .text').html(text)
            $('.loading-information .text').removeClass('no-text')
        }
    }
}

const awaiter = {
    isActive: false,
    show: function(state, nomusic) {
        if (state == this.isActive) return
        state ? $('.loader-container').css({display: 'flex'}).hide().fadeIn(250) : $('.loader-container').fadeOut()
        this.isActive = state
        if (nomusic) return
        state ? music.fade(15, 1000) : music.fade(30, 1000)
    }
}

const locations = {
    active: false,
    activeKey: "last",
    locations: {},
    canSwapLocation: true,
    order: { 
        last: 1, 
        property: 2, 
        default: 3 
    },
    init: function(state, locations) {
        if (state == this.isActive) return
        if (state) this.setLocations(locations)
        state ? $('.locations-screen').css({display: 'flex'}).hide().fadeIn(500) : $('.locations-screen').fadeOut()
        this.active = state
    },
    setLocations: function(locations) {
        this.locations = locations
        this.activeKey = 'last'
        const location = new TextScramble(document.querySelector('.location-text'))
        location.setText('Last Location')
        $('.locations-screen .locations-list').empty()
        $('.locations-screen .navbar').empty()

        var sortedArray = Object.entries(locations).sort((a, b)=> {
            return this.order[a[1].type] - this.order[b[1].type];
        });
        
        var sortedObject = {};
        sortedArray.forEach((entry)=> {
            sortedObject[entry[0]] = entry[1];
        });

        for(const[key, location] of Object.entries(sortedObject)) {
            if (location.visible) {
                
                $('.locations-screen .navbar').append(`
                    <div class="location location-nav" data-name="${key}">
                        <div class="icon">${location.type == "property" ? '<i class="fas fa-home"></i>' : location.type == "default" ? '<i class="fas fa-map-marker-alt"></i>' : location.type == "last" ? '<i class="fas fa-play"></i>' : ''}</div>
                        <div class="text-box">
                            <div class="type">${location.type == 'default' ? location.label : ZSX.Translations.Locations[location.type]}</div>
                            <div class="text">${location.type == 'default' ? location.street : (location.label == 'location' ? ZSX.Translations.Locations['location'] : location.label)}</div>
                        </div>
                    </div>
                    `)
        
                    $('.locations-screen .locations-list').append(`
                    <div class="location location-spawn" data-name="${key}">
                    <div class="icon">${location.type == "property" ? '<i class="fas fa-home"></i>' : location.type == "default" ? '<i class="fas fa-map-marker-alt"></i>' : location.type == "last" ? '<i class="fas fa-play"></i>' : ''}</div>
                        <div class="line"></div>
                        <div class="text-box">
                            <div class="type">${location.type == 'default' ? location.label : ZSX.Translations.Locations[location.type]}</div>
                            <div class="text">${location.type == 'default' ? location.street : (location.label == 'location' ? ZSX.Translations.Locations['location'] : location.label)}</div>
                        </div>
                    </div>
                    `)
                location.active && $(`.location-nav[data-name="${key}"]`).addClass('active')
            }
        }
    },

    updateLocation: function(location) {
        if (!location.onScreen) {
            return $(`.location-spawn[data-name="${location.key}"]`).hide()
        }
        $(`.location-spawn[data-name="${location.key}"]`).show()
        $(`.location-spawn[data-name="${location.key}"]`).css({
            left: location.screen.x + '%',
            top: location.screen.y + '%',
        })
    },

    handleClick: function(key) {
        if (!this.canSwapLocation) return
        this.canSwapLocation = false
        $(`.location-nav`).removeClass('active')
        $(`.location-nav[data-name="${key}"]`).addClass('active')
        $.post(`https://${GetParentResourceName()}/handleLocationClick`, JSON.stringify({
            key: key
        }), callback=> {
            if (callback == 'OK') {
                this.canSwapLocation = true
            }
        })
        this.activeKey = key
        const location = new TextScramble(document.querySelector('.location-text'))
        location.setText(this.locations[key].label != 'Location' ? this.locations[key].label : 'Last Location')
    },

    sortKeys: function() {
        const keys = Object.keys(this.locations);
        
        const index = keys.indexOf("Last");
        if (index !== -1) {
          keys.splice(index, 1);
          keys.unshift("Last");
        }
        
        keys.sort((a, b) => a.localeCompare(b));
        
        const sortedObject = {};
        keys.forEach(key => {
          sortedObject[key] = this.locations[key];
        });
        
        return sortedObject
    },
}


const welcomeScreen = {
    isActive: false,
    queue: false,
    init: function(state) {
        this.slideBars(state)
    },
    slider: function() {
        anime({
            targets: ['.slider-bar-anim'],
            right: ['190vw', '0'],
            easing: 'cubicBezier(0.075, 0.82, 0.165, 1)',
            duration: 3000,
            complete: ()=> {
                anime({
                    targets: ['.slider-bar-anim'],
                    right: ['0vw', '-190vw'],
                    easing: 'cubicBezier(0.075, 0.82, 0.165, 1)',
                    duration: 2000,
                })
            }
        })
    },
    slideBars: async function(state) {
        if (state == this.isActive) return
        this.isActive = state
        if (state) {
            this.queue = true
            anime({
                targets: ['.welcome-logo'],
                opacity: [0,1],
                scale: ['0.6', '1.5'],
                easing: 'cubicBezier(1, 0, 0, 1)',
                duration: 1500,
                complete: ()=> {
                    this.queue = false
                }
            })
            anime({
                targets: ['.bar-right'],
                left: ['100%', '0%'],
                easing: 'cubicBezier(1, 0, 0, 1)',
                duration: 1200,
            })
            anime({
                targets: ['.bar-left'],
                left: ['-100%', '0%'],
                easing: 'cubicBezier(1, 0, 0, 1)',
                duration: 1200,
            })
        } else if (!state) {
            if (this.queue) {
                await new Promise((resolve) => {
                    const checkVariable = () => {
                      if (this.queue === false) {
                        resolve();
                      } else {
                        setTimeout(checkVariable, 100);
                      }
                    };
                    checkVariable();
                });
            }
            music.sfx.play()
            anime({
                targets: ['.bar-right'],
                left: ['0%', '-100%'],
                easing: 'cubicBezier(1, 0, 0, 1)',
                duration: 1200,
            })
            anime({
                targets: ['.bar-left'],
                left: ['0%', '100%'],
                easing: 'cubicBezier(1, 0, 0, 1)',
                duration: 1200,
            })
            
            anime({
                targets: ['.welcome-logo'],
                opacity: [1,0],
                scale: ['1.5', '.6'],
                easing: 'cubicBezier(1, 0, 0, 1)',
                duration: 1500,
            })
        }
    }
}

const tooltip = {
    isActive: false,
    show: function(state) {
        if (state == this.isActive) return
        state ? $('.tool-tip-content').css({opacity: 1}) : $('.tool-tip-content').css({opacity: 0})
        this.isActive = state
    },
    setText: function(data) { 
        if (!data) return
        $('.tool-tip-content').find('.header').html('TOOLTIP / ' + data.header)
        $('.tool-tip-content').find('.text').html(data.text)
    }
}

const music = {
    player: null,
    cachedURL: null,
    state: null,
    tickInterval: false,
    fadeInterval: false,
    music: {
        default: null,
        volume: .0,
    },
    sfx: new Howl({
        src: ['./metadata/sfx.wav'],
        html5: false,
        loop: false,
        autoplay: false,
        volume: .3,
    }),
    FX_ENTRANCE: new Howl({
        src: ['./metadata/FX_ENTRANCE.wav'],
        html5: false,
        loop: false,
        autoplay: false,
        volume: .3,
    }),
    FX_WIND_1: new Howl({
        src: ['./metadata/fx_wind_stage_1.mp3'],
        html5: false,
        loop: false,
        autoplay: false,
        volume: .9,
    }),
    FX_WIND_2: new Howl({
        src: ['./metadata/fx_wind_stage_2.mp3'],
        html5: false,
        loop: false,
        autoplay: false,
        volume: .9,
    }),
    extractVideoId: function(url) {
        const pattern = /(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?&v=|.*[?&]v=))([^?&]+)(?:[?&]|\b)/;
        const match = url.match(pattern);
        if (match && match[1]) {
            return match[1];
        } else {
            return null;
        }
    },

    setDefaultMusicData: function(ConfigMusic) {
        this.music['default'] = ConfigMusic.default
        this.music['volume'] = localStorage.getItem('videoVolume') != null ? Number(localStorage.getItem('videoVolume')) : ConfigMusic.volume * 100
        $(`.col-children[data-content="DEFAULT_VOLUME"]`).find('.row-children').find('.percentage').html(Math.floor(this.music['volume']) + '%')
        $('#DEFAULT_VOLUME').val(this.music['volume'] / 100)
    },

    handleMusicInput: function(number) {
        localStorage.setItem('videoVolume', number)
        this.music['volume'] = number
    },

    controls: function() {
        if (this.player.seekTo == null || this.player.seekTo == undefined) return
        if (this.state == 'PLAYING') {
            this.player.pauseVideo()
            
        } else {
            this.player.playVideo()
            
        }
    },
    seek: function(percentage) {
        if (this.player.seekTo == null || this.player.seekTo == undefined) return
        let duration = this.player.getDuration()
        let time = Math.floor(percentage * duration)
        let minutes = Math.floor(time / 60)
        let remainingSeconds = time % 60
        $('.player-tick').html(`${minutes}:${(remainingSeconds < 10) ? '0' + remainingSeconds : remainingSeconds}`)
        $('.player-actual-progress').css({width: percentage * 100 + '%'})
        this.player.seekTo(time)
        this.player.playVideo()
    },
    updateMusic: function(id) {
        if (!id) return
        if (this.state == 'PLAYING') this.player.stopVideo()
        this.player.loadVideoById(id)
        this.player.playVideo()
        $('#video_url_content').val('')
        storage.updateVideoId(id)
    },
    updateTickInterval: function(state) {
        if (this.tickInterval) {
            clearInterval(this.tickInterval)
        }
        
        if (state) {
            this.tickInterval = setInterval(()=> {
                let seconds = Math.floor(this.player.getCurrentTime())
                let minutes = Math.floor(seconds / 60)
                let remainingSeconds = seconds % 60
                $('.player-tick').html(`${minutes}:${(remainingSeconds < 10) ? '0' + remainingSeconds : remainingSeconds}`)
                $('.player-actual-progress').css({width: (this.player.getCurrentTime() / this.player.getDuration()) * 100 + '%'})
            }, 1000)
        }
    },
    updateAudioTitle: function(title) {
        $('.player-title').html(title)
    },
    updateDropTick: function() {
        if (this.player.getCurrentTime() <= 3) return
        storage.updateDropTick(this.player.getCurrentTime())
    },
    fade: function(targetVolume, duration) {
        if (this.player.seekTo == null || this.player.seekTo == undefined) return
        if (this.fadeInterval) {
            clearInterval(this.fadeInterval);
            this.fadeInterval = false
        }
        const initialVolume = this.player.getVolume();
        const volumeChangeInterval = 10;
        const steps = duration / volumeChangeInterval;
        const volumeStep = (targetVolume - initialVolume) / steps;

        let currentStep = 0;

        this.fadeInterval = setInterval(() => {
            if (currentStep < steps) {
                const newVolume = initialVolume + currentStep * volumeStep;
                this.player.setVolume(newVolume);
                currentStep++;
            } else {
                this.player.setVolume(targetVolume);
                clearInterval(this.fadeInterval);
            }
        }, volumeChangeInterval);
    },
    setVolume: function(value) {
        this.player.setVolume(value)
    },
    checkForBuffer: function(conditionFn, interval = 100) {
        return new Promise((resolve) => {
          const checkCondition = () => {
            if (conditionFn()) {
              resolve();
            } else {
              setTimeout(checkCondition, interval);
            }
          };
          checkCondition();
        });
    },
    adjustState: async function(state) {
        if (state == 'STOP') {
            this.fade(0, 1000)
        } else if (state == 'START') {
            $.post(`https://${GetParentResourceName()}/UIReady`, JSON.stringify({}))
            if (this.player.seekTo == null || this.player.seekTo == undefined) return
            this.player.seekTo(storage.dropTick)
            await this.checkForBuffer(()=> {
                return this.state == 'PLAYING'
            })
            this.fade(this.music['volume'], 3000)
        } else if (state == 'VOLUME_DOWN') {
            this.fade(10, 2000)
        } else if (state == 'VOLUME_UP') {
            this.fade(this.music['volume'], 2000) 
        }
    }
}

const screens = {
    canUse: true,
    current: false,
    transitions: {
        ['char-creator-container']: {
            init: {
                alignment: 'top',
                data: ['100%', '0%']
            },
            final: {
                alignment: 'top',
                data: ['0%', '-100%'],
            },
        },
        ['settings-container']: {
            init: {
                alignment: 'left',
                data: ['100%', '0%']
            },
            final: {
                alignment: 'left',
                data: ['0%', '100%'],
            },
        },
    },
    showScreen: function(screen, init) {
        if (!this.canUse) return
        this.canUse = false
        if (init) settings.handleNavbar(base.useUIV2Music ? 'interface' : 'music')
        base.setKeydownsUsable(false)
        this.transitions[screen][init ? 'init' : 'final'].alignment == 'left' ? anime({
            targets: '.' + screen,
            left: this.transitions[screen][init ? 'init' : 'final'].data,
            easing: 'cubicBezier(1, 0, 0, 1)',
            duration: 700,
            complete: ()=> {
                base.setKeydownsUsable(true)
                this.canUse = true
                this.current = init ? screen : false
            }
        }) : anime({
            targets: '.' + screen,
            top: this.transitions[screen][init ? 'init' : 'final'].data,
            easing: 'cubicBezier(1, 0, 0, 1)',
            duration: 700,
            complete: ()=> {
                this.canUse = true
                this.current = init ? screen : false
            }
        })

        this.transitions[screen][init ? 'init' : 'final'].alignment == 'left' ? anime({
            targets: '.multicharacter-container',
            left: init ? ['0%', '-100%'] : ['-100%', '0%'],
            easing: 'cubicBezier(1, 0, 0, 1)',
            duration: 700,
        }) : anime({
            targets: '.multicharacter-container',
            top: init ? ['0%', '-100%'] : ['-100%', '0%'],
            easing: 'cubicBezier(1, 0, 0, 1)',
            duration: 700,
        })
    },
    updateScreen: function(screen) {
        this.current = screen
    },
}

const settings = {
    current: 'music',
    canUse: true,
    themeMode: 0,
    handleNavbar: function(next) {
        if (!next || !this.canUse) return
        this.canUse = false
        $('.nav-settings.active').removeClass('active')
        $(`.nav-settings[data-type="${next}"]`).addClass('active')
        let alignment = ($(`.child-settings-screen[data-type="${this.current}"]`).index() < $(`.child-settings-screen[data-type="${next}"]`).index()) ? [
            ['0%', '-100%'],
            ['100%', '0%']
        ] : [
            ['0%', '100%'],
            ['-100%', '0%']
        ]
        anime({
            targets: `.child-settings-screen[data-type="${this.current}"]`,
            top: alignment[0],
            easing: 'cubicBezier(0.075, 0.82, 0.165, 1)',
            duration: 1000,
        })
        anime({
            targets: `.child-settings-screen[data-type="${next}"]`,
            top: alignment[1],
            easing: 'cubicBezier(0.075, 0.82, 0.165, 1)',
            duration: 1000,
            complete: ()=> {
                if (next == 'game') base.setKeydownsUsable(true)
                this.current = next
                this.canUse = true
            }
        })
        if (next == 'game') {
            base.setKeydownsUsable(false)
            $('.back-button').removeClass('disabled')
            $('.settings-navbar').addClass('disabled')
            $('.settings-container').addClass('background-less')
            $.post(`https://${GetParentResourceName()}/slideCameraForce`, JSON.stringify({alignment: 'left', init: false}))
        } else {
            $('.back-button').addClass('disabled')
            $('.settings-navbar').removeClass('disabled')
            if (this.current == 'game') $.post(`https://${GetParentResourceName()}/slideCameraForce`, JSON.stringify({alignment: 'left', init: true}))
            $('.settings-container').removeClass('background-less')
        }
    },
    getCurrentScreen: function() {
        return this.current
    },
    setThemeMode: function(isDarkMode) {
        this.darkMode = isDarkMode
        $(':root').css({
            '--primary-background': this.darkMode ? '#0E0E0E' : '#FFF',
            '--nav-background': this.darkMode ? '#FFF' : '#1a1a1a',
            '--secondary-background': this.darkMode ? '#dadada' : '#626262',
            '--tertiary-background': this.darkMode ? '#24242435' : '#d9d9d935',
            '--primary-color': this.darkMode ? '#FFF' : '#1a1a1a',
            '--inverted-primary-color': this.darkMode ? '#1a1a1a' : '#fff',
        })
        const scrambler = new TextScramble(document.querySelector('.theme-mode'))
        scrambler.setText(ZSX.Translations.Basic[this.darkMode ? 'DARK_MODE' : 'LIGHT_MODE'])
    },
    swapThemeMode: function() {
        this.darkMode = !this.darkMode
        $(':root').css({
            '--primary-background': this.darkMode ? '#0E0E0E' : '#FFF',
            '--nav-background': this.darkMode ? '#FFF' : '#1a1a1a',
            '--secondary-background': this.darkMode ? '#dadada' : '#626262',
            '--tertiary-background': this.darkMode ? '#24242435' : '#d9d9d935',
            '--primary-color': this.darkMode ? '#FFF' : '#1a1a1a',
            '--inverted-primary-color': this.darkMode ? '#1a1a1a' : '#fff',
        })
        storage.updateDarkMode()
        const scrambler = new TextScramble(document.querySelector('.theme-mode'))
        scrambler.setText(ZSX.Translations.Basic[this.darkMode ? 'DARK_MODE' : 'LIGHT_MODE'])
    },
    handleSlidersStatus: function(targetToSlide, sliderToggler) {
        let sliderTarget = $(`.slider-context[data-sliderType="${targetToSlide}"]`)
        let sliderActive = $(sliderTarget).hasClass('active')
        let sliderTogglerActive = $(sliderToggler).hasClass('unhovered')
        if (sliderActive && sliderTogglerActive) {$(sliderTarget).removeClass('active'); $(sliderToggler).removeClass('unhovered') }
        if (!sliderActive && !sliderTogglerActive) {$(sliderTarget).addClass('active'); $(sliderToggler).addClass('unhovered')}
    },

    sliderTypeToSetting: {
        ['GAME_FILTERS']: 'filters',
        ['CAMERA_ANIMATION']: 'cameras',
        ['CARTOON_ANIMATIONS']: 'cartoon_anims',
    },
    handleSliderData: function(sliderType, isNext) {
        if ($(`.control-button[data-action="${isNext ? "NEXT" : "PREV"}"][data-content="${sliderType}"]`).hasClass('disabled')) return
        base.updateUserSetting(this.sliderTypeToSetting[sliderType], isNext)
    },

    handleButtonSlider: function(action) {
        if (action == 'GAME_FILTERS_RESET') {
            return base.setUserSetting('filters', 0)
        }

        $.post(`https://${GetParentResourceName()}/handleButtonSlider`, JSON.stringify({action: action}))
    },
    rangeVolumeUpdate: function(element, value) {
        $(`.col-children[data-content="${element}"]`).find('.row-children').find('.percentage').html(Math.floor(Number(value) * 100) + '%')
        music.setVolume(Number(value) * 100)
        music.handleMusicInput(Math.floor(Number(value) * 100))
    },
    saver: function(text) {
        $('.saving-text').html(ZSX.Translations.Saves[text])
        $('.saving-content').stop().animate({opacity: 1}).delay(2000).stop().animate({opacity: 0})
    },
}

const cinematics = {
    show: function(state) {
        if (state) {
            $('.cinematic-bar').addClass('active')
        } else {
            $('.cinematic-bar').removeClass('active')
        }
    },
    setText: function(state, text) {
        if (state) {
            const cinematicText = new TextScramble(document.querySelector('.cinematic-user-name'))
            cinematicText.setText(text)
        }
        state ? $('.cinematic-text-box').css({display: 'flex'}).hide().fadeIn(1200) : $('.cinematic-text-box').fadeOut(2000)
    }
}

const initial = {
    active: false,
    init: function(state, text) {
        if (this.active == state) return
        state && $('.initial-discord-user-name').html(text)
        state ? $('.initial-screen').css({display: 'flex'}).hide().fadeIn(3000) : $('.initial-screen').fadeOut(3000)
        this.active = state
    },
}

const creator = {
    isActive: false,
    errorsCount: 5,
    currentYear: Number(new Date().getFullYear()),
    isCheckingNames: false,
    formErrors: {
        firstname: false,
        lastname: false,
        date: false,
        height: false,
        nationality: false,
    },
    formData: {
        firstname: '',
        lastname: '',
        date: '',
        nationality: false,
        height: 0,
    },
    isCountriesShown: false,
    show: async function(state) {
        base.show(false)
        $('.identity-content').attr('style', '')
        $('.identity-logo').attr('style', '')
        this.clearForm()
        anime({
            targets: '.identity-bars',
            height: ['0%', '60%'],
            easing: 'cubicBezier(0.075, 0.82, 0.165, 1)',
            duration: 3000,
        })
        await new Promise(r => setTimeout(r, 1000));
        $('.identity-content').css({display: 'flex'}).hide().fadeIn()
        $('.identity-logo').css({display: 'flex'}).hide().fadeIn()
        this.isActive = true
    },
    hide() {
        anime({
            targets: '.identity-bars',
            height: ['60%', '0%'],
            easing: 'cubicBezier(0.075, 0.82, 0.165, 1)',
            duration: 3000,
        })

        anime({
            targets: '.identity-content',
            translateX: ['0', '-10%'],
            easing: 'cubicBezier(0.075, 0.82, 0.165, 1)',
            duration: 1500,
            complete() {
                $('.identity-content').css({transform: 'translateX(0)'}).hide()
            }
        })

        anime({
            targets: '.identity-logo',
            translateX: ['0', '10%'],
            easing: 'cubicBezier(0.075, 0.82, 0.165, 1)',
            duration: 1500,
            complete() {
                $('.identity-logo').css({transform: 'translateX(0)'}).hide()
            }
        })

        this.isActive = false


    },
    switchCountries: function() {
        this.isCountriesShown = !this.isCountriesShown
        if (this.isCountriesShown) {
            $('.identity-nationality-select').addClass('active')
            $('.select-nationality-button').addClass('active')
        } else {
            $('.identity-nationality-select').removeClass('active')
            $('.select-nationality-button').removeClass('active')
        }
    },
    prepareCountries: function() {
        $('.nationality-countries-list').empty()
        let countries = ZSX.Translations.Countries
        countries.forEach(country => {
            $('.nationality-countries-list').append(`<div class="search-element nationality-country" data-name="${country}">${country}</div>`)
        });
    },
    searchCountries: function(value) {
        let val = value.toLowerCase()
        let elements = $('.nationality-country')
        elements.each(function () {
            var countryText = $(this).text().toLowerCase();
            if (countryText.includes(val)) {
                $(this).show();
            } else {
                $(this).hide();
            }
        });
    },
    handleCountryClick: function(val) {
        $('.nationality-placeholder').addClass('active')
        $('.selected-country').html(val)
        this.formData['nationality'] = val
        this.formErrors['nationality'] = true
        let haveError = Object.values(this.formErrors).every(value => value === true)
        if (!haveError) $('.identity-create-button').addClass('disabled')
        if (haveError) $('.identity-create-button').removeClass('disabled')
    },
    handleGenderClick: function(target) {
        $('.identity-gender.active').removeClass('active')
        $(target).addClass('active')
        this.updateGender($(target).data('type') == 'male')
    },
    clearForm: function() {
        $('.identity-input-text').val('')
        $('.icon-is-succesfull .success').attr('style', '')
        $('.icon-is-succesfull .error').attr('style', '')
        $('.input-text').removeClass('active')
        $('.placeholder').removeClass('active')
        $('.identity-input-date').val('')
        $('.selected-country').html('.')
        $('.identity-gender.active').removeClass('active')
        $('.identity-gender[data-type="male"]').addClass('active')
        this.formErrors = {
            firstname: false,
            lastname: false,
            date: false,
            height: false,
            nationality: false,
        }
        this.formData = {
            firstname: '',
            lastname: '',
            date: '',
            height: 0,
            gender: 'male',
            nationality: ''
        }
        $('.identity-create-button').addClass('disabled')
    },
    notificationAnimeObjIn: false,
    notificationAnimeObjOut: false,
    addNotification(text) {
        if (this.notificationAnimeObj) this.notificationAnimeObjIn.stop()
        if (this.notificationAnimeObjOut) this.notificationAnimeObjOut.stop()
        $('.identity-notification').html(text)
        this.notificationAnimeObjIn = anime({
            targets: '.identity-notification',
            top: '3vw',
            easing: 'cubicBezier(0.075, 0.82, 0.165, 1)',
            opacity: 1,
            complete: ()=> {
                this.notificationAnimeObjIn = false
                this.notificationAnimeObjOut = anime({
                    targets: '.identity-notification',
                    top: '-2vw',
                    opacity: 0,
                    easing: 'cubicBezier(0.075, 0.82, 0.165, 1)',
                    complete: ()=> {this.notificationAnimeObjOut = false}
                })
            }
        })
    },
    onInput: function(type) {
        var error = false
        if (type == 'firstname' || type == 'lastname') {
            let value = $(`.identity-input-text[data-type="${type}"]`).val()
            let stringArray = value.split('')
            let notContainsNumber = /\d/.test(value);
            this.formData[type] = value
            
            // Basic validation
            error = stringArray.length < 1 || stringArray.length > 15 || notContainsNumber;
            
            // Update the UI for basic validation first
            if (!base.useIdentityDupeCheck) {
                this.updateValidationUI(type, error)
            } else {
                if (!error) {
                    this.checkFullNameWhenReady()
                }
            }
            // If basic validation passes, check if we should validate full name
            
            
            return // Always return here for name fields
            
        } else if (type == 'date') {
            let value = $(`.identity-input-date`).val()
            this.formData[type] = value
            let stringArray = value.split('')
            let day = Number(stringArray[0] + '' + stringArray[1])
            let month = Number(stringArray[5] + '' + stringArray[6])
            let year = Number(stringArray[10] + '' + stringArray[11] + '' + stringArray[12] + '' + stringArray[13])
            if (base.dateFormat === 1) {            // DD/MM/YYYY
                day   = Number(stringArray[0] + stringArray[1]);
                month = Number(stringArray[3] + stringArray[4]);
                year  = Number(stringArray[6] + stringArray[7] + stringArray[8] + stringArray[9]);
              }
              else if (base.dateFormat === 2) {       // MM/DD/YYYY
                month = Number(stringArray[0] + stringArray[1]);
                day   = Number(stringArray[3] + stringArray[4]);
                year  = Number(stringArray[6] + stringArray[7] + stringArray[8] + stringArray[9]);
              }
              else if (base.dateFormat === 3) {       // YYYY/DD/MM
                year  = Number(stringArray[0] + stringArray[1] + stringArray[2] + stringArray[3]);
                day   = Number(stringArray[5] + stringArray[6]);
                month = Number(stringArray[8] + stringArray[9]);
              }
              else if (base.dateFormat === 4) {       // YYYY/MM/DD
                year  = Number(stringArray[0] + stringArray[1] + stringArray[2] + stringArray[3]);
                month = Number(stringArray[5] + stringArray[6]);
                day   = Number(stringArray[8] + stringArray[9]);
              }
            
            error = stringArray.length < 14 || (month < 1 || month > 12) || (day < 1 || day > 31) || (year > this.currentYear || year < this.currentYear - 100)
        } else if (type == 'height') {
            let value = $(`.identity-input-number[data-type="height"]`).val()
            this.formData[type] = Number(value)
            error = Number(value) < 120 || Number(value) > 220
        }

        this.updateValidationUI(type, error)
    },

    // Check full name only when both names are ready
    checkFullNameWhenReady: function() {
        let firstName = this.formData.firstname
        let lastName = this.formData.lastname
        
        // Only check if both names are filled and pass basic validation
        if (firstName && lastName && firstName.length >= 1 && lastName.length >= 1 && 
            firstName.length <= 15 && lastName.length <= 15 && 
            !/\d/.test(firstName) && !/\d/.test(lastName)) {
            
            this.checkFullNameAvailability(firstName, lastName)
        }
    },

    // Add timeout for debouncing
    nameCheckTimeout: null,
    checkFullNameAvailability: function(firstName, lastName) {
        // Clear previous timeout
        if (this.isCheckingNames) return
        if (this.nameCheckTimeout) {
            clearTimeout(this.nameCheckTimeout)
        }
        
        // Set checking flag
        this.isCheckingNames = true
        this.updateCreateButtonState()
        
        // Set a timeout to debounce the requests
        this.nameCheckTimeout = setTimeout(() => {
            // Show loading state for both firstname and lastname
            $(`.icon-is-succesfull[data-type="firstname"]`).find('.success, .error').fadeOut(125, () => {
                $(`.icon-is-succesfull[data-type="firstname"]`).html('<i class="fas fa-spinner fa-spin"></i>')
            })
            $(`.icon-is-succesfull[data-type="lastname"]`).find('.success, .error').fadeOut(125, () => {
                $(`.icon-is-succesfull[data-type="lastname"]`).html('<i class="fas fa-spinner fa-spin"></i>')
            })
            
            $.post(`https://${GetParentResourceName()}/checkNameAvailability`, JSON.stringify({
                firstName: firstName,
                lastName: lastName
            }), (isAvailable) => {
                // Clear checking flag
                
                // Restore original icon structure for both fields
                setTimeout(()=> {
                    $(`.icon-is-succesfull[data-type="firstname"]`).html(`
                        <div class="success" style="display: none;"><i class="fas fa-check"></i></div>
                        <div class="error" style="display: none;"><i class="fas fa-times"></i></div>
                    `)
                    $(`.icon-is-succesfull[data-type="lastname"]`).html(`
                        <div class="success" style="display: none;"><i class="fas fa-check"></i></div>
                        <div class="error" style="display: none;"><i class="fas fa-times"></i></div>
                    `)
                    this.isCheckingNames = false
                    let hasError = !isAvailable
                
                    // Update both firstname and lastname validation status
                    this.formErrors['firstname'] = !hasError
                    this.formErrors['lastname'] = !hasError
                    
                    this.updateValidationUI('firstname', hasError)
                    this.updateValidationUI('lastname', hasError)
                    
                    if (!isAvailable) {
                        this.addNotification('Character name is already taken.')
                    }
                }, 200)
            }).fail(() => {
                // Handle request failure
                
                this.isCheckingNames = false
                this.formErrors['firstname'] = false
                this.formErrors['lastname'] = false
                this.updateCreateButtonState()
            })
        }, 100) // 500ms delay
    },

    // Update the validation UI method
    updateValidationUI: function(type, error) {
        if (type != 'date') {
            if (error) {
                $(`.icon-is-succesfull[data-type="${type}"]`).find('.success').fadeOut(125, () => {
                    $(`.icon-is-succesfull[data-type="${type}"]`).find('.error').fadeIn(125)
                })
            } else {
                $(`.icon-is-succesfull[data-type="${type}"]`).find('.error').fadeOut(125, () => {
                    $(`.icon-is-succesfull[data-type="${type}"]`).find('.success').fadeIn(125)
                })
            }
        } else {
            if (error) {
                $('.icon-date').css({opacity: .15, filter: 'drop-shadow(0 0 10px rgba(255, 255, 255, 0.0))'})
            } else {
                $('.icon-date').css({opacity: 1, filter: 'drop-shadow(0 0 10px rgba(255, 255, 255, 0.382))'})
            }
        }

        this.formErrors[type] = !error
        this.updateCreateButtonState()
    },

    // New method to properly handle button state
    updateCreateButtonState: function() {
        let haveAllValid = Object.values(this.formErrors).every(value => value === true)
        let shouldEnable = haveAllValid && !this.isCheckingNames
        
        if (shouldEnable) {
            $('.identity-create-button').removeClass('disabled')
        } else {
            $('.identity-create-button').addClass('disabled')
        }
    },

    updateGender: function(male) {
        this.formData['gender'] = male ? 'male' : 'female'
    },
    finishLogin: function() {
        // Prevent creation if still checking names
        if (this.isCheckingNames) {
            return
        }
        
        // Check if all validations pass
        let haveAllValid = Object.values(this.formErrors).every(value => value === true)
        if (!haveAllValid) {
            return
        }
        
        let prevFormData = this.formData
        this.formData = {
            firstname: $('.identity-input-text[data-type="firstname"]').val(),
            lastname: $('.identity-input-text[data-type="lastname"]').val(),
            date: ($('.identity-input-date').val()).split(' ').join(''),
            height: Number($('.identity-input-number[data-type="height"]').val()),
            gender: prevFormData['gender'],
            nationality: prevFormData['nationality'],
        }
        anime({
            targets: '.identity-content',
            left: ['0%', '-100%'],
            easing: 'cubicBezier(0.075, 0.82, 0.165, 1)',
            duration: 600,
        })
        anime({
            targets: '.identity-logo',
            width: ['50%', '100%'],
            easing: 'cubicBezier(0.075, 0.82, 0.165, 1)',
            duration: 1200,
            complete: async ()=> {
                $.post(`https://${GetParentResourceName()}/userIdentityCreated`, JSON.stringify(this.formData), async callback=> {
                    await new Promise(r => setTimeout(r, 1000));
                    
                    music.sfx.play()
                    anime({
                        targets: '.identity-logo',
                        scale: [1, 0.0],
                        opacity: [1, 0],
                        easing: 'cubicBezier(0.075, 0.82, 0.165, 1)',
                        duration: 1000,
                    })
                    anime({
                        targets: '.identity-bars',
                        height: ['100%', '0%'],
                        easing: 'cubicBezier(0.075, 0.82, 0.165, 1)',
                        duration: 2000,
                    })
                    this.isActive = false
                })
                
            }
        })
    }
}

const timer = {
    start: function(time, text) {
        $('.timer-text').html(text)
        $('.timer-value').css({width: '0%'})
        $('.timer-screen').css({display: 'flex'}).hide().fadeIn()
        anime({
            targets: '.timer-value',
            width: ['0%', '100%'],
            easing: 'linear',
            duration: time,
            complete: ()=> {
                $('.timer-screen').fadeOut(100)
                $.post(`https://${GetParentResourceName()}/clothing_timer_end`, JSON.stringify({}))
            }
        })
    },
}

const characterRemove = {
    isVisible: false,
    show: function(state) {
        if (this.isVisible == state) return
        state ? $('.remove-user-screen').css({display: 'flex'}).hide().fadeIn() : $('.remove-user-screen').fadeOut()
        this.isVisible = state
    }
}