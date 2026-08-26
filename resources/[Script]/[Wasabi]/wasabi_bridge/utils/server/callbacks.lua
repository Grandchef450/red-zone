local L0_1, L1_1, L2_1
L0_1 = WSB
L0_1 = L0_1.registerCallback
L1_1 = "wasabi_bridge:getVersion"
function L2_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = A1_2
  L3_2 = WSB
  L3_2 = L3_2.getVersion
  L3_2 = L3_2()
  L2_2(L3_2)
end
L0_1(L1_1, L2_1)
L0_1 = WSB
L0_1 = L0_1.registerCallback
L1_1 = "wasabi_bridge:getIdentifier"
function L2_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2
  if not A2_2 then
    A2_2 = A0_2
  end
  L3_2 = A1_2
  L4_2 = WSB
  L4_2 = L4_2.getIdentifier
  L5_2 = A2_2
  L4_2, L5_2 = L4_2(L5_2)
  L3_2(L4_2, L5_2)
end
L0_1(L1_1, L2_1)
L0_1 = WSB
L0_1 = L0_1.registerCallback
L1_1 = "wasabi_bridge:isPlayerBoss"
function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = A1_2
  L3_2 = WSB
  L3_2 = L3_2.isPlayerBoss
  L4_2 = A0_2
  L3_2, L4_2 = L3_2(L4_2)
  L2_2(L3_2, L4_2)
end
L0_1(L1_1, L2_1)
