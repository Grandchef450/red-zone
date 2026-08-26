local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1, L11_1, L12_1
function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = LoadResourceFile
  L2_2 = GetCurrentResourceName
  L2_2 = L2_2()
  L3_2 = A0_2
  L1_2 = L1_2(L2_2, L3_2)
  if not L1_2 then
    L2_2 = error
    L3_2 = string
    L3_2 = L3_2.format
    L4_2 = "Failed to load module: %s"
    L5_2 = A0_2
    L3_2 = L3_2(L4_2, L5_2)
    L4_2 = 2
    L2_2(L3_2, L4_2)
  end
  L2_2 = load
  L3_2 = L1_2
  L4_2 = string
  L4_2 = L4_2.format
  L5_2 = "@%s"
  L6_2 = A0_2
  L4_2 = L4_2(L5_2, L6_2)
  L5_2 = "t"
  L2_2, L3_2 = L2_2(L3_2, L4_2, L5_2)
  if not L2_2 then
    L4_2 = error
    L5_2 = string
    L5_2 = L5_2.format
    L6_2 = "Failed to load module: %s - %s"
    L7_2 = A0_2
    L8_2 = L3_2
    L5_2 = L5_2(L6_2, L7_2, L8_2)
    L6_2 = 2
    L4_2(L5_2, L6_2)
  end
  L4_2 = L2_2
  L4_2 = L4_2()
  return L4_2
end
L1_1 = L0_1
L2_1 = "server/errortracker/modules/framework_check.lua"
L1_1 = L1_1(L2_1)
L2_1 = L0_1
L3_1 = "server/errortracker/modules/config_multichar.lua"
L2_1 = L2_1(L3_1)
L3_1 = L0_1
L4_1 = "server/errortracker/modules/user_prefix.lua"
L3_1 = L3_1(L4_1)
L4_1 = L0_1
L5_1 = "server/errortracker/modules/multicharacters_running.lua"
L4_1 = L4_1(L5_1)
L5_1 = L0_1
L6_1 = "server/errortracker/modules/uiv2_integration.lua"
L5_1 = L5_1(L6_1)
L6_1 = L0_1
L7_1 = "server/errortracker/modules/compatible_appearances.lua"
L6_1 = L6_1(L7_1)
L7_1 = L0_1
L8_1 = "server/errortracker/data/solution_list.lua"
L7_1 = L7_1(L8_1)
L8_1 = {}
L8_1.framework = false
L8_1.other_multichar_running = false
function L9_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L0_2 = {}
  L1_2 = "framework"
  L2_2 = "uiv2_integrated"
  L3_2 = "appearance_integrated"
  L4_2 = "other_multichar_running"
  L5_2 = "is_config_multichar_enabled"
  L6_2 = "user_prefix_proper"
  L0_2[1] = L1_2
  L0_2[2] = L2_2
  L0_2[3] = L3_2
  L0_2[4] = L4_2
  L0_2[5] = L5_2
  L0_2[6] = L6_2
  L1_2 = {}
  L1_2.framework = "Framework Detected"
  L1_2.is_config_multichar_enabled = "Config.Multichar properly set"
  L1_2.other_multichar_running = "Other Multicharacters not detected"
  L1_2.user_prefix_proper = "Identifier prefix correct"
  L1_2.uiv2_integrated = "UIV2 Integrated"
  L1_2.appearance_integrated = "Appearance Integrated"
  L2_2 = {}
  L3_2 = {}
  L4_2 = pairs
  L5_2 = L0_2
  L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
  for L8_2, L9_2 in L4_2, L5_2, L6_2, L7_2 do
    L10_2 = L8_1
    L10_2 = L10_2[L9_2]
    if false == L10_2 then
      L10_2 = table
      L10_2 = L10_2.insert
      L11_2 = L3_2
      L12_2 = L7_1
      L12_2 = L12_2[L9_2]
      L10_2(L11_2, L12_2)
    end
    L10_2 = L8_1
    L10_2 = L10_2[L9_2]
    if nil ~= L10_2 then
      L10_2 = L1_2[L9_2]
      L11_2 = L10_2
      L10_2 = L10_2.len
      L10_2 = L10_2(L11_2)
      L11_2 = 40
      L10_2 = L11_2 - L10_2
      L11_2 = ""
      L12_2 = 1
      L13_2 = L10_2
      L14_2 = 1
      for L15_2 = L12_2, L13_2, L14_2 do
        L16_2 = L11_2
        L17_2 = " "
        L16_2 = L16_2 .. L17_2
        L11_2 = L16_2
      end
      L12_2 = print
      L13_2 = "  -  "
      L14_2 = L1_2[L9_2]
      L15_2 = ""
      L16_2 = L11_2
      L17_2 = ""
      L18_2 = L8_1
      L18_2 = L18_2[L9_2]
      if L18_2 then
        L18_2 = "[^2STATUS OK^7]"
        if L18_2 then
          goto lbl_70
        end
      end
      L18_2 = "[^1STATUS ERROR^7]"
      ::lbl_70::
      L13_2 = L13_2 .. L14_2 .. L15_2 .. L16_2 .. L17_2 .. L18_2
      L12_2(L13_2)
      if "appearance_integrated" == L9_2 then
        L12_2 = print
        L13_2 = "    [-] Selected: [^2"
        L14_2 = L8_1.appearance_integrated
        L15_2 = "^7]"
        L13_2 = L13_2 .. L14_2 .. L15_2
        L12_2(L13_2)
      end
      if "framework" == L9_2 then
        L12_2 = print
        L13_2 = "    [-] Selected: [^2"
        L14_2 = FrameworkSelected
        L15_2 = "^7]"
        L13_2 = L13_2 .. L14_2 .. L15_2
        L12_2(L13_2)
      end
      if "other_multichar_running" == L9_2 then
        L12_2 = L8_1.other_multichar_running
        if not L12_2 then
          L12_2 = print
          L13_2 = "    [-] Detected: [^2"
          L14_2 = L4_1
          L14_2 = L14_2()
          L14_2 = L14_2.name
          L15_2 = "^7]"
          L13_2 = L13_2 .. L14_2 .. L15_2
          L12_2(L13_2)
        end
      end
      L12_2 = Wait
      L13_2 = math
      L13_2 = L13_2.random
      L14_2 = 250
      L15_2 = 650
      L13_2, L14_2, L15_2, L16_2, L17_2, L18_2 = L13_2(L14_2, L15_2)
      L12_2(L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
    end
  end
  L4_2 = print
  L5_2 = "\n"
  L4_2(L5_2)
  L4_2 = print
  L5_2 = "[^1ERROR_DATA^7] Errors found [^"
  L6_2 = #L3_2
  if L6_2 > 0 then
    L6_2 = "1"
    L7_2 = #L3_2
    L6_2 = L6_2 .. L7_2
    if L6_2 then
      goto lbl_127
    end
  end
  L6_2 = "2"
  L7_2 = "0"
  L6_2 = L6_2 .. L7_2
  ::lbl_127::
  L7_2 = "^7]"
  L5_2 = L5_2 .. L6_2 .. L7_2
  L4_2(L5_2)
  L4_2 = #L3_2
  if L4_2 > 0 then
    L4_2 = print
    L5_2 = [[
[^6-^7] Some errors has been found. To show possible solutions to your issues use a command 
    ^2multicharacter_solutions^7 below [^1NOT YET AVAILABLE^7].]]
    L4_2(L5_2)
  else
    L4_2 = print
    L5_2 = [[

[^6-^7] No known errors has been found. If you encounter any issues visit ^5https://discord.gg/zsx^7 
    for more information]]
    L4_2(L5_2)
  end
  L4_2 = print
  L5_2 = "============================================================================================"
  L4_2(L5_2)
  L4_2 = print
  L5_2 = [[





]]
  L4_2(L5_2)
end
function L10_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = Config
  L0_2 = L0_2.CheckIntegration
  if not L0_2 then
    return
  end
  L0_2 = print
  L1_2 = [[





]]
  L0_2(L1_2)
  L0_2 = print
  L1_2 = "===========================[^2MULTICHARACTER INTEGRATION CHECK^7]==============================="
  L0_2(L1_2)
  L0_2 = print
  L1_2 = "[^4/^7] Warmin up integration"
  L0_2(L1_2)
  L0_2 = Wait
  L1_2 = math
  L1_2 = L1_2.random
  L2_2 = 100
  L3_2 = 300
  L1_2, L2_2, L3_2 = L1_2(L2_2, L3_2)
  L0_2(L1_2, L2_2, L3_2)
  L0_2 = print
  L1_2 = "[^2STATUS OK^7] Integration prepared!\n"
  L0_2(L1_2)
  L0_2 = print
  L1_2 = "[^4/^7] Gathering debug data"
  L0_2(L1_2)
  L0_2 = Wait
  L1_2 = math
  L1_2 = L1_2.random
  L2_2 = 50
  L3_2 = 500
  L1_2, L2_2, L3_2 = L1_2(L2_2, L3_2)
  L0_2(L1_2, L2_2, L3_2)
  L0_2 = L1_1
  L0_2 = L0_2()
  L8_1.framework = L0_2
  L0_2 = FrameworkSelected
  if "ESX" == L0_2 then
    L0_2 = L2_1
    L0_2 = L0_2()
    L8_1.is_config_multichar_enabled = L0_2
    L0_2 = L3_1
    L0_2 = L0_2()
    L8_1.user_prefix_proper = L0_2
  end
  L0_2 = IsUIV2Active
  if L0_2 then
    L0_2 = L5_1
    L0_2 = L0_2()
    L8_1.uiv2_integrated = L0_2
  end
  L0_2 = L6_1
  L0_2 = L0_2()
  L8_1.appearance_integrated = L0_2
  L0_2 = L4_1
  L0_2 = L0_2()
  L0_2 = L0_2.state
  L8_1.other_multichar_running = L0_2
  L0_2 = L9_1
  L0_2()
end
L11_1 = Citizen
L11_1 = L11_1.CreateThread
function L12_1()
  local L0_2, L1_2
  L0_2 = Wait
  L1_2 = 3000
  L0_2(L1_2)
  L0_2 = L10_1
  L0_2()
end
L11_1(L12_1)
