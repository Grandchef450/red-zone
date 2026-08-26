local function check()
    local amount = MySQL.prepare.await("SELECT COUNT(*) AS count FROM users WHERE identifier NOT LIKE 'char%'", {})
    return amount == 0
end

return check