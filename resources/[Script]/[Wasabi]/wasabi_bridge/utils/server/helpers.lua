local L0_1, L1_1, L2_1
L0_1 = exports
L1_1 = "GetBridgeObject"
function L2_1()
  local L0_2, L1_2
  L0_2 = WSB
  return L0_2
end
L0_1(L1_1, L2_1)
L0_1 = WSB
function L1_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2
  L0_2 = GetResourceMetadata
  L1_2 = GetCurrentResourceName
  L1_2 = L1_2()
  L2_2 = "version"
  L3_2 = 0
  L0_2 = L0_2(L1_2, L2_2, L3_2)
  L2_2 = L0_2
  L1_2 = L0_2.gsub
  L3_2 = "%."
  L4_2 = ""
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  L0_2 = L1_2
  return L0_2
end
L0_1.getVersion = L1_1
L0_1 = WSB
function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  if A0_2 then
    L1_2 = string
    L1_2 = L1_2.gsub
    L2_2 = A0_2
    L3_2 = "^%s*(.-)%s*$"
    L4_2 = "%1"
    L1_2 = L1_2(L2_2, L3_2, L4_2)
    return L1_2
  else
    L1_2 = nil
    return L1_2
  end
end
L0_1.trim = L1_1
function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  if not A1_2 then
    L2_2 = WSB
    A1_2 = L2_2.inventorySystem
  end
  if "codem-inventory" == A1_2 then
    L2_2 = {}
    L3_2 = ipairs
    L4_2 = A0_2.inventory
    L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
    for L7_2, L8_2 in L3_2, L4_2, L5_2, L6_2 do
      L9_2 = #L2_2
      L9_2 = L9_2 + 1
      L10_2 = {}
      L11_2 = L8_2.name
      L10_2.name = L11_2
      L11_2 = L8_2.price
      L10_2.price = L11_2
      L2_2[L9_2] = L10_2
    end
    return L2_2
  end
  L2_2 = 0
  L3_2 = {}
  L4_2 = A0_2.name
  L3_2.label = L4_2
  L4_2 = {}
  L3_2.items = L4_2
  L4_2 = ipairs
  L5_2 = A0_2.inventory
  L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
  for L8_2, L9_2 in L4_2, L5_2, L6_2, L7_2 do
    L10_2 = L3_2.items
    L11_2 = L3_2.items
    L11_2 = #L11_2
    L11_2 = L11_2 + 1
    L12_2 = {}
    L13_2 = L9_2.name
    L12_2.name = L13_2
    L13_2 = L9_2.price
    L12_2.price = L13_2
    L13_2 = L2_2 + 1
    L12_2.slot = L13_2
    L12_2.amount = 500
    L13_2 = {}
    L12_2.info = L13_2
    L10_2[L11_2] = L12_2
    L2_2 = L2_2 + 1
  end
  return L3_2
end
ConvertShopData = L0_1
L0_1 = RegisterNetEvent
L1_1 = "wasabi_bridge:debugPrint"
L2_1 = print
L0_1(L1_1, L2_1)
