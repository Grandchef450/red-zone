FrameworkSelected = GetResourceState('es_extended') == 'started' and 'ESX' or GetResourceState('qb-core') == 'started' and 'QBCore' or false
if not FrameworkSelected then
    debugPrint('[^2FRAMEWORK^7] Awaiting Framework [/]')
end
while not FrameworkSelected do
    Wait(0)
    FrameworkSelected = GetResourceState('es_extended') == 'started' and 'ESX' or GetResourceState('qb-core') == 'started' and 'QBCore' or false
end
debugPrint('[^2FRAMEWORK^7] Framework '..FrameworkSelected..' loaded!')
ESX = FrameworkSelected == 'ESX' and exports['es_extended']:getSharedObject() or false
QBCore = FrameworkSelected == 'QBCore' and exports['qb-core']:GetCoreObject() or false
IsQBOXEnabled = GetResourceState('qbx_core') == 'started'

ZSX_UI = 'ZSX_UI'
UserInterfaceActive = GetResourceState(ZSX_UI) == 'started'

--[[
    New interface handling for UIV2
]]

ZSX_UIV2 = 'ZSX_UIV2'
IsUIV2Active = GetResourceState(ZSX_UIV2) == 'started'