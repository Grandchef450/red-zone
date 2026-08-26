local L0_1, L1_1
L0_1 = {}
Logs = L0_1
L0_1 = Logs
function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L3_2 = Webhooks
  L3_2 = L3_2.jobs
  L3_2 = L3_2[A1_2]
  if L3_2 and "" ~= L3_2 then
    L4_2 = Utils
    L4_2 = L4_2.logToDiscord
    L5_2 = A0_2
    L6_2 = L3_2
    L7_2 = A2_2
    L4_2(L5_2, L6_2, L7_2)
  end
  L4_2 = Webhooks
  L4_2 = L4_2.globalWebhook
  if L4_2 and "" ~= L4_2 then
    L5_2 = Utils
    L5_2 = L5_2.logToDiscord
    L6_2 = A0_2
    L7_2 = L4_2
    L8_2 = A2_2
    L5_2(L6_2, L7_2, L8_2)
  end
end
L0_1.send = L1_1
