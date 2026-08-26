local L0_1, L1_1, L2_1, L3_1
L0_1 = {}
Webhooks = L0_1
L0_1 = Webhooks
L1_1 = GetResourceKvpString
L2_1 = "webhook"
L1_1 = L1_1(L2_1)
L0_1.globalWebhook = L1_1
L0_1 = GetResourceKvpString
L1_1 = "webhookSettings"
L0_1 = L0_1(L1_1)
L1_1 = Webhooks
if L0_1 then
  L2_1 = json
  L2_1 = L2_1.decode
  L3_1 = L0_1
  L2_1 = L2_1(L3_1)
  if L2_1 then
    goto lbl_32
  end
end
L2_1 = {}
L2_1.alarms = false
L2_1.collecting = false
L2_1.crafting = true
L2_1.vehicleBought = true
L2_1.registers = true
L2_1.selling = true
L2_1.shops = true
L2_1.stashes = true
::lbl_32::
L1_1.settings = L2_1
L1_1 = Webhooks
L2_1 = {}
L1_1.jobs = L2_1
L1_1 = MySQL
L1_1 = L1_1.ready
function L2_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L0_2 = Wait
  L1_2 = 1000
  L0_2(L1_2)
  L0_2 = MySQL
  L0_2 = L0_2.query
  L0_2 = L0_2.await
  L1_2 = "SELECT * FROM lunar_jobscreator_webhooks"
  L0_2 = L0_2(L1_2)
  L1_2 = 1
  L2_2 = #L0_2
  L3_2 = 1
  for L4_2 = L1_2, L2_2, L3_2 do
    L5_2 = L0_2[L4_2]
    L6_2 = Webhooks
    L6_2 = L6_2.jobs
    L7_2 = L5_2.name
    L8_2 = L5_2.url
    L6_2[L7_2] = L8_2
  end
end
L1_1(L2_1)
L1_1 = lib
L1_1 = L1_1.callback
L1_1 = L1_1.register
L2_1 = "lunar_unijob:getWebhookData"
function L3_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = Framework
  L1_2 = L1_2.getPlayerFromId
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L2_2 = IsPlayerAdmin
    L3_2 = L1_2.source
    L2_2 = L2_2(L3_2)
    if L2_2 then
      goto lbl_13
    end
  end
  do return end
  ::lbl_13::
  L2_2 = Webhooks
  return L2_2
end
L1_1(L2_1, L3_1)
L1_1 = RegisterNetEvent
L2_1 = "lunar_unijob:updateWebhookData"
function L3_1(A0_2)
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
  L3_2 = Webhooks
  L4_2 = A0_2.globalWebhook
  L3_2.globalWebhook = L4_2
  L3_2 = Webhooks
  L4_2 = A0_2.settings
  L3_2.settings = L4_2
  L3_2 = A0_2.globalWebhook
  if L3_2 then
    L3_2 = SetResourceKvp
    L4_2 = "webhook"
    L5_2 = A0_2.globalWebhook
    L3_2(L4_2, L5_2)
  end
  L3_2 = A0_2.settings
  if L3_2 then
    L3_2 = SetResourceKvp
    L4_2 = "webhookSettings"
    L5_2 = json
    L5_2 = L5_2.encode
    L6_2 = A0_2.settings
    L5_2, L6_2 = L5_2(L6_2)
    L3_2(L4_2, L5_2, L6_2)
  end
end
L1_1(L2_1, L3_1)
L1_1 = RegisterNetEvent
L2_1 = "lunar_unijob:updateJobWebhook"
function L3_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = source
  L3_2 = Framework
  L3_2 = L3_2.getPlayerFromId
  L4_2 = L2_2
  L3_2 = L3_2(L4_2)
  if L3_2 then
    L4_2 = IsPlayerAdmin
    L5_2 = L3_2.source
    L4_2 = L4_2(L5_2)
    if L4_2 then
      L5_2 = A1_2
      L4_2 = A1_2.len
      L4_2 = L4_2(L5_2)
      if 0 ~= L4_2 then
        goto lbl_18
      end
    end
  end
  do return end
  ::lbl_18::
  L4_2 = Webhooks
  L4_2 = L4_2.jobs
  L4_2[A0_2] = A1_2
  L4_2 = MySQL
  L4_2 = L4_2.update
  L4_2 = L4_2.await
  L5_2 = "INSERT INTO lunar_jobscreator_webhooks (name, url) VALUES(?, ?) ON DUPLICATE KEY UPDATE url = VALUES(url)"
  L6_2 = {}
  L7_2 = A0_2
  L8_2 = A1_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L4_2(L5_2, L6_2)
end
L1_1(L2_1, L3_1)
