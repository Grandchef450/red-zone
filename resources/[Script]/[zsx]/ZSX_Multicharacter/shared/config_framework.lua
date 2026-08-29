--[[
    ZSX_Multicharacter — détection du framework
    CORRIGÉ POUR QBOX — RedZone, 29 août 2026

    LE PROBLÈME D'ORIGINE
    Ce fichier ne cherchait que la ressource 'qb-core'. Or Qbox
    s'appelle 'qbx_core' : il fournit bien les EXPORTS sous le nom
    qb-core, via un pont de compatibilité, mais aucune ressource ne
    porte ce nom. GetResourceState('qb-core') renvoyait donc 'missing',
    FrameworkSelected restait à false, et la boucle d'attente
    ci-dessous tournait indéfiniment — à chaque frame, sur chaque
    client. C'est ce qui empêchait le multicharacter de démarrer.

    LA CORRECTION
    On accepte qbx_core comme équivalent de qb-core. Le reste du
    script continue de parler à exports['qb-core'], ce qui fonctionne
    grâce au pont de Qbox.
]]

local function detectFramework()
    if GetResourceState('es_extended') == 'started' then
        return 'ESX'
    end

    -- QBCore classique OU Qbox : les deux exposent exports['qb-core']
    if GetResourceState('qb-core') == 'started'
       or GetResourceState('qbx_core') == 'started' then
        return 'QBCore'
    end

    return false
end

FrameworkSelected = detectFramework()

if not FrameworkSelected then
    debugPrint('[^2FRAMEWORK^7] Awaiting Framework [/]')
end

-- Garde-fou : sans limite, un framework absent fait tourner cette
-- boucle à chaque frame pour toujours. Trente secondes suffisent
-- largement au démarrage le plus lent.
local deadline = GetGameTimer() + 30000

while not FrameworkSelected do
    Wait(250)
    FrameworkSelected = detectFramework()

    if GetGameTimer() > deadline then
        print('^1[ZSX] Aucun framework détecté après 30 s. ' ..
              'Vérifie que qbx_core démarre AVANT ZSX_Multicharacter.^7')
        break
    end
end

if FrameworkSelected then
    debugPrint('[^2FRAMEWORK^7] Framework '..FrameworkSelected..' loaded!')
end

ESX = FrameworkSelected == 'ESX' and exports['es_extended']:getSharedObject() or false
QBCore = FrameworkSelected == 'QBCore' and exports['qb-core']:GetCoreObject() or false

-- Déjà présent d'origine : ZSX sait gérer les identifiants Qbox.
IsQBOXEnabled = GetResourceState('qbx_core') == 'started'

ZSX_UI = 'ZSX_UI'
UserInterfaceActive = GetResourceState(ZSX_UI) == 'started'

--[[
    New interface handling for UIV2
]]

ZSX_UIV2 = 'ZSX_UIV2'
IsUIV2Active = GetResourceState(ZSX_UIV2) == 'started'
