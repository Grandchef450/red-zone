local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1
L0_1 = {}
L1_1 = "__wsb_cb_%s"
L2_1 = GetConvarInt
L3_1 = "wsb:callbackTimeout"
L4_1 = 300000
L2_1 = L2_1(L3_1, L4_1)
L3_1 = {}
Callback = L3_1
L3_1 = {}
L4_1 = {}
L5_1 = RegisterNetEvent
L7_1 = L1_1
L6_1 = L1_1.format
L8_1 = "wasabi_bridge"
L6_1 = L6_1(L7_1, L8_1)
function L7_1(A0_2, ...)
  local L1_2, L2_2, L3_2
  L1_2 = L0_1
  L1_2 = L1_2[A0_2]
  if not L1_2 then
    return
  end
  L2_2 = L0_1
  L2_2[A0_2] = nil
  L2_2 = L1_2
  L3_2 = ...
  L2_2(L3_2)
end
L5_1(L6_1, L7_1)
function L5_1(A0_2, A1_2, A2_2, A3_2, ...)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L4_2 = assert
  L5_2 = DoesPlayerExist
  L6_2 = A2_2
  L5_2 = L5_2(L6_2)
  L6_2 = "target playerId '%s' does not exist"
  L7_2 = L6_2
  L6_2 = L6_2.format
  L8_2 = A2_2
  L6_2, L7_2, L8_2, L9_2, L10_2 = L6_2(L7_2, L8_2)
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
  L4_2 = nil
  repeat
    L5_2 = "%s:%s:%s"
    L6_2 = L5_2
    L5_2 = L5_2.format
    L7_2 = A1_2
    L8_2 = math
    L8_2 = L8_2.random
    L9_2 = 0
    L10_2 = 100000
    L8_2 = L8_2(L9_2, L10_2)
    L9_2 = A2_2
    L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
    L4_2 = L5_2
    L5_2 = L0_1
    L5_2 = L5_2[L4_2]
  until not L5_2
  L5_2 = TriggerClientEvent
  L6_2 = "wasabi_bridge:validateCallback"
  L7_2 = A2_2
  L8_2 = A1_2
  L9_2 = "wasabi_bridge"
  L10_2 = L4_2
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  L5_2 = TriggerClientEvent
  L6_2 = L1_1
  L7_2 = L6_2
  L6_2 = L6_2.format
  L8_2 = A1_2
  L6_2 = L6_2(L7_2, L8_2)
  L7_2 = A2_2
  L8_2 = "wasabi_bridge"
  L9_2 = L4_2
  L10_2 = ...
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  L5_2 = promise
  L5_2 = L5_2.new
  L5_2 = not A3_2 and L5_2
  L6_2 = L0_1
  function L7_2(A0_3, ...)
    local L1_3, L2_3, L3_3
    if "cb_invalid" == A0_3 then
      L1_3 = "callback '%s' does not exist"
      L2_3 = L1_3
      L1_3 = L1_3.format
      L3_3 = A1_2
      L1_3 = L1_3(L2_3, L3_3)
      A0_3 = L1_3
      L1_3 = L5_2
      if L1_3 then
        L1_3 = L5_2
        L2_3 = L1_3
        L1_3 = L1_3.reject
        L3_3 = A0_3
        L1_3 = L1_3(L2_3, L3_3)
        if L1_3 then
          goto lbl_21
        end
      end
      L1_3 = error
      L2_3 = A0_3
      L1_3 = L1_3(L2_3)
      ::lbl_21::
      return L1_3
    end
    L1_3 = {}
    L2_3 = A0_3
    L3_3 = ...
    L1_3[1] = L2_3
    L1_3[2] = L3_3
    A0_3 = L1_3
    L1_3 = L5_2
    if L1_3 then
      L1_3 = L5_2
      L2_3 = L1_3
      L1_3 = L1_3.resolve
      L3_3 = A0_3
      return L1_3(L2_3, L3_3)
    end
    L1_3 = A3_2
    if L1_3 then
      L1_3 = A3_2
      L2_3 = table
      L2_3 = L2_3.unpack
      L3_3 = A0_3
      L2_3, L3_3 = L2_3(L3_3)
      L1_3(L2_3, L3_3)
    end
  end
  L6_2[L4_2] = L7_2
  if L5_2 then
    L6_2 = SetTimeout
    L7_2 = L2_1
    function L8_2()
      local L0_3, L1_3, L2_3, L3_3, L4_3
      L0_3 = L5_2
      L1_3 = L0_3
      L0_3 = L0_3.reject
      L2_3 = "callback event '%s' timed out"
      L3_3 = L2_3
      L2_3 = L2_3.format
      L4_3 = L4_2
      L2_3, L3_3, L4_3 = L2_3(L3_3, L4_3)
      L0_3(L1_3, L2_3, L3_3, L4_3)
    end
    L6_2(L7_2, L8_2)
    L6_2 = table
    L6_2 = L6_2.unpack
    L7_2 = Citizen
    L7_2 = L7_2.Await
    L8_2 = L5_2
    L7_2, L8_2, L9_2, L10_2 = L7_2(L8_2)
    return L6_2(L7_2, L8_2, L9_2, L10_2)
  end
end
L6_1 = setmetatable
L7_1 = {}
L8_1 = {}
function L9_1(A0_2, A1_2, A2_2, A3_2, ...)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  if not A3_2 then
    L4_2 = warn
    L5_2 = "callback '%s' called without a callback function, this will cause the server to hang until the client responds"
    L6_2 = L5_2
    L5_2 = L5_2.format
    L7_2 = A1_2
    L5_2, L6_2, L7_2, L8_2, L9_2 = L5_2(L6_2, L7_2)
    L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
  else
    L4_2 = type
    L5_2 = A3_2
    L4_2 = L4_2(L5_2)
    if "table" == L4_2 then
      L5_2 = getmetatable
      L6_2 = A3_2
      L5_2 = L5_2(L6_2)
      if L5_2 then
        L5_2 = L5_2.__call
      end
      if L5_2 then
        L4_2 = "function"
      end
    end
    L5_2 = assert
    L6_2 = "function" == L4_2
    L7_2 = "expected argument 3 to have type 'function' (received %s)"
    L8_2 = L7_2
    L7_2 = L7_2.format
    L9_2 = L4_2
    L7_2, L8_2, L9_2 = L7_2(L8_2, L9_2)
    L5_2(L6_2, L7_2, L8_2, L9_2)
  end
  L4_2 = L5_1
  L5_2 = A0_2
  L6_2 = A1_2
  L7_2 = A2_2
  L8_2 = A3_2
  L9_2 = ...
  return L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
end
L8_1.__call = L9_1
L6_1 = L6_1(L7_1, L8_1)
Callback = L6_1
L6_1 = Callback
function L7_1(A0_2, A1_2, ...)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = L5_1
  L3_2 = nil
  L4_2 = A0_2
  L5_2 = A1_2
  L6_2 = false
  L7_2 = ...
  return L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
end
L6_1.awaitResponse = L7_1
function L6_1(A0_2, A1_2, ...)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  if not A0_2 then
    if A1_2 then
      L2_2 = print
      L3_2 = [[
^1SCRIPT ERROR: %s^0
%s]]
      L4_2 = L3_2
      L3_2 = L3_2.format
      L5_2 = A1_2
      L6_2 = Citizen
      L6_2 = L6_2.InvokeNative
      L7_2 = 3607903178
      L8_2 = nil
      L9_2 = 0
      L10_2 = Citizen
      L10_2 = L10_2.ResultAsString
      L10_2 = L10_2()
      L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2)
      if not L6_2 then
        L6_2 = ""
      end
      L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2 = L3_2(L4_2, L5_2, L6_2)
      return L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
    end
    L2_2 = false
    return L2_2
  end
  L2_2 = A1_2
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2 = ...
  return L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
end
L7_1 = pcall
L8_1 = Callback
function L9_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = L1_1
  L3_2 = L2_2
  L2_2 = L2_2.format
  L4_2 = A0_2
  L2_2 = L2_2(L3_2, L4_2)
  event = L2_2
  L2_2 = SetValidCallback
  L3_2 = A0_2
  L4_2 = true
  L2_2(L3_2, L4_2)
  L3_2 = event
  L2_2 = L4_1
  L2_2 = L2_2[L3_2]
  if L2_2 then
    L2_2 = RemoveEventHandler
    L4_2 = event
    L3_2 = L4_1
    L3_2 = L3_2[L4_2]
    L2_2(L3_2)
  end
  L3_2 = event
  L2_2 = L4_1
  L4_2 = AddEventHandler
  L5_2 = event
  function L6_2(A0_3, A1_3, ...)
    local L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3
    L2_3 = TriggerClientEvent
    L3_3 = L1_1
    L4_3 = L3_3
    L3_3 = L3_3.format
    L5_3 = A0_3
    L3_3 = L3_3(L4_3, L5_3)
    L4_3 = source
    L5_3 = A1_3
    L6_3 = L6_1
    L7_3 = L7_1
    L8_3 = A1_2
    L9_3 = source
    L10_3 = ...
    L7_3, L8_3, L9_3, L10_3 = L7_3(L8_3, L9_3, L10_3)
    L6_3, L7_3, L8_3, L9_3, L10_3 = L6_3(L7_3, L8_3, L9_3, L10_3)
    L2_3(L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3)
  end
  L4_2 = L4_2(L5_2, L6_2)
  L2_2[L3_2] = L4_2
  L3_2 = event
  L2_2 = L3_1
  L2_2 = L2_2[L3_2]
  if not L2_2 then
    L3_2 = event
    L2_2 = L3_1
    L2_2[L3_2] = true
    L2_2 = RegisterNetEvent
    L3_2 = event
    L2_2(L3_2)
  end
end
L8_1.register = L9_1
