
    var tag = document.createElement('script');
    tag.src = "https://www.youtube.com/iframe_api";
    var firstScriptTag = document.getElementsByTagName('script')[0];
    firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);
    async function onYouTubeIframeAPIReady() {
        const waitForMusicReady = new Promise(resolve => {
            const checkMusicReady = () => {
                if (music.music.default !== null) {
                    resolve();
                } else {
                    setTimeout(checkMusicReady, 100);
                }
            };
            checkMusicReady();
        });
    
        waitForMusicReady.then(() => {
            let videoId = localStorage.getItem('videoID') || music.extractVideoId(music.music.default)
            music.player = new YT.Player('player', {
                height: '0',
                width: '0',
                videoId: videoId,
                playerVars: {
                    controls: 0, 
                    autoplay: 0,
                },
                events: {
                    'onReady': onPlayerReady,
                    'onStateChange': onPlayerStateChange,
                },
            });
            setTimeout(()=> {
                $.post(`https://${GetParentResourceName()}/music_ready`, JSON.stringify({}))
            }, 1500);
        });
    }
    
    function onPlayerReady(event) {
        let videoData = music.player.getVideoData()
        let thumbnailUrl = `https://img.youtube.com/vi/${videoData.video_id}/maxresdefault.jpg`;
        $('#player_bg').attr('src', thumbnailUrl)
        music.player.setVolume(0)
        music.updateAudioTitle(music.player.getVideoData().title)
    }

    function onPlayerStateChange(event) {
        music.updateAudioTitle(music.player.getVideoData().title)
        switch (event.data) {
            case YT.PlayerState.PLAYING:
                music.state = 'PLAYING'
                let videoData = music.player.getVideoData()
                let thumbnailUrl = `https://img.youtube.com/vi/${videoData.video_id}/maxresdefault.jpg`;
                $('#player_bg').attr('src', thumbnailUrl)
                music.updateTickInterval(true)
                $('.controls-player').html(`
                <svg viewBox="0 0 40 47" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <rect width="12" height="45" class="player-controls-svg"/>
                    <rect x="22" width="12" height="45" class="player-controls-svg"/>
                </svg>`)
                
                break;
            case YT.PlayerState.PAUSED:
                music.state = 'PAUSED'
                music.updateTickInterval(false)
                $('.controls-player').html(`<svg viewBox="0 0 40 47" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <path d="M0.0278374 46.3509L0.0278377 0.295218L39.9132 23.323L0.0278374 46.3509Z" class="player-controls-svg"/>
                </svg>`)
                break;
            case YT.PlayerState.ENDED:
                music.state = 'ENDED'
                music.updateTickInterval(false)
                music.player.playVideo()
                break;
            case YT.PlayerState.BUFFERING:
                music.state = 'BUFFERING'
                $('.controls-player').html(`<div class="buffer">
                <div class="progress"></div>
            </div>`)
                break;
            case YT.PlayerState.CUED:
                music.state = 'CUED'
                break;
            case YT.PlayerState.UNSTARTED:
                music.state = 'UNSTARTED'
                break;
        }
    }
    
    function waitUntil(condition, timeout = 100) {
        return new Promise((resolve, reject) => {
          const intervalId = setInterval(() => {
            if (condition()) {
              clearInterval(intervalId);
              resolve();
            }
          }, timeout);
      
          setTimeout(() => {
            clearInterval(intervalId);
          }, timeout);
        });
      }
