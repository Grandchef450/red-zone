local list = {
    ['framework'] = {
        header = "Framework not detected",
        text = "In order to fix that error go to server.cfg file and make sure that ZSX_Multicharacters starts after your framework.",
        docs = ""
    }, 
    ['is_config_multichar_enabled'] = {
        header = "Config.Multichar value is not set to true",
        text = "In order to fix that error follow up the docs below.",
        docs = ""
    },
    ['other_multichar_running'] = {
        header = "Other Multicharacter is running",
        text = "If other instance of Multicharacter is running it needs to be either removed or stopped from starting at all.",
        docs = ""
    },
    ['user_prefix_proper'] = {
        header = "Character Prefix is incorrect",
        text = "Multicharacter detected that one/some of your characters list in users table does not follow the required template.",
        docs = ""
    },
}

return list