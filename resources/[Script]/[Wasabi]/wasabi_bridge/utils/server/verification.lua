local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1
L0_1 = Config
L0_1 = L0_1.CheckForUpdates
if not L0_1 then
  return
end
L0_1 = "wasabi_bridge"
L1_1 = "wasabi_bridge"
L2_1 = GetResourceMetadata
L3_1 = GetCurrentResourceName
L3_1 = L3_1()
L4_1 = "version"
L2_1 = L2_1(L3_1, L4_1)
L3_1 = "https://raw.githubusercontent.com/Wasabi-Scripts/wasabi_versions/main/versions.json"
function L4_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = PerformHttpRequest
  L2_2 = L3_1
  function L3_2(A0_3, A1_3, A2_3)
    local L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3
    if 200 == A0_3 and A1_3 then
      L3_3 = json
      L3_3 = L3_3.decode
      L4_3 = A1_3
      L3_3 = L3_3(L4_3)
      L4_3 = type
      L5_3 = L3_3
      L4_3 = L4_3(L5_3)
      if "table" == L4_3 then
        L4_3 = ipairs
        L5_3 = L3_3
        L4_3, L5_3, L6_3, L7_3 = L4_3(L5_3)
        for L8_3, L9_3 in L4_3, L5_3, L6_3, L7_3 do
          L10_3 = L9_3.script
          if L10_3 then
            L10_3 = L9_3.script
            L11_3 = L0_1
            if L10_3 == L11_3 then
              L10_3 = A0_2
              L11_3 = L9_3.version
              L10_3(L11_3)
              return
            end
          end
        end
      end
    end
    L3_3 = A0_2
    L4_3 = false
    L3_3(L4_3)
  end
  L4_2 = "GET"
  L1_2(L2_2, L3_2, L4_2)
end
function L5_1(A0_2)
  local L1_2, L2_2
  L1_2 = CreateThread
  function L2_2()
    local L0_3, L1_3, L2_3, L3_3
    L0_3 = A0_2
    if L0_3 then
      L0_3 = L2_1
      L1_3 = A0_2
      if L0_3 ~= L1_3 then
        L0_3 = Wait
        L1_3 = 4500
        L0_3(L1_3)
        L0_3 = print
        L1_3 = "^0[^3WARNING^0] "
        L2_3 = L1_1
        L3_3 = " is ^1NOT ^0up to date!"
        L1_3 = L1_3 .. L2_3 .. L3_3
        L0_3(L1_3)
        L0_3 = print
        L1_3 = "^0[^3WARNING^0] Your Version: ^1"
        L2_3 = tostring
        L3_3 = L2_1
        L2_3 = L2_3(L3_3)
        L3_3 = "^0"
        L1_3 = L1_3 .. L2_3 .. L3_3
        L0_3(L1_3)
        L0_3 = print
        L1_3 = "^0[^3WARNING^0] Latest Version: ^2"
        L2_3 = tostring
        L3_3 = A0_2
        L2_3 = L2_3(L3_3)
        L3_3 = "^0"
        L1_3 = L1_3 .. L2_3 .. L3_3
        L0_3(L1_3)
        L0_3 = print
        L1_3 = "^0[^3WARNING^0] ^1Get the latest version from portal.cfx.re!^0"
        L0_3(L1_3)
      end
    end
  end
  L1_2(L2_2)
end
L6_1 = CreateThread
function L7_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = GetCurrentResourceName
  L0_2 = L0_2()
  L1_2 = L1_1
  if L0_2 ~= L1_2 then
    L0_2 = L1_1
    L1_2 = "("
    L2_2 = GetCurrentResourceName
    L2_2 = L2_2()
    L3_2 = ")"
    L0_2 = L0_2 .. L1_2 .. L2_2 .. L3_2
    L1_1 = L0_2
    L0_2 = Wait
    L1_2 = 4500
    L0_2(L1_2)
    L0_2 = print
    L1_2 = "^0[^3WARNING^0] Rename the folder to \""
    L2_2 = L0_1
    L3_2 = "\", otherwise this resource could experience problems!"
    L1_2 = L1_2 .. L2_2 .. L3_2
    L0_2(L1_2)
  end
  while true do
    L0_2 = L4_1
    L1_2 = L5_1
    L0_2(L1_2)
    L0_2 = Wait
    L1_2 = 3600000
    L0_2(L1_2)
  end
end
L6_1(L7_1)
