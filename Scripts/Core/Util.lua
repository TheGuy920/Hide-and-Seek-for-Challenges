dofile("$CONTENT_DATA/Scripts/CustomGame/ChallengeModeMenuPack.lua")
dofile("$CONTENT_DATA/Scripts/CustomGame/ChallengeModeMenuPlay.lua")
dofile("$CONTENT_DATA/Scripts/CustomGame/ChallengeBuilder.lua")

local header = "$CONTENT_DATA/"

local function EscapePattern(s)
    return s:gsub("([^%w])", "%%%1")
end

if not sm.old then
    sm.old = { challenge = sm.challenge, world = { createWorld = sm.world.createWorld }, json = { save = sm.json.save, open = sm.json.open } } 

    sm.challenge = {
        private = {
            hasStarted = false,
            uuid = tostring(sm.uuid.getNil()),
            world = nil
        },
        setChallengeUuid = function(uuid)
            if uuid then
                sm.challenge.private.uuid = tostring(uuid)
            end
        end,
        resolveContentPath = function(string)
            local ret = string.gsub(string, "$CONTENT_DATA", "$CONTENT_"..sm.challenge.private.uuid)
            return ret
        end,
        hasStarted = function()
            return sm.challenge.private.hasStarted == true
        end,
        takePicturesForMenu = function()
            print("this is sad. no photo, even tho we want one :(")
        end,
        stop = function()
            sm.challenge.private.hasStarted = false
        end,
        start = function(world)
            sm.challenge.private.world = world
            sm.challenge.private.hasStarted = true
        end,
        setChallengeWorld = function(world)
            sm.challenge.private.world = world
        end,
        isChallengeWorld = function( world )
            return world == sm.challenge.private.world
        end,
        getSaveData = function(string)
            return sm.old.challenge.getSaveData(string)
        end,
        levelCompleted = function(string, time, data)
            sm.old.challenge.levelCompleted(string, time, data)
        end,
        getCompletionTime = function(uuid)
            return sm.old.challenge.getCompletionTime(uuid)
        end,
        isMasterMechanicTrial = function() return false end
    }

    sm.world.private = {
        storage = nil,
        target = nil
    }

    sm.world.setTargetWorld = function( world )
        sm.world.private.target = world
    end

    sm.world.isTargetWorld = function( world )
        return sm.world.private.target == world
    end

    sm.world.createWorld = function( filename, classname, terrainParams, seed )
        local nworld = sm.old.world.createWorld( filename, classname, terrainParams, seed )
        sm.world.setTargetWorld(nworld)
        return nworld
    end

    sm.gui.exitToMenu = function()
        if not sm.isServerMode() then
            sm.event.sendToGame("client_exitToMenu")
        else
            sm.event.sendToGame("server_exitToMenu")
        end
    end

    sm.json.save = function( data, path, pass )
        if not string.find(path, "/Overrides/") and string.find(path, sm.challenge.private.uuid, 1, true) and not pass then
            sm.event.sendToGame("server_saveAsOverride",{path=path, data=data})
            return
        end
        if pass then 
            sm.event.sendToGame("server_saveAsNow",{path=path, data=data})
            return
        end
        return sm.old.json.save(data, path)
    end

    sm.json.open = function( path )
        return sm.old.json.open(path)
    end

    sm.json.checkPath = function( path, pass )
        if string.find(path, header, 1, true) == nil and not pass then
            local trimmed = path:sub(10):gsub("/", ".")
            local override_path = header .. "Overrides/" .. trimmed
            local s, f = pcall(sm.json.fileExists, override_path)
            if s and f then
                return override_path
            end
        end
        return path
    end
end

if _G.ChallengeGame == nil then
    dofile("$CONTENT_DATA/Scripts/ChallengeModeScripts/challenge/ChallengeGame.lua")
    InitializeChallengeGame()
end

if _G.ChallengePlayer == nil then
    dofile("$CONTENT_DATA/Scripts/ChallengeModeScripts/game/ChallengePlayer.lua")
end

_G.States = {
    PackMenu = 0,
    PlayMenu = 1,
    BuildMenu = 2,
    Play = 3,
    PlayBuild = 4,
    Build = 5
}

if _G.FormatPath == nil then
    _G.FormatPath = function( path, uuid )
	    return string.gsub( path, "$CONTENT_DATA/", "$CONTENT_"..uuid.."/")
    end
end

if _G.LoadChallengeData == nil then
    _G.LoadChallengeData = function()
        local paths = { { path = "$CONTENT_e3589ff7-31ca-4f19-b1f0-bef055ba9200/ChallengeList.json", isLocal = false } }
        local challenge_levels = {}
        local challenge_packs = {}
        for index,data in pairs(paths) do
            local file = sm.json.open(data.path)
            for _,uuid in pairs(file.challenges) do
                if select(1, pcall(sm.json.fileExists, "$CONTENT_" .. uuid .. "/description.json")) then
                    local challenge, ctype = GetChallengesAndPacks( uuid )
                    if ctype == "level" then
                        if challenge_levels[uuid] ~= nil then goto passForLoop end
                        challenge.uuid = uuid
                        challenge.inPack = false
                        challenge.isPack = false
                        challenge.directory = "$CONTENT_"..uuid
                        challenge.isLocal = data.isLocal
                        challenge_levels[uuid] = challenge
                    elseif ctype == "pack" then
                        challenge.uuid = uuid
                        challenge.isPack = true
                        challenge.isLocal = data.isLocal
                        challenge.directory = "$CONTENT_"..uuid
                        challenge_packs[uuid] = challenge
                        for _,c in pairs(challenge.levelList) do
                            --if challenge_levels[c.uuid] ~= nil then break end
                            for _,creationPath in pairs(c.data.levelCreations) do
                                if not string.find(creationPath, "/Overrides/", 1, true) then
                                    local file = creationPath:match(".*/(.-)$")
                                    local fullPath = challenge.directory .. "/" .. c.uuid .. "/" .. file
                                    c.data.levelCreations[_] = sm.json.checkPath(fullPath)
                                end
                            end
                            c.inPack = true
                            c.isPack = false
                            c.packUuid = uuid
                            c.isLocal = data.isLocal
                            c.image = FormatPath(c.largeIcon, uuid)
                            c.directory = "$CONTENT_"..uuid
                            challenge_levels[c.uuid] = c
                        end
                    end
                end
                ::passForLoop::
            end
        end
        return { levels = challenge_levels, packs = challenge_packs  }
    end
end

if _G.GetChallengesAndPacks == nil then
    _G.GetChallengesAndPacks = function( uuid )
        local dir = "$CONTENT_"..uuid
        local content = nil
        local c_type = "fail"
        local cPackPath = dir.."/challengePack.json"
        local cLevelPath = dir.."/challengeLevel.json"
        local cAltPackPath = header .. "Overrides/" .. uuid .. ".challengePack.json"
        if sm.json.fileExists(cAltPackPath) then
            c_type = "pack"
            content = sm.json.open(cAltPackPath)
            local item = content.levelList[1]
            content.image = FormatPath(item.smallIcon, uuid)
        elseif sm.json.fileExists(cLevelPath) then
            c_type = "level"
            content = sm.json.open(cLevelPath)
            content.image = dir.."/icon_small.png"
        elseif sm.json.fileExists(cPackPath) then
            c_type = "pack"
            content = sm.json.open(cPackPath)
            local item = content.levelList[1]
            content.image = FormatPath(item.smallIcon, uuid)
        end
        return content, c_type
    end
end