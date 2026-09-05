-- Universal Hub Loader | supports multiple games | Delta Plugin fix included

-- Supported: Final Swarm (99521272836282)

local SUPPORTED = {

    [99521272836282] = "https://raw.githubusercontent.com/tyanxblack2-max/asdfasd/refs/heads/main/Final%20Swarm%20Delta%20FIX.luau", -- Final Swarm main

    [797875825749] = "https://raw.githubusercontent.com/tyanxblack2-max/asdfasd/refs/heads/main/Final%20Swarm%20Delta%20FIX.luau", -- Final Swarm Raid

    [9551044479] = "https://raw.githubusercontent.com/tyanxblack2-max/asdfasd/refs/heads/main/Final%20Swarm%20Delta%20FIX.luau", -- Final Swarm Universe

        [72119929635167] = "https://raw.githubusercontent.com/BO3DYXAN777/Liquid_Hub/refs/heads/main/ChessInc_.luau", -- Chess Incremental Place
    [10381920426] = "https://raw.githubusercontent.com/BO3DYXAN777/Liquid_Hub/refs/heads/main/ChessInc_.luau", -- Chess Incremental Game
    -- [PLACEID2] = "https://raw.githubusercontent.com/.../OtherGame.luau",

}



local function withPlugin(fn)

    local get = getthreadidentity or get_thread_identity or function() return 8 end

    local set = setthreadidentity or set_thread_identity or setthreadcontext or set_identity

    local old = get and get() or 8

    if set then pcall(set, 8) end

    local ok, res = pcall(fn)

    if set then pcall(set, old) end

    if not ok then error(res) end

    return res

end



withPlugin(function()

    local pid = game.PlaceId

    local gid = game.GameId

    local url = SUPPORTED[pid] or SUPPORTED[gid]

    -- fallback by name / map detection (for Final Swarm if place changes / Raid sub-place)

    if not url then

        local name = game.Name:lower()

        if name:find("swarm") then

            url = SUPPORTED[99521272836282]

        elseif workspace:FindFirstChild("Enemies") then

            local ok, hasRaid = pcall(function()

                for _,e in ipairs(workspace.Enemies:GetChildren()) do

                    if e.Name:lower():find("raid") or e.Name:lower():find("tomb") then return true end

                end

                return false

            end)

            if ok and hasRaid then url = SUPPORTED[99521272836282] end

        end

        if not url and workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Floor") then

            local ok, hasFloor = pcall(function() return workspace.Map.Floor.Size.Magnitude > 1000 end)

            if ok and hasFloor then url = SUPPORTED[99521272836282] end

        end

    end

    if url then

        loadstring(game:HttpGet(url))()

    else

        warn("[Universal Loader] Game not supported: PlaceId="..tostring(pid).." GameId="..tostring(gid).." Name="..tostring(game.Name))

        -- optional notification

        pcall(function()

            game:GetService("StarterGui"):SetCore("SendNotification", {

                Title = "Universal Loader",

                Text = "Game not supported: "..tostring(pid),

                Duration = 5

            })

        end)

    end

end)

