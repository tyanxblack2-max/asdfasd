-- Universal Hub Loader | supports multiple games | Delta Plugin fix included

-- Supported: Final Swarm (99521272836282)

local SUPPORTED = {

    [99521272836282] = "https://raw.githubusercontent.com/tyanxblack2-max/asdfasd/refs/heads/main/Final%20Swarm%20Delta%20FIX%20Clean2.luau", -- Final Swarm main

    [797875825749] = "https://raw.githubusercontent.com/tyanxblack2-max/asdfasd/refs/heads/main/Final%20Swarm%20Delta%20FIX%20Clean2.luau", -- Final Swarm Raid

    [9551044479] = "https://raw.githubusercontent.com/tyanxblack2-max/asdfasd/refs/heads/main/Final%20Swarm%20Delta%20FIX%20Clean2.luau", -- Final Swarm Universe

        [72119929635167] = "https://raw.githubusercontent.com/BO3DYXAN777/Liquid_Hub/refs/heads/main/ChessInc_.luau", -- Chess Incremental Place
    [10381920426] = "https://raw.githubusercontent.com/BO3DYXAN777/Liquid_Hub/refs/heads/main/ChessInc_.luau", -- Chess Incremental Game
    -- [PLACEID2] = "https://raw.githubusercontent.com/.../OtherGame.luau",

}




local function deltaHttpGet(url)
    local ok, res
    ok, res = pcall(function() return game:HttpGet(url) end)
    if ok and type(res)=="string" and #res>200 then return res end
    ok, res = pcall(function() return game:HttpGetAsync(url) end)
    if ok and type(res)=="string" and #res>200 then return res end
    if request then
        ok, res = pcall(request, {Url=url, Method="GET"})
        if ok and res and res.Body and #res.Body>200 then return res.Body end
    end
    return nil
end

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

        local src = deltaHttpGet(url .. "?t=" .. tostring(math.floor(tick()))) or deltaHttpGet(url)
        if not src then warn("[Loader] HttpGet failed") return end
        local fn, err = loadstring(src)
        if not fn then warn("[Loader] loadstring failed: "..tostring(err)) return end
        local ok, res = pcall(fn)
        if not ok then warn("[Loader] script error: "..tostring(res)) end

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

