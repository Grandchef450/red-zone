local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1
L0_1 = {}
L0_1.onDutyCount = 0
L0_1.lastOnDutyCount = 0
L0_1.wealthiestJob = nil
L1_1 = {}
L0_1.jobCounts = L1_1
L1_1 = false
function L2_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L0_2 = GetJobs
  L0_2 = L0_2()
  L1_2 = {}
  L1_2.job = nil
  L1_2.balance = 0
  L2_2 = pairs
  L3_2 = L0_2
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
    L8_2 = Editable
    L8_2 = L8_2.getSocietyMoney
    L9_2 = L7_2.name
    L8_2 = L8_2(L9_2)
    if not L8_2 then
      L8_2 = 0
    end
    L9_2 = type
    L10_2 = L8_2
    L9_2 = L9_2(L10_2)
    if "number" ~= L9_2 or not L8_2 then
      L9_2 = tonumber
      L10_2 = L8_2
      L9_2 = L9_2(L10_2)
      L8_2 = L9_2 or L8_2
      if not L9_2 then
        L8_2 = 0
      end
    end
    L9_2 = L1_2.balance
    if L8_2 >= L9_2 then
      L9_2 = {}
      L9_2.job = L7_2
      L9_2.balance = L8_2
      L1_2 = L9_2
    end
  end
  L2_2 = L1_2.job
  if L2_2 then
    L2_2 = {}
    L3_2 = L1_2.job
    L3_2 = L3_2.label
    L2_2.label = L3_2
    L3_2 = L1_2.balance
    L2_2.balance = L3_2
    L0_1.wealthiestJob = L2_2
  end
end
L3_1 = lib
L3_1 = L3_1.callback
L3_1 = L3_1.register
L4_1 = "lunar_unijob:getStats"
function L5_1()
  local L0_2, L1_2
  while true do
    L0_2 = L1_1
    if L0_2 then
      break
    end
    L0_2 = Wait
    L1_2 = 100
    L0_2(L1_2)
  end
  L0_2 = L0_1
  return L0_2
end
L3_1(L4_1, L5_1)
L3_1 = lib
L3_1 = L3_1.cron
L3_1 = L3_1.new
L4_1 = "0 * * * *"
function L5_1()
  local L0_2, L1_2
  L0_2 = L2_1
  L0_2()
end
L3_1(L4_1, L5_1)
L3_1 = CreateThread
function L4_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  while true do
    L0_2 = AreJobsLoaded
    L0_2 = L0_2()
    if L0_2 then
      break
    end
    L0_2 = Wait
    L1_2 = 100
    L0_2(L1_2)
  end
  L0_2 = GetJobs
  L0_2 = L0_2()
  L1_2 = pairs
  L2_2 = L0_2
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
    L7_2 = L0_1.jobCounts
    L8_2 = L6_2.name
    L7_2[L8_2] = 0
  end
  L1_2 = L2_1
  L1_2()
  L1_2 = true
  L1_1 = L1_2
end
L3_1(L4_1)
L3_1 = SetInterval
function L4_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = TriggerClientEvent
  L1_2 = "lunar_unijob:updateStats"
  L2_2 = -1
  L3_2 = L0_1
  L0_2(L1_2, L2_2, L3_2)
end
L5_1 = 600000
L3_1(L4_1, L5_1)
L3_1 = {}
L4_1 = {}
function L5_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L3_2 = L3_1
  L3_2 = L3_2[A0_2]
  L4_2 = GetJobs
  L4_2 = L4_2()
  if L3_2 == A1_2 then
    return
  end
  if L3_2 then
    L5_2 = L0_1.jobCounts
    L6_2 = L5_2[L3_2]
    L6_2 = L6_2 - 1
    L5_2[L3_2] = L6_2
  end
  L5_2 = L4_2[A1_2]
  if L5_2 then
    L5_2 = L0_1.jobCounts
    L5_2 = L5_2[A1_2]
    if not L5_2 then
      L5_2 = L0_1.jobCounts
      L5_2[A1_2] = 0
    end
    L5_2 = L0_1.jobCounts
    L6_2 = L5_2[A1_2]
    L6_2 = L6_2 + 1
    L5_2[A1_2] = L6_2
    L5_2 = L3_1
    L5_2[A0_2] = A1_2
  else
    L5_2 = L3_1
    L5_2[A0_2] = nil
  end
  if A2_2 then
    L5_2 = L4_1
    L5_2 = L5_2[A0_2]
    if not L5_2 then
      L5_2 = L4_1
      L5_2[A0_2] = true
      L5_2 = L0_1.onDutyCount
      L5_2 = L5_2 + 1
      L0_1.onDutyCount = L5_2
    end
  else
    L5_2 = L4_1
    L5_2 = L5_2[A0_2]
    if L5_2 then
      L5_2 = L4_1
      L5_2[A0_2] = nil
      L5_2 = L0_1.onDutyCount
      L5_2 = L5_2 - 1
      L0_1.onDutyCount = L5_2
    end
  end
end
L6_1 = AddEventHandler
L7_1 = "esx:setJob"
function L8_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A1_2.name
  L3_2 = Config
  L3_2 = L3_2.UnemployedJob
  if L2_2 ~= L3_2 then
    L2_2 = Editable
    L2_2 = L2_2.getPlayerDuty
    L3_2 = A0_2
    L4_2 = A1_2
    L2_2 = L2_2(L3_2, L4_2)
    L3_2 = L5_1
    L4_2 = A0_2
    L5_2 = A1_2.name
    L6_2 = L2_2
    L3_2(L4_2, L5_2, L6_2)
  end
end
L6_1(L7_1, L8_1)
L6_1 = AddEventHandler
L7_1 = "QBCore:Server:OnJobUpdate"
function L8_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A1_2.name
  L3_2 = Config
  L3_2 = L3_2.UnemployedJob
  if L2_2 ~= L3_2 then
    L2_2 = Editable
    L2_2 = L2_2.getPlayerDuty
    L3_2 = A0_2
    L4_2 = A1_2
    L2_2 = L2_2(L3_2, L4_2)
    L3_2 = L5_1
    L4_2 = A0_2
    L5_2 = A1_2.name
    L6_2 = L2_2
    L3_2(L4_2, L5_2, L6_2)
  end
end
L6_1(L7_1, L8_1)
L6_1 = AddEventHandler
L7_1 = "esx:playerLoaded"
function L8_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = Editable
  L2_2 = L2_2.getPlayerDuty
  L3_2 = A0_2
  L4_2 = A1_2.job
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = L5_1
  L4_2 = A0_2
  L5_2 = A1_2.job
  L5_2 = L5_2.name
  L6_2 = L2_2
  L3_2(L4_2, L5_2, L6_2)
end
L6_1(L7_1, L8_1)
L6_1 = AddEventHandler
L7_1 = "QBCore:Server:PlayerLoaded"
function L8_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = Editable
  L1_2 = L1_2.getPlayerDuty
  L2_2 = A0_2.PlayerData
  L2_2 = L2_2.source
  L3_2 = A0_2.PlayerData
  L3_2 = L3_2.job
  L1_2 = L1_2(L2_2, L3_2)
  L2_2 = L5_1
  L3_2 = A0_2.PlayerData
  L3_2 = L3_2.source
  L4_2 = A0_2.PlayerData
  L4_2 = L4_2.job
  L4_2 = L4_2.name
  L5_2 = L1_2
  L2_2(L3_2, L4_2, L5_2)
end
L6_1(L7_1, L8_1)
L6_1 = lib
L6_1 = L6_1.cron
L6_1 = L6_1.new
L7_1 = "0 * * * *"
function L8_1()
  local L0_2, L1_2
  L0_2 = L0_1.onDutyCount
  L0_1.lastOnDutyCount = L0_2
end
L6_1(L7_1, L8_1)
L6_1 = CreateThread
function L7_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  while true do
    L0_2 = L1_1
    if L0_2 then
      break
    end
    L0_2 = Wait
    L1_2 = 100
    L0_2(L1_2)
  end
  L0_2 = pairs
  L1_2 = Framework
  L1_2 = L1_2.getPlayers
  L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2 = L1_2()
  L0_2, L1_2, L2_2, L3_2 = L0_2(L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
  for L4_2, L5_2 in L0_2, L1_2, L2_2, L3_2 do
    L6_2 = Editable
    L6_2 = L6_2.getPlayerDuty
    L7_2 = L5_2.source
    if not L7_2 then
      L7_2 = L5_2.PlayerData
      L7_2 = L7_2.source
    end
    L8_2 = L5_2.job
    if not L8_2 then
      L8_2 = L5_2.PlayerData
      L8_2 = L8_2.job
    end
    L6_2 = L6_2(L7_2, L8_2)
    L7_2 = Framework
    L7_2 = L7_2.name
    if "es_extended" == L7_2 then
      L7_2 = L5_1
      L8_2 = L5_2.source
      L9_2 = L5_2.job
      L9_2 = L9_2.name
      L10_2 = L6_2
      L7_2(L8_2, L9_2, L10_2)
    else
      L7_2 = L5_1
      L8_2 = L5_2.PlayerData
      L8_2 = L8_2.source
      L9_2 = L5_2.PlayerData
      L9_2 = L9_2.job
      L9_2 = L9_2.name
      L10_2 = L6_2
      L7_2(L8_2, L9_2, L10_2)
    end
  end
  L0_2 = TriggerClientEvent
  L1_2 = "lunar_unijob:updateStats"
  L2_2 = -1
  L3_2 = L0_1
  L0_2(L1_2, L2_2, L3_2)
end
L6_1(L7_1)
