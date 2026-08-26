local L0_1, L1_1, L2_1, L3_1, L4_1
L0_1 = {}
L1_1 = AddEventHandler
L2_1 = "onResourceStop"
function L3_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = GetInvokingResource
  L1_2 = L1_2()
  if L1_2 == A0_2 then
    return
  end
  L1_2 = pairs
  L2_2 = L0_1
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
    if L6_2 == A0_2 then
      L7_2 = L0_1
      L7_2[L5_2] = nil
    end
  end
end
L1_1(L2_1, L3_1)
function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L2_2 = GetInvokingResource
  L2_2 = L2_2()
  if not L2_2 then
    L2_2 = "wasabi_bridge"
  end
  L3_2 = L0_1
  L3_2 = L3_2[A0_2]
  if L3_2 then
    if not A1_2 then
      L3_2[A0_2] = nil
      return
    end
    if L3_2 == L2_2 then
      return
    end
    L4_2 = "^1resource '%s' attempted to overwrite callback '%s' owned by resource '%s'^0"
    L5_2 = L4_2
    L4_2 = L4_2.format
    L6_2 = L2_2
    L7_2 = A0_2
    L8_2 = L3_2
    L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
    L5_2 = print
    L6_2 = [[
^1SCRIPT ERROR: %s^0
%s]]
    L7_2 = L6_2
    L6_2 = L6_2.format
    L8_2 = L4_2
    L9_2 = Citizen
    L9_2 = L9_2.InvokeNative
    L10_2 = 3607903178
    L11_2 = nil
    L12_2 = 0
    L13_2 = Citizen
    L13_2 = L13_2.ResultAsString
    L13_2 = L13_2()
    L9_2 = L9_2(L10_2, L11_2, L12_2, L13_2)
    if not L9_2 then
      L9_2 = ""
    end
    L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2 = L6_2(L7_2, L8_2, L9_2)
    return L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  end
  L4_2 = L0_1
  L4_2[A0_2] = L2_2
end
SetValidCallback = L1_1
function L1_1(A0_2)
  local L1_2
  L1_2 = L0_1
  L1_2 = L1_2[A0_2]
  L1_2 = "wasabi_bridge" == L1_2
  return L1_2
end
IsCallbackValid = L1_1
L1_1 = "__wsb_cb_%s"
L2_1 = RegisterNetEvent
L3_1 = "wasabi_bridge:validateCallback"
function L4_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L3_2 = L0_1
  L3_2 = L3_2[A0_2]
  if L3_2 then
    return
  end
  L3_2 = L1_1
  L4_2 = L3_2
  L3_2 = L3_2.format
  L5_2 = A1_2
  L3_2 = L3_2(L4_2, L5_2)
  L4_2 = GetGameName
  L4_2 = L4_2()
  if "fxserver" == L4_2 then
    L4_2 = TriggerClientEvent
    L5_2 = L3_2
    L6_2 = source
    L7_2 = A2_2
    L8_2 = "cb_invalid"
    return L4_2(L5_2, L6_2, L7_2, L8_2)
  end
  L4_2 = TriggerServerEvent
  L5_2 = L3_2
  L6_2 = A2_2
  L7_2 = "cb_invalid"
  L4_2(L5_2, L6_2, L7_2)
end
L2_1(L3_1, L4_1)
