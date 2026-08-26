local L0_1, L1_1
function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = WSB
  L2_2 = L2_2.getPlayer
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    L3_2 = false
    return L3_2
  end
  L3_2 = nil
  L4_2 = L2_2.Functions
  if L4_2 then
    L4_2 = L2_2.Functions
    L4_2 = L4_2.GetItemByName
    if L4_2 then
      L4_2 = L2_2.Functions
      L4_2 = L4_2.GetItemByName
      L5_2 = A1_2
      L4_2 = L4_2(L5_2)
      L3_2 = L4_2
  end
  else
    L4_2 = L2_2.getInventoryItem
    if L4_2 then
      L4_2 = L2_2.getInventoryItem
      L5_2 = A1_2
      L4_2 = L4_2(L5_2)
      L3_2 = L4_2
    end
  end
  if L3_2 then
    L4_2 = L3_2.slot
    if L4_2 then
      goto lbl_36
    end
  end
  L4_2 = false
  ::lbl_36::
  return L4_2
end
GetItemSlot = L0_1
function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = {}
  if not A0_2 then
    return L2_2
  end
  L3_2 = pairs
  L4_2 = A0_2
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  for L7_2, L8_2 in L3_2, L4_2, L5_2, L6_2 do
    L9_2 = L8_2.name
    L10_2 = L9_2
    L9_2 = L9_2.lower
    L9_2 = L9_2(L10_2)
    L11_2 = A1_2
    L10_2 = A1_2.lower
    L10_2 = L10_2(L11_2)
    if L9_2 == L10_2 then
      L9_2 = #L2_2
      L9_2 = L9_2 + 1
      L10_2 = tonumber
      L11_2 = L8_2.slot
      L10_2 = L10_2(L11_2)
      if not L10_2 then
        L10_2 = tonumber
        L11_2 = L7_2
        L10_2 = L10_2(L11_2)
      end
      L2_2[L9_2] = L10_2
    end
  end
  return L2_2
end
GetSlotsByItem = L0_1
