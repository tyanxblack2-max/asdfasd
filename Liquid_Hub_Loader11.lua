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
    local get = getthreadidentity or get_thread_identity or getthreadcontext or function() return 0 end
    local sets = {setthreadidentity, set_thread_identity, setthreadcontext, set_identity, (syn and syn.set_thread_identity), (syn and syn.set_thread_context)}
    local function trySet(v)
        for _, s in ipairs(sets) do
            if type(s)=="function" then pcall(s, v) end
        end
        -- also try 8 and 7
        pcall(function() if setthreadidentity then setthreadidentity(v) end end)
        pcall(function() if set_thread_identity then set_thread_identity(v) end end)
    end
    pcall(function() trySet(8) end)
    -- verify
    local cur = 0
    pcall(function() cur = get() end)
    if cur ~= 8 then
        pcall(function() trySet(7) end)
        pcall(function() cur = get() end)
    end
    -- DO NOT restore old identity - keep Plugin for WindUI heartbeat
    local ok, res = pcall(fn)
    if not ok then
        warn("[withPlugin] inner error: "..tostring(res))
        if error then pcall(error, res) else warn(res) end
    end
    return res
end

-- Ensure every new thread keeps Plugin capability (Delta heartbeat fix)
pcall(function()
    local _origSpawn = task.spawn
    local _origDefer = task.defer
    local _origDelay = task.delay
    local _origWrap = coroutine.wrap
    task.spawn = function(fn, ...)
        pcall(ensurePlugin)
        local args = {...}
        return _origSpawn(function()
            pcall(ensurePlugin)
            return fn(table.unpack(args))
        end)
    end
    task.defer = function(fn, ...)
        pcall(ensurePlugin)
        local args = {...}
        return _origDefer(function()
            pcall(ensurePlugin)
            return fn(table.unpack(args))
        end)
    end
    task.delay = function(t, fn, ...)
        pcall(ensurePlugin)
        local args = {...}
        return _origDelay(t, function()
            pcall(ensurePlugin)
            return fn(table.unpack(args))
        end)
    end
    if _origWrap then
        coroutine.wrap = function(fn)
            return function(...)
                pcall(ensurePlugin)
                return _origWrap(fn)(...)
            end
        end
    end
    -- also hook Heartbeat/RenderStepped if needed
    pcall(function()
        local hs = game:GetService("RunService")
        local origConnect = hs.Heartbeat.Connect
        -- not hooking connect, just ensurePlugin before each connect
    end)
end)

local function deltaHttpGet(url)
    local ok, res
    ok, res = pcall(function() return game:HttpGet(url) end)
    if ok and type(res)=="string" and #res>200 then return res end
    ok, res = pcall(function() return game:HttpGetAsync(url) end)
    if ok and type(res)=="string" and #res>200 then return res end
    if request then
        ok, res = pcall(request, {Url=url, Method="GET"})
        if ok and res and res.Body and #res.Body>200 then return res.Body end
        if ok and res and type(res)=="string" and #res>200 then return res end
    end
    if http_request then
        ok, res = pcall(http_request, {Url=url, Method="GET"})
        if ok and res and res.Body and #res.Body>200 then return res.Body end
    end
    if syn and syn.request then
        ok, res = pcall(syn.request, {Url=url, Method="GET"})
        if ok and res and res.Body and #res.Body>200 then return res.Body end
    end
    return nil
end



withPlugin(function()


    -- cooldown before HttpGet
    pcall(function()
        if not game:IsLoaded() then game.Loaded:Wait() end
        task.wait(1.5)
    end)

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

        local src = deltaHttpGet(url)
        if not src then
            warn("[Loader] HttpGet failed for "..tostring(url).." - check Http Requests enabled")
            return
        end
        local fn2, err = loadstring(src)
        if not fn2 then
            warn("[Loader] loadstring failed: "..tostring(err))
            return
        end
        local ok2, res2 = pcall(fn2)
        if not ok2 then
            warn("[Loader] script error: "..tostring(res2))
            if error then error(res2) else warn(res2) end
        end

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

