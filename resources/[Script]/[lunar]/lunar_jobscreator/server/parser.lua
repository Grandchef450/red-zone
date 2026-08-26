local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1
L0_1 = {}
Parser = L0_1
function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2
  if not A0_2 then
    return A2_2
  end
  L3_2 = type
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  L4_2 = L3_2 == A1_2
  return L4_2
end
function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = L0_1
  L2_2 = A0_2.name
  L3_2 = "string"
  L4_2 = false
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  if not L1_2 then
    L1_2 = false
    L2_2 = "the name field needs to be a valid string."
    return L1_2, L2_2
  end
  L1_2 = L0_1
  L2_2 = A0_2.label
  L3_2 = "string"
  L4_2 = false
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  if not L1_2 then
    L1_2 = false
    L2_2 = "the label field needs to be a valid string."
    return L1_2, L2_2
  end
  L1_2 = L0_1
  L2_2 = A0_2.grades
  L3_2 = "array"
  L4_2 = false
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  if not L1_2 then
    L1_2 = false
    L2_2 = "provide valid grades in an array."
    return L1_2, L2_2
  end
  L1_2 = L0_1
  L2_2 = A0_2.blips
  L3_2 = "array"
  L4_2 = true
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  if not L1_2 then
    L1_2 = false
    L2_2 = "provide valid blips data in an array."
    return L1_2, L2_2
  end
  L1_2 = L0_1
  L2_2 = A0_2.cloakrooms
  L3_2 = "table"
  L4_2 = true
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  if not L1_2 then
    L1_2 = false
    L2_2 = "provide valid cloakrooms table."
    return L1_2, L2_2
  end
  L1_2 = L0_1
  L2_2 = A0_2.collecting
  L3_2 = "array"
  L4_2 = true
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  if not L1_2 then
    L1_2 = false
    L2_2 = "provide valid collecting data in an array."
    return L1_2, L2_2
  end
  L1_2 = L0_1
  L2_2 = A0_2.crafting
  L3_2 = "array"
  L4_2 = true
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  if not L1_2 then
    L1_2 = false
    L2_2 = "provide valid crafting data in an array."
    return L1_2, L2_2
  end
  L1_2 = L0_1
  L2_2 = A0_2.garages
  L3_2 = "array"
  L4_2 = true
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  if not L1_2 then
    L1_2 = false
    L2_2 = "provide valid garage data in an array."
    return L1_2, L2_2
  end
  L1_2 = L0_1
  L2_2 = A0_2.selling
  L3_2 = "array"
  L4_2 = true
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  if not L1_2 then
    L1_2 = false
    L2_2 = "provide valid selling data in an array."
    return L1_2, L2_2
  end
  L1_2 = L0_1
  L2_2 = A0_2.shops
  L3_2 = "array"
  L4_2 = true
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  if not L1_2 then
    L1_2 = false
    L2_2 = "provide valid shops in an array."
    return L1_2, L2_2
  end
  L1_2 = L0_1
  L2_2 = A0_2.stashes
  L3_2 = "array"
  L4_2 = true
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  if not L1_2 then
    L1_2 = false
    L2_2 = "provide valid stashes in an array."
    return L1_2, L2_2
  end
  L1_2 = true
  return L1_2
end
function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L1_2 = nil
  L3_2 = A0_2
  L2_2 = A0_2.gmatch
  L4_2 = [[
[^
]+]]
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2, L4_2)
  for L6_2 in L2_2, L3_2, L4_2, L5_2 do
    L8_2 = L6_2
    L7_2 = L6_2.find
    L9_2 = "---@if_resource"
    L7_2 = L7_2(L8_2, L9_2)
    if not L7_2 then
      L8_2 = L6_2
      L7_2 = L6_2.find
      L9_2 = "---@if_not_resource"
      L7_2 = L7_2(L8_2, L9_2)
    end
    if L7_2 then
      if not L1_2 then
        L9_2 = L6_2
        L8_2 = L6_2.match
        L10_2 = "%((.-)%)"
        L8_2 = L8_2(L9_2, L10_2)
        if L8_2 then
          goto lbl_30
        end
      end
      L8_2 = print
      L9_2 = "Invalid: "
      L10_2 = L6_2
      L9_2 = L9_2 .. L10_2
      L8_2(L9_2)
      L8_2 = false
      do return L8_2 end
      ::lbl_30::
      L1_2 = "if_resource"
    else
      L9_2 = L6_2
      L8_2 = L6_2.find
      L10_2 = "---@elseif_resource"
      L8_2 = L8_2(L9_2, L10_2)
      if not L8_2 then
        L9_2 = L6_2
        L8_2 = L6_2.find
        L10_2 = "---@elseif_not_resource"
        L8_2 = L8_2(L9_2, L10_2)
      end
      if L8_2 then
        if "if_resource" == L1_2 or "elseif_resource" == L1_2 then
          L10_2 = L6_2
          L9_2 = L6_2.match
          L11_2 = "%((.-)%)"
          L9_2 = L9_2(L10_2, L11_2)
          if L9_2 then
            goto lbl_53
          end
        end
        L9_2 = false
        do return L9_2 end
        ::lbl_53::
        L1_2 = "elseif_resource"
      else
        L10_2 = L6_2
        L9_2 = L6_2.find
        L11_2 = "---@else"
        L9_2 = L9_2(L10_2, L11_2)
        if L9_2 then
          if "if_resource" == L1_2 or "elseif_resource" == L1_2 then
            L11_2 = L6_2
            L10_2 = L6_2.match
            L12_2 = "%((.-)%)"
            L10_2 = L10_2(L11_2, L12_2)
            if not L10_2 then
              goto lbl_71
            end
          end
          L10_2 = false
          do return L10_2 end
          ::lbl_71::
          L1_2 = "else"
        else
          L11_2 = L6_2
          L10_2 = L6_2.find
          L12_2 = "---@end"
          L10_2 = L10_2(L11_2, L12_2)
          if L10_2 then
            if L1_2 then
              L12_2 = L6_2
              L11_2 = L6_2.match
              L13_2 = "%((.-)%)"
              L11_2 = L11_2(L12_2, L13_2)
              if not L11_2 then
                goto lbl_87
              end
            end
            L11_2 = false
            do return L11_2 end
            ::lbl_87::
            L1_2 = false
          end
        end
      end
    end
  end
  if L1_2 then
    L2_2 = false
    return L2_2
  end
  L2_2 = true
  return L2_2
end
function L3_1(A0_2)
  local L1_2, L2_2
  L1_2 = GetResourceState
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  L1_2 = "started" == L1_2
  return L1_2
end
function L4_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L1_2 = L2_1
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    return
  end
  L1_2 = ""
  L2_2 = "reading"
  L4_2 = A0_2
  L3_2 = A0_2.gmatch
  L5_2 = [[
[^
]+]]
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2, L5_2)
  for L7_2 in L3_2, L4_2, L5_2, L6_2 do
    L9_2 = L7_2
    L8_2 = L7_2.find
    L10_2 = "---@if_resource"
    L8_2 = L8_2(L9_2, L10_2)
    if L8_2 and "reading" == L2_2 then
      L10_2 = L7_2
      L9_2 = L7_2.match
      L11_2 = "%((.-)%)"
      L9_2 = L9_2(L10_2, L11_2)
      L10_2 = L3_1
      L11_2 = L9_2
      L10_2 = L10_2(L11_2)
      if not L10_2 then
        L2_2 = "skipping"
      else
        L2_2 = "reading_to_end"
      end
    else
      L10_2 = L7_2
      L9_2 = L7_2.find
      L11_2 = "---@if_not_resource"
      L9_2 = L9_2(L10_2, L11_2)
      if L9_2 and "reading" == L2_2 then
        L11_2 = L7_2
        L10_2 = L7_2.match
        L12_2 = "%((.-)%)"
        L10_2 = L10_2(L11_2, L12_2)
        L11_2 = L3_1
        L12_2 = L10_2
        L11_2 = L11_2(L12_2)
        if L11_2 then
          L2_2 = "skipping"
        else
          L2_2 = "reading_to_end"
        end
      else
        L11_2 = L7_2
        L10_2 = L7_2.find
        L12_2 = "---@elseif_resource"
        L10_2 = L10_2(L11_2, L12_2)
        if L10_2 then
          if "skipping" == L2_2 then
            L12_2 = L7_2
            L11_2 = L7_2.match
            L13_2 = "%((.-)%)"
            L11_2 = L11_2(L12_2, L13_2)
            L12_2 = L3_1
            L13_2 = L11_2
            L12_2 = L12_2(L13_2)
            if L12_2 then
              L2_2 = "reading_to_end"
            end
          elseif "reading_to_end" == L2_2 then
            L2_2 = "skipping_to_end"
          end
        else
          L12_2 = L7_2
          L11_2 = L7_2.find
          L13_2 = "---@elseif_not_resource"
          L11_2 = L11_2(L12_2, L13_2)
          if L11_2 then
            if "skipping" == L2_2 then
              L13_2 = L7_2
              L12_2 = L7_2.match
              L14_2 = "%((.-)%)"
              L12_2 = L12_2(L13_2, L14_2)
              L13_2 = L3_1
              L14_2 = L12_2
              L13_2 = L13_2(L14_2)
              if not L13_2 then
                L2_2 = "reading_to_end"
              end
            elseif "reading_to_end" == L2_2 then
              L2_2 = "skipping_to_end"
            end
          else
            L13_2 = L7_2
            L12_2 = L7_2.find
            L14_2 = "---@else"
            L12_2 = L12_2(L13_2, L14_2)
            if L12_2 then
              if "skipping" == L2_2 then
                L2_2 = "reading_to_end"
              else
                L2_2 = "skipping"
              end
            else
              L14_2 = L7_2
              L13_2 = L7_2.find
              L15_2 = "---@end"
              L13_2 = L13_2(L14_2, L15_2)
              if L13_2 then
                if "skipping" == L2_2 or "reading_to_end" == L2_2 or "skipping_to_end" == L2_2 then
                  L2_2 = "reading"
                end
              elseif "reading" == L2_2 or "reading_to_end" == L2_2 then
                L14_2 = L1_2
                L15_2 = "\n"
                L16_2 = L7_2
                L14_2 = L14_2 .. L15_2 .. L16_2
                L1_2 = L14_2
              end
            end
          end
        end
      end
    end
  end
  return L1_2
end
L5_1 = Parser
function L6_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = L4_1
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  L2_2 = load
  L3_2 = L1_2 or L3_2
  if not L1_2 then
    L3_2 = A0_2
  end
  L2_2, L3_2 = L2_2(L3_2)
  if not L2_2 then
    L4_2 = false
    L5_2 = "Couldn't load %s due to a syntax error: "
    L6_2 = L3_2
    L5_2 = L5_2 .. L6_2
    return L4_2, L5_2
  end
  L4_2 = L2_2
  L4_2 = L4_2()
  if not L4_2 then
    L5_2 = false
    L6_2 = "Couldn't load %s due to no return statement."
    return L5_2, L6_2
  end
  L5_2 = L1_1
  L6_2 = L4_2
  L5_2, L6_2 = L5_2(L6_2)
  if L5_2 then
    if not L1_2 then
      L7_2 = warn
      L8_2 = "Ignoring annotations in job %s."
      L9_2 = L8_2
      L8_2 = L8_2.format
      L10_2 = L4_2.name
      L8_2, L9_2, L10_2 = L8_2(L9_2, L10_2)
      L7_2(L8_2, L9_2, L10_2)
    end
    L7_2 = true
    L8_2 = L4_2
    return L7_2, L8_2
  else
    L7_2 = false
    L8_2 = "Couldn't load %s due to invalid data: "
    L9_2 = L6_2
    L8_2 = L8_2 .. L9_2
    return L7_2, L8_2
  end
end
L5_1.parse = L6_1
