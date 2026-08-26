$(()=> {
    creator.prepareCountries()
    $.post(`https://${GetParentResourceName()}/music_ready`, JSON.stringify({}))
    $.post(`https://${GetParentResourceName()}/createdUIFrame`, JSON.stringify({}))
    $.datable('init');
    $('.button-settings').click(e=> {
        if ($(e.target).data('click') == 'UPDATE_URL') {
            music.updateMusic(music.extractVideoId($('#video_url_content').val()))
        } else if ($(e.target).data('click') == 'UPDATE_DROP') {
            music.updateDropTick()
        }
    })

    $('.player-progress').click(function(event) {
        let width = $(this).width();
        let pointX = event.pageX - $(this).offset().left;
        let percentage = (pointX / width);
        music.seek(percentage)
    })

    $(document).on('keydown', '#video_url_content', e=> {
        if (e.repeat) return
        if (e.code == 'Enter') {
            music.updateMusic(music.extractVideoId($('#video_url_content').val()))
        }
    })

    $(document).on('click', '.character', e=> {
        if ($(e.target).hasClass('character-new')) {
            $.post(`https://${GetParentResourceName()}/createNewCharacter`, JSON.stringify({id: Number($(e.target).data('key'))}))
        } else {
            $.post(`https://${GetParentResourceName()}/swapEntity`, JSON.stringify({
                key: Number($(e.target).data('key'))
            }))
        }
    })

    $('.controls-player').click(e=> {
        music.controls()
    })

    $('.tool-tip').on('mouseenter', e=> {
        let content = $(e.target).closest('.tool-tip').data('content')
        tooltip.setText(ZSX.Translations.ToolTip[content])
        tooltip.show(true)
    })

    $('.tool-tip').on('mouseleave', e=> {
        tooltip.show(false)
    })

    $('.settings-button').click(e=> {
        $.post(`https://${GetParentResourceName()}/screenShown`, JSON.stringify({screen: 'settings-container', alignment: 'left', init: true}))
    })

    $('.play-button').click(e=> {
        $.post(`https://${GetParentResourceName()}/selectedCharacter`, JSON.stringify({
            id: base.getCurrentCharId()
        }))
    })

    $(document).on('click', '.nav-settings',e=> {
        settings.handleNavbar($(e.target).data('type'))
    })

    $('.theme-mode').click(e=> {
        settings.swapThemeMode()
    })

    $(document).on('click', '.identity-gender', e=> {
        $('.gender-select.active').removeClass('active')
        $(e.target).addClass('active')
        $('.square-gender.active').removeClass('active')
        creator.handleGenderClick($(e.target))
        $(`.square-gender[data-type="${$(e.target).data('type')}"]`).addClass('active')
        $('.selected-gender').html($(e.target).data('type') == 'male' ? 'Male' : 'Female')
    })

    $('.settings-back-button').click(e=> {
        settings.handleNavbar(base.useUIV2Music ? 'interface' : 'music')
    })

    $('.unhover-context').click(e=> {
        let target = $(e.target).attr('data-sliderType')
        settings.handleSlidersStatus(target, $(e.target))
    })

    $('.control-button').click(e=> {
        settings.handleSliderData($(e.target).data('content'), $(e.target).data('action') == 'NEXT')
    })

    $('#DEFAULT_VOLUME').on('change input', e=> {
        settings.rangeVolumeUpdate('DEFAULT_VOLUME', $(e.target).val())
    })

    $(document).on('click', '.button-slider', e=> {
        settings.handleButtonSlider($(e.target).data('action'))
    })

    $(document).on('click', '.button-change-spawn', e=> {
        $.post(`https://${GetParentResourceName()}/locationsDisable`, JSON.stringify({key: locations.activeKey}))
    })

    $(document).on('click', '.location-nav', e=> {
        locations.handleClick($(e.target).attr('data-name'))
    })
    $(document).on('click', '.spawn-location-button', e=> {
        $.post(`https://${GetParentResourceName()}/locationsInit`, JSON.stringify({
            state: true
        }))
    })

    $(document).on('focus', '.identity-input-text, .identity-input-number', e=> {
        $(e.target).closest('.input-text').addClass('active')
    })

    $(document).on('blur', '.identity-input-text, .identity-input-number', e=> {
        if ($(e.target).val() != '') {
            return creator.onInput($(e.target).data('type'))
        }
        $(e.target).closest('.input-text').removeClass('active')
    })

    let typingTimer

    $(document).on('keyup', '.identity-input-text', e => {
        const inputType = $(e.target).data('type');
        
        // const sanitizedValue = e.target.value.replace(/[^a-zA-Z]/g, '');
        // e.target.value = sanitizedValue;
    
        clearTimeout(typingTimer);
        typingTimer = setTimeout(() => creator.onInput(inputType), 850);
    });
    
    $(document).on('keyup', '.identity-input-number, .identity-input-date', e=> {
        clearTimeout(typingTimer);
        typingTimer = setTimeout(creator.onInput($(e.target).data('type')), 850);
    });
    $(document).on('keydown', '.identity-input-number, .identity-input-text, .identity-input-date', e=> {
        clearTimeout(typingTimer);
    });

    $(document).on('input', '#dateInput', function () {
        let val = this.value.replace(/\D/g, ''); // Only digits
    
        if (val.length > 8) val = val.slice(0, 8); // Max DDMMYYYY
        
        let formatted = '';
        if (base.dateFormat <= 2) {
            //XX XX YYYY
            if (val.length > 0) {
                formatted += val.substring(0, 2);
            }
            if (val.length >= 3) {
                formatted += ' / ' + val.substring(2, 4);
            } else if (val.length > 2) {
                formatted += ' / ' + val.substring(2);
            }
            if (val.length >= 5) {
                formatted += ' / ' + val.substring(4, 8);
            } else if (val.length > 4) {
                formatted += ' / ' + val.substring(4);
            }
        } else {
            //YYYY XX XX
            if (val.length > 0) {
                formatted += val.substring(0, 4);
            }
            if (val.length >= 5) {
                formatted += ' / ' + val.substring(4, 6);
                if (val.length >= 7) {
                    formatted += ' / ' + val.substring(6, 8);
                } else if (val.length > 6) {
                    formatted += ' / ' + val.substring(6);
                }
            } else if (val.length > 4) {
                formatted += ' / ' + val.substring(4);
            }
        }
        
    
        this.value = formatted;
    });

    $(document).on('click', '.identity-create-button', e=> {
        if ($(e.target).hasClass('disabled')) return
        creator.finishLogin()
    })

    $(document).on('click', '.new-web-content-handler', e=> {
        let url = $(e.target).data('url')
        window.invokeNative('openUrl', url)
    })

    $(document).on('input change', '.identity-nationality-input-text', e=> {
        creator.searchCountries($(e.target).val())
    })
    
    $(document).on('click', '.select-nationality-button', e=> {
        creator.switchCountries()
    })
    
    $(document).on('click', '.nationality-country', e=> {
        creator.handleCountryClick($(e.target).data('name'))
    })

    $(document).on('click', '.remove-content-button', e=> {
        characterRemove.show(true)
    })

    $(document).on('click', '.button-remove-character', e=> {
        let remove = $(e.target).data('type') == 'remove'
        if (remove) {
            $.post(`https://${GetParentResourceName()}/removeCharacter`)
        }
        characterRemove.show(false)
    })
})

