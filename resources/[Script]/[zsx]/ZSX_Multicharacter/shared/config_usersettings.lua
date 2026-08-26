Config.Filters = {
    {
        name = 'none',
        label = 'None'
    },
    {
        name = 'NG_filmic01',
        label = 'Dark Night',
        value = .6,
    }, {
        name = 'NG_filmic02',
        label = 'Vintage',
        value = .95,
    }, {
        name = 'NG_filmic03',
        label = 'Light',
        value = .95,
    }, {
        name = 'NG_filmic04',
        label = 'Black & White',
        value = .95,
    }, {
        name = 'NG_filmic05',
        label = 'Stoned',
        value = .95,
    }, {
        name = 'NG_filmic19',
        label = "80's",
        value = .95,
    }, {
        name = 'NG_filmic07',
        label = "Weed Joy",
        value = .95,
    }, {
        name = 'NG_filmic08',
        label = "Night Lovel",
        value = .95,
    }, {
        name = 'NG_filmic09',
        label = "Alien Invasion",
        value = .95,
    }, {
        name = 'NG_filmic10',
        label = "Alien Invasion + Glitch",
        value = .95,
    }, {
        name = 'NG_filmic11',
        label = "Horror Story",
        value = .95,
    }, {
        name = 'NG_filmic21',
        label = "Camera",
        value = .95,
    }, {
        name = 'NG_filmic22',
        label = "Camera Night",
        value = .6,
    }, {
        name = 'NG_filmic23',
        label = "Blurred Out",
        value = .6,
    }, {
        name = 'NG_filmic25',
        label = "Ultra Light",
        value = .9,
    }, {
        name = 'nightvision',
        label = "Cyan",
        value = .9,
    },
}

Config.Cameras = {
    {
        name = 'slide_in',
        label = 'Slide In',
        rotations = {
            x = false,
            y = false,
            z = false,
        },
        offsets = {
            x = -3.25,
            y = 5.5,
            z = 0.3,
        },
    },
    {
        name = 'rotate_25',
        label = 'Rotated',
        rotations = {
            x = false,
            y = 25.0,
            z = false,
        },
        offsets = {
            x = -3.25,
            y = 5.5,
            z = 0.3,
        },
    }, {
        name = 'from_back',
        label = 'From the back',
        rotations = {
            x = false,
            y = -30.0,
            z = -50.0,
        },
        offsets = {
            x = -2.25,
            y = 10.0,
            z = 0.3,
        },
    }, {
        name = 'down_to_front',
        label = 'Down to front',
        rotations = {
            x = -30.0,
            y = false,
            z = false,
        },
        offsets = {
            x = 0.1,
            y = 8.2,
            z = 0.3,
        },
    }, 
}