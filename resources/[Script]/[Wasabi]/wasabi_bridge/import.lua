local L0_1, L1_1, L2_1, L3_1
L0_1 = GetResourceState
L1_1 = "wasabi_bridge"
L0_1 = L0_1(L1_1)
L1_1 = L0_1
L0_1 = L0_1.find
L2_1 = "start"
L0_1 = L0_1(L1_1, L2_1)
if not L0_1 then
  L0_1 = print
  L1_1 = "^1wasabi_bridge should be started before this resource: "
  L2_1 = GetCurrentResourceName
  L2_1 = L2_1()
  L3_1 = "^0"
  L1_1 = L1_1 .. L2_1 .. L3_1
  L0_1(L1_1)
  return
end
L0_1 = exports
L0_1 = L0_1.wasabi_bridge
L1_1 = L0_1
L0_1 = L0_1.GetBridgeObject
L0_1 = L0_1(L1_1)
wsb = L0_1
L0_1 = wsb
L0_1 = L0_1.getCore
L0_1 = L0_1()
L1_1 = IsDuplicityVersion
L1_1 = L1_1()
if not L1_1 then
  L1_1 = wsb
  function L2_1(A0_2, A1_2)
    local L2_2, L3_2, L4_2
    L2_2 = AddEventHandler
    L3_2 = "wasabi_bridge:cache:"
    L4_2 = A0_2
    L3_2 = L3_2 .. L4_2
    L4_2 = A1_2
    L2_2(L3_2, L4_2)
  end
  L1_1.onCache = L2_1
  L1_1 = AddEventHandler
  L2_1 = "wasabi_bridge:initialize"
  function L3_1()
    local L0_2, L1_2
    L0_2 = GetInvokingResource
    L0_2 = L0_2()
    if "wasabi_bridge" ~= L0_2 then
      return
    end
    L0_2 = L0_1.Functions
    if L0_2 then
      L0_2 = wsb
      L1_2 = L0_1.Functions
      L1_2 = L1_2.GetPlayerData
      L1_2 = L1_2()
      L0_2.playerData = L1_2
      L0_2 = wsb
      L0_2.playerLoaded = true
    else
      L0_2 = wsb
      L1_2 = L0_1.GetPlayerData
      L1_2 = L1_2()
      L0_2.playerData = L1_2
      L0_2 = wsb
      L0_2.playerLoaded = true
    end
  end
  L1_1(L2_1, L3_1)
  L1_1 = AddEventHandler
  L2_1 = "wasabi_bridge:setPlayerData"
  function L3_1(A0_2)
    local L1_2, L2_2, L3_2
    L1_2 = GetInvokingResource
    L1_2 = L1_2()
    if "wasabi_bridge" ~= L1_2 then
      return
    end
    L1_2 = wsb
    L1_2 = L1_2.framework
    if "qb" == L1_2 then
      L1_2 = wsb
      L1_2.playerData = A0_2
      return
    end
    L1_2 = wsb
    L1_2 = L1_2.framework
    if "esx" == L1_2 then
      L1_2 = wsb
      L1_2 = L1_2.playerData
      L2_2 = A0_2.key
      L3_2 = A0_2.value
      L1_2[L2_2] = L3_2
    end
  end
  L1_1(L2_1, L3_1)
  L1_1 = AddEventHandler
  L2_1 = "wasabi_bridge:updateCache"
  function L3_1(A0_2, A1_2)
    local L2_2
    L2_2 = GetInvokingResource
    L2_2 = L2_2()
    if "wasabi_bridge" ~= L2_2 then
      return
    end
    L2_2 = wsb
    L2_2 = L2_2.cache
    L2_2[A0_2] = A1_2
  end
  L1_1(L2_1, L3_1)
  L1_1 = RegisterNetEvent
  L2_1 = "wasabi_bridge:playerLoaded"
  function L3_1(A0_2)
    local L1_2, L2_2
    L1_2 = wsb
    L1_2.playerData = A0_2
    L1_2 = wsb
    L1_2.playerLoaded = true
    L1_2 = wsb
    L1_2 = L1_2.framework
    if "qb" == L1_2 then
      L1_2 = wsb
      L2_2 = L0_1.Functions
      L2_2 = L2_2.GetPlayerData
      L2_2 = L2_2()
      L1_2.playerData = L2_2
    end
  end
  L1_1(L2_1, L3_1)
  L1_1 = RegisterNetEvent
  L2_1 = "wasabi_bridge:onPlayerLogout"
  function L3_1()
    local L0_2, L1_2
    L0_2 = table
    L0_2 = L0_2.wipe
    L1_2 = wsb
    L1_2 = L1_2.playerData
    L0_2(L1_2)
    L0_2 = wsb
    L0_2.playerLoaded = false
  end
  L1_1(L2_1, L3_1)
  L1_1 = RegisterNetEvent
  L2_1 = "wasabi_bridge:setJob"
  function L3_1(A0_2)
    local L1_2, L2_2
    L1_2 = wsb
    L1_2 = L1_2.playerData
    L1_2.job = A0_2
    L1_2 = wsb
    L1_2 = L1_2.framework
    if "qb" == L1_2 then
      L1_2 = wsb
      L2_2 = L0_1.Functions
      L2_2 = L2_2.GetPlayerData
      L2_2 = L2_2()
      L1_2.playerData = L2_2
    end
  end
  L1_1(L2_1, L3_1)
end
