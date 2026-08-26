local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1
L0_1 = {}
Settings = L0_1
L0_1 = false
L1_1 = {}
L1_1.interactDistance = 3.0
L1_1.impoundPrice = 500
L1_1.handcuffItems = true
L1_1.handcuffsItemName = "handcuffs"
L1_1.ziptiesItemName = "zipties"
L1_1.handcuffsSkillCheck = true
L1_1.sprintWhileDrag = false
L1_1.disableTargetInteractions = false
L1_1.tackleCooldown = 10000
L1_1.tackleRadius = 2.0
L2_1 = {}
L2_1.steal = false
L2_1.handcuff = false
L2_1.drag = false
L2_1.carry = false
L2_1.bill = false
L2_1.revive = false
L2_1.heal = false
L1_1.playerActions = L2_1
L2_1 = {}
L2_1.putInsideVehicle = false
L2_1.takeOutOfVehicle = false
L2_1.hijack = false
L2_1.repair = false
L2_1.clean = false
L2_1.impound = false
L1_1.vehicleActions = L2_1
L2_1 = {}
L2_1.steal = 3000
L2_1.revive = 10000
L2_1.heal = 5000
L2_1.hijack = 1000
L2_1.repair = 10000
L2_1.clean = 10000
L2_1.impound = 10000
L1_1.durations = L2_1
function L2_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L0_2 = {}
  L1_2 = pairs
  L2_2 = Settings
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
    L7_2 = #L0_2
    L7_2 = L7_2 + 1
    L8_2 = {}
    L9_2 = json
    L9_2 = L9_2.encode
    L10_2 = L6_2
    L9_2 = L9_2(L10_2)
    L10_2 = L5_2
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L0_2[L7_2] = L8_2
  end
  L1_2 = MySQL
  L1_2 = L1_2.prepare
  L1_2 = L1_2.await
  L2_2 = "UPDATE lunar_jobscreator_settings SET `value` = ? WHERE `key` = ?"
  L3_2 = L0_2
  L1_2(L2_2, L3_2)
end
L3_1 = MySQL
L3_1 = L3_1.ready
function L4_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L0_2 = Wait
  L1_2 = 1000
  L0_2(L1_2)
  L0_2 = pairs
  L1_2 = L1_1
  L0_2, L1_2, L2_2, L3_2 = L0_2(L1_2)
  for L4_2, L5_2 in L0_2, L1_2, L2_2, L3_2 do
    L6_2 = Settings
    L6_2[L4_2] = L5_2
    L6_2 = MySQL
    L6_2 = L6_2.insert
    L6_2 = L6_2.await
    L7_2 = "INSERT IGNORE INTO lunar_jobscreator_settings (`key`, `value`) VALUES (?, ?)"
    L8_2 = {}
    L9_2 = L4_2
    L10_2 = json
    L10_2 = L10_2.encode
    L11_2 = L5_2
    L10_2, L11_2 = L10_2(L11_2)
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L8_2[3] = L11_2
    L6_2(L7_2, L8_2)
  end
  L0_2 = MySQL
  L0_2 = L0_2.query
  L0_2 = L0_2.await
  L1_2 = "SELECT * FROM lunar_jobscreator_settings"
  L0_2 = L0_2(L1_2)
  L1_2 = 1
  L2_2 = #L0_2
  L3_2 = 1
  for L4_2 = L1_2, L2_2, L3_2 do
    L5_2 = L0_2[L4_2]
    L6_2 = Settings
    L7_2 = L5_2.key
    L8_2 = json
    L8_2 = L8_2.decode
    L9_2 = L5_2.value
    L8_2 = L8_2(L9_2)
    L6_2[L7_2] = L8_2
  end
  L1_2 = true
  L0_1 = L1_2
end
L3_1(L4_1)
L3_1 = RegisterNetEvent
L4_1 = "lunar_unijob:updateSettings"
function L5_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = source
  L2_2 = Framework
  L2_2 = L2_2.getPlayerFromId
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L3_2 = IsPlayerAdmin
    L4_2 = L2_2.source
    L3_2 = L3_2(L4_2)
    if L3_2 then
      goto lbl_14
    end
  end
  do return end
  ::lbl_14::
  Settings = A0_2
  L3_2 = TriggerClientEvent
  L4_2 = "lunar_unijob:updateSettings"
  L5_2 = -1
  L6_2 = A0_2
  L3_2(L4_2, L5_2, L6_2)
  L3_2 = L2_1
  L3_2()
end
L3_1(L4_1, L5_1)
L3_1 = lib
L3_1 = L3_1.callback
L3_1 = L3_1.register
L4_1 = "lunar_unijob:getSettings"
function L5_1()
  local L0_2, L1_2
  while true do
    L0_2 = L0_1
    if L0_2 then
      break
    end
    L0_2 = Wait
    L1_2 = 100
    L0_2(L1_2)
  end
  L0_2 = Settings
  return L0_2
end
L3_1(L4_1, L5_1)
