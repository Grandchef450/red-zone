Config = {}

-- ═══════════════════════════════════════════════════════════════════
--  REDZONE — PAGER
--  Corrigé le 29 août 2026
--
--  ⚠️  CORRECTION MAJEURE : Config.ItemName valait "pepper" — du
--  poivre, resté du script d'origine. Cet item n'existe pas dans
--  items.lua, donc avec RequireItem = true PERSONNE ne pouvait
--  ouvrir le pager. Il pointe désormais sur l'item 'pager', qu'il
--  faut ajouter à ox_inventory (bloc fourni à part).
-- ═══════════════════════════════════════════════════════════════════

Config.MaxFrequency = 999
Config.MinFrequency = 100
Config.MaxNicknameLength = 15
Config.MinNicknameLength = 3

-- 50 caractères, c'était court pour coordonner un groupe. 140 laisse
-- la place à une vraie phrase sans transformer le pager en messagerie.
Config.MaxMessageLength = 140

Config.NotificationDuration = 4000 -- ms
Config.PagerBottomOffset = 20 -- px


-- ═══════════════════════════════════════════════════════════════════
--  FRAMEWORK
--  Qbox expose ses exports sous le nom « qb-core » via son pont de
--  compatibilité, donc l'option qbcore fonctionne telle quelle.
-- ═══════════════════════════════════════════════════════════════════
Config.Framework = "qbcore"


-- ═══════════════════════════════════════════════════════════════════
--  ITEM REQUIS
-- ═══════════════════════════════════════════════════════════════════
Config.RequireItem = true
Config.ItemName = "pager"   -- ← corrigé, valait "pepper"


-- ═══════════════════════════════════════════════════════════════════
--  ANIMATION
-- ═══════════════════════════════════════════════════════════════════
Config.PhoneModel = "prop_npc_phone_02"
Config.AnimDict = "cellphone@"
Config.AnimName = "cellphone_text_read_base"


-- ═══════════════════════════════════════════════════════════════════
--  TEXTES
-- ═══════════════════════════════════════════════════════════════════
Config.Locale = {
    ["no_pager"]            = "Aucun pager détecté.",
    ["message_too_long"]    = "ERREUR : MESSAGE TROP LONG. LIMITE : %d CARACTÈRES.",
    ["set_nickname_first"]  = "ERREUR : DÉFINIS UN INDICATIF AVANT. COMMANDE : /NICK <NOM>",
    ["set_frequency_first"] = "ERREUR : DÉFINIS UNE FRÉQUENCE AVANT. COMMANDE : /FREQ <100-999>",
    ["frequency_set"]       = "FRÉQUENCE CONFIGURÉE SUR : %d",
    ["nickname_set"]        = "INDICATIF CONFIGURÉ SUR : %s",
    ["nickname_length"]     = "L'INDICATIF DOIT CONTENIR ENTRE %d ET %d CARACTÈRES.",
    ["nickname_set_chat"]   = "Indicatif configuré : %s",
    ["invalid_frequency"]   = "FRÉQUENCE NON VALIDE. VALEURS AUTORISÉES : %d-%d"
}

Config.UI = {
    ["title"]                = "PAGER RZ-1",
    ["placeholder_message"]  = "Saisir un message...",
    ["placeholder_freq"]     = "Fréquence (100-999)",
    ["placeholder_nick"]     = "Indicatif",
    ["button_send"]          = "ENVOYER",
    ["button_freq"]          = "DÉFINIR FRÉQUENCE",
    ["button_nick"]          = "DÉFINIR INDICATIF",
    ["close"]                = "FERMER"
}
