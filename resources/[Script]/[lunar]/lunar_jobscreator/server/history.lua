local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1
L0_1 = {}
L1_1 = false
function L2_1()
  local L0_2, L1_2
  L0_2 = os
  L0_2 = L0_2.time
  return L0_2()
end
L3_1 = MySQL
L3_1 = L3_1.ready
function L4_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2
  L0_2 = Wait
  L1_2 = 1000
  L0_2(L1_2)
  L0_2 = L2_1
  L0_2 = L0_2()
  L1_2 = L0_2 - 172800
  L2_2 = MySQL
  L2_2 = L2_2.query
  L2_2 = L2_2.await
  L3_2 = "SELECT * FROM lunar_jobscreator_history WHERE timestamp >= ?"
  L4_2 = {}
  L5_2 = L1_2
  L4_2[1] = L5_2
  L2_2 = L2_2(L3_2, L4_2)
  L0_1 = L2_2
  L2_2 = MySQL
  L2_2 = L2_2.query
  L2_2 = L2_2.await
  L3_2 = "DELETE FROM lunar_jobscreator_history WHERE timestamp < ?"
  L4_2 = {}
  L5_2 = L1_2
  L4_2[1] = L5_2
  L2_2(L3_2, L4_2)
  L2_2 = true
  L1_1 = L2_2
end
L3_1(L4_1)
L3_1 = {}
L4_1 = lib
L4_1 = L4_1.callback
L4_1 = L4_1.register
L5_1 = "lunar_unijob:getHistory"
function L6_1(A0_2)
  local L1_2, L2_2
  L1_2 = L3_1
  L1_2 = L1_2[A0_2]
  if L1_2 then
    return
  end
  L1_2 = L3_1
  L1_2[A0_2] = true
  while true do
    L1_2 = L1_1
    if L1_2 then
      break
    end
    L1_2 = Wait
    L2_2 = 0
    L1_2(L2_2)
  end
  L1_2 = L0_1
  return L1_2
end
L4_1(L5_1, L6_1)
function L4_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = {}
  L3_2 = GetPlayerName
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  L2_2.username = L3_2
  L2_2.action = A1_2
  L3_2 = L2_1
  L3_2 = L3_2()
  L2_2.timestamp = L3_2
  L3_2 = L0_1
  L3_2 = #L3_2
  L4_2 = L3_2 + 1
  L3_2 = L0_1
  L3_2[L4_2] = L2_2
  L3_2 = MySQL
  L3_2 = L3_2.insert
  L3_2 = L3_2.await
  L4_2 = "INSERT INTO lunar_jobscreator_history (username, action, timestamp) VALUES (?, ?, ?)"
  L5_2 = {}
  L6_2 = L2_2.username
  L7_2 = L2_2.action
  L8_2 = L2_2.timestamp
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L3_2(L4_2, L5_2)
  L3_2 = TriggerClientEvent
  L4_2 = "lunar_unijob:updateHistory"
  L5_2 = -1
  L6_2 = L0_1
  L3_2(L4_2, L5_2, L6_2)
end
AddHistoryLog = L4_1
