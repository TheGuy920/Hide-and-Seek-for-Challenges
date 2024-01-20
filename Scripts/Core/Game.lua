dofile("$CONTENT_a65c170c-ede3-4757-9f1a-586eabf1a2bc/Scripts/Core/Util.lua")
Game = class(nil)

local correctBasePos = sm.vec3.new(0, -114.5475, 6.1475)
local correctBaseDir = sm.vec3.new(0, 1, -0.11)

local pdiff = sm.vec3.new(0, 23.5, -2.5)
local ddiff = sm.vec3.new(0, 0.5, 0.631)

function Game.server_onCreate(self)
    print("Game.server_onCreate")
    sm.game.setLimitedInventory(false)
    self.special_challenge_has_init = true
    self.start_time = sm.game.getCurrentTick()
    self.respawn_all = 0
    
    self.worldDestroyQueue = {}
    self.sv = {
        saved = {
            world = sm.world.createWorld(
                "$CONTENT_a65c170c-ede3-4757-9f1a-586eabf1a2bc/Scripts/Core/Lobby.lua",
                "World"
            )
        }
    }

    local hasDatabase, _ = pcall(sm.json.open, "$CONTENT_e3589ff7-31ca-4f19-b1f0-bef055ba9200/ChallengeList.json")
    if not hasDatabase then
        self.network:sendToClients("client_setDependencyStatus",{hasDatabase=hasDatabase,hasAssets=true})
        return 
    end

    --self.ChallengeData = { packs = {}, levels = {} }
    self.ChallengeData = LoadChallengeData()
    self:server_updateGameState(States.PackMenu)
    self.ready = true

end

function Game.client_setDependencyStatus( self, data )
    self.MenuInstance = {
        blur = {
            blur_gui = sm.gui.createGuiFromLayout(
                "$CONTENT_a65c170c-ede3-4757-9f1a-586eabf1a2bc/Gui/Layouts/missing.layout",
                false,
                {
                    isHud = true,
                    isInteractive = false,
                    needsCursor = true,
                    hidesHotbar = true,
                    isOverlapped = true,
                    backgroundAlpha = 0
                }
            )
        }
    }
    self.MenuInstance.blur.blur_gui:setVisible("hasDatabase", not data.hasDatabase)
    self.MenuInstance.blur.blur_gui:setVisible("hasAssets", not data.hasAssets)
    self.MenuInstance.blur.blur_gui:open()
end

function Game.client_initializeMenu(self, force)
    if self.ChallengeData == nil then
        self.ChallengeData = {}
    end
    if self.MenuInstance == nil or force == true then
        if self.MenuInstance and self.MenuInstance.blur and sm.exists(self.MenuInstance.blur.gui) then
            self.MenuInstance.blur.gui:destroy()
        end
        local bgui = nil
        if self.MenuInstance ~= nil then
            bgui = self.MenuInstance.blur.blur_gui
            if sm.exists(self.MenuInstance.waiting.gui) then
                self.MenuInstance.waiting.gui:close()
                self.MenuInstance.waiting.gui:destroy()
            end
        end
        self.MenuInstance = {
            blur = {
                gui = nil,
                blur_gui = bgui,
                network = self.network
            },
            waiting = {
                gui = nil,
                progress = 2
            },
            pack = {
                gui = nil,
                network = self.network,
                challenge_packs = self.ChallengeData.packs,
                client_initializePlayMenu = self.client_initializePlayMenu,
                client_initializeBuildMenu = self.client_initializeBuildMenu
            },
            build = {
                gui = nil,
                network = self.network,
                toggle = true,
                challenge_levels = self.ChallengeData.levels
            },
            play = {
                gui = nil,
                network = self.network,
                challenge_levels = nil
            }
        }
    end
    if sm.isHost then
        sm.localPlayer.setLockedControls(true)
    else
        sm.localPlayer.setLockedControls(false)
    end
    --if force then self.ready = true end
end

function Game.client_initializeBackground(self)
    if sm.exists(self.MenuInstance.blur.gui) then
        self.MenuInstance.blur.gui:open()
    elseif sm.isHost then
        self.MenuInstance.blur.gui =
            sm.gui.createGuiFromLayout(
            "$CONTENT_a65c170c-ede3-4757-9f1a-586eabf1a2bc/Gui/Layouts/darken/darken.layout",
            true,
            {
                isHud = true,
                isInteractive = false,
                needsCursor = true,
                hidesHotbar = true,
                isOverlapped = true,
                backgroundAlpha = 0
            }
        )
        self.MenuInstance.blur.gui:open()
    end
    -- sm.camera.setPosition( correctBasePos + pdiff )
    -- sm.camera.setDirection( correctBaseDir + ddiff )
    sm.render.setOutdoorLighting(0.5)
end

function Game.client_initializePackMenu(self, force)
    self:client_initializeMenu(force)
    self:client_initializeBackground()

    if not sm.isHost then
        -- self.MenuInstance.pack.gui =
        --     sm.gui.createGuiFromLayout(
        --     "$CONTENT_a65c170c-ede3-4757-9f1a-586eabf1a2bc/Gui/Layouts/ClientLoadingScreen.layout",
        --     true,
        --     {
        --         isHud = true,
        --         isInteractive = false,
        --         needsCursor = false,
        --         hidesHotbar = false,
        --         isOverlapped = true,
        --         backgroundAlpha = 0.5
        --     }
        -- )
        -- self.MenuInstance.pack.gui:open()
    elseif sm.isHost then
        if self.ChallengeData == nil then
            self.ChallengeData = LoadChallengeData()
        end
        if sm.exists(self.MenuInstance.pack.gui) and force ~= true then
            self.MenuInstance.pack.gui:open()
        else
            if sm.exists(self.MenuInstance.pack.gui) then
                self.MenuInstance.pack.gui:close()
                self.MenuInstance.pack.gui:destroy()
            end
            _G["ChallengeModeMenuPack_LoadFunctions"](self.MenuInstance.pack)
            self.MenuInstance.pack.gui =
                sm.gui.createGuiFromLayout(
                "$CONTENT_a65c170c-ede3-4757-9f1a-586eabf1a2bc/Gui/Layouts/ChallengeModeMenuPack.layout"
            )
            self.MenuInstance.pack.gui:setVisible("RecordContainer", false)
            self.MenuInstance.pack.gui_table =
                sm.json.open(
                "$CONTENT_a65c170c-ede3-4757-9f1a-586eabf1a2bc/Scripts/CustomGame/Json/ChallengeModeMenuPack.json"
            )
            for _, item in pairs(self.MenuInstance.pack.gui_table.buttons) do
                self.MenuInstance.pack.gui:setButtonCallback(item.name, item.method)
            end
            for _, item in pairs(self.MenuInstance.pack.gui_table.text) do
                self.MenuInstance.pack.gui:setTextChangedCallback(item.name, item.method)
            end
            --self.MenuInstance.pack.gui:open()
        end
        self.MenuInstance.pack.ChallengeModeMenuPack_LOADED(self.MenuInstance.pack, 0, force)

        self.MenuInstance.pack.gui:setFocus("xx01441")
    end
end

function Game.client_exitToMenu(self)
    self.network:sendToServer("server_exitToMenu")
end

function Game.server_exitToMenu(self)
    self.network:sendToClients("client_tmpGui")
    local index = true
    for _, player in pairs(sm.player.getAllPlayers()) do
        if sm.exists(player.character) then
            local world = player.character:getWorld()
            sm.event.sendToWorld(world, "server_exitToMenu", index)
            index = false
        end
    end
end

function Game.server_startTest(self, level)
    self:server_updateGameState(States.PlayBuild)
    sm.game.setEnableRestrictions(ChallengeGame.enableRestrictions)
    sm.game.setEnableAmmoConsumption(ChallengeGame.enableAmmoConsumption)
    sm.game.setEnableFuelConsumption(ChallengeGame.enableFuelConsumption)
    sm.game.setEnableUpgrade(ChallengeGame.enableUpgrade)

    for _, player in pairs(sm.player.getAllPlayers()) do
        sm.event.sendToPlayer(player, "server_updateGameRules", level)
    end
    ChallengeGame.server_startTest(ChallengeGame, level)
end

function Game.server_exitToMenu2(self, data)
    if sm.exists(data.world) then
        data.world:destroy()
    end
    if data.first == true then
        -- reset ChallengeGame
        InitializeChallengeGame()
        self.ChallengeData = LoadChallengeData()
        if not sm.exists(self.sv.saved.world) then
            self.sv.saved.world =
                sm.world.createWorld("$CONTENT_a65c170c-ede3-4757-9f1a-586eabf1a2bc/Scripts/Core/Lobby.lua", "World")
        end
        self.respawn_all = 2
        self:server_updateGameState(States.PackMenu)
        self.ready = true
        self.network:sendToClients("client_closeTmp")

        sm.game.setLimitedInventory(true)
        for id,player in pairs(sm.player.getAllPlayers()) do
            local inv = player:getInventory()
            sm.container.beginTransaction()
            for i = 1, inv:getSize() do
                sm.container.setItem(inv, i - 1, sm.uuid.getNil(), 1)
            end
            if id == 1 or true then
                self.network:sendToClient(player, "client_giveHammer")
            end
            sm.container.endTransaction()
        end
    end
end

function Game.client_giveHammer(self)
    self.network:sendToServer(
        "server_giveHammer",
        {p = sm.localPlayer.getPlayer(), s = sm.localPlayer.getSelectedHotbarSlot()}
    )
end

function Game.server_giveHammer(self, param)
    local inv = param.p:getInventory()
    sm.container.beginTransaction()
    sm.container.setItem(inv, param.s, sm.uuid.new("9d4d51b5-f3a5-407f-a030-138cdcf30b4e"), 1)
    sm.container.endTransaction()
end

function Game.client_closeTmp(self, gui)
    if sm.exists(self.MenuInstance.waiting.gui) then
        self.MenuInstance.waiting.gui:destroy()
    end
end

function Game.client_tmpGui(self, gui)
    self.MenuInstance.waiting.gui =
        sm.gui.createGuiFromLayout("$CONTENT_a65c170c-ede3-4757-9f1a-586eabf1a2bc/Gui/Layouts/waiting.layout")
    self.MenuInstance.waiting.gui:open()
end

function Game.client_initializeBuildMenu(self, force)
    if not sm.isHost then
        return
    end

    self:client_initializeMenu()
    self:client_initializeBackground()

    if sm.exists(self.MenuInstance.build.gui) and force ~= true then
        self.MenuInstance.build.gui:open()
    else
        _G["ChallengeBuilder_LoadFunctions"](self.MenuInstance.build)
        self.MenuInstance.build.gui =
            sm.gui.createGuiFromLayout(
            "$CONTENT_a65c170c-ede3-4757-9f1a-586eabf1a2bc/Gui/Layouts/ChallengeBuilder.layout"
        )
        self.MenuInstance.build.gui:setVisible("RecordContainer", false)
        self.MenuInstance.build.level_table =
            sm.json.open("$CONTENT_a65c170c-ede3-4757-9f1a-586eabf1a2bc/Scripts/CustomGame/Json/ChallengeBuilder.json")
        for _, item in pairs(self.MenuInstance.build.level_table.buttons) do
            self.MenuInstance.build.gui:setButtonCallback(item.name, item.method)
        end
        for _, item in pairs(self.MenuInstance.build.level_table.text) do
            self.MenuInstance.build.gui:setTextChangedCallback(item.name, item.method)
        end
    end
    self.MenuInstance.build.ChallengeBuilder_LOADED(self.MenuInstance.build, 0, true)

    self.network:sendToServer("server_updateGameState", States.BuildMenu)

    self.MenuInstance.build.gui:setFocus("xx01441")
end

function Game.client_level_ChangeTitle(self, button, text)
    self.MenuInstance.build.client_ChangeTitle(self.MenuInstance.build, button, text)
end

function Game.client_level_AddChallenge(self, button)
    self.MenuInstance.build.client_AddChallenge(self.MenuInstance.build, button)
end

function Game.client_level_ChangeDescription(self, button, text)
    self.MenuInstance.build.client_ChangeDescription(self.MenuInstance.build, button, text)
end

function Game.client_level_BuildChallenge(self, button)
    self.MenuInstance.build.client_BuildChallenge(self.MenuInstance.build, button)
end

function Game.client_level_PlayChallenge(self, button)
    self.MenuInstance.build.client_PlayChallenge(self.MenuInstance.build, button)
end

function Game.client_level_OpenGui(self)
    self.MenuInstance.build.gui:close()
    self.network:sendToServer("server_updateGameState", States.PackMenu)
    --self:client_initializePackMenu(true)
end

function Game.client_play_OpenGui(self)
    self.MenuInstance.play.gui:close()
    self.network:sendToServer("server_updateGameState", States.PackMenu)
    --self:client_initializePackMenu(true)
end

function Game.client_level_SelectChallenge(self, button)
    self.MenuInstance.build.client_SelectChallenge(self.MenuInstance.build, button)
end

function Game.client_level_DeselectAll(self)
    self.MenuInstance.build.client_DeselectAll(self.MenuInstance.build)
end

function Game.client_level_NewChallenge(self)
    print("NO NEW CHALLENGE FOR YOU!")
end

function Game.client_pack_OpenGui(self, button)
    self.MenuInstance.pack.gui:close()
    self:client_initializeBuildMenu(true)
end

function Game.client_pack_SelectChallenge(self, button)
    self.MenuInstance.pack.client_SelectChallenge(self.MenuInstance.pack, button)
end

function Game.client_pack_DeselectAll(self)
    self.MenuInstance.pack.client_DeselectAll(self.MenuInstance.pack)
end

function Game.client_pack_CloseMenu(self, button)
    self.MenuInstance.pack.client_CloseMenu(self.MenuInstance.pack, button)
end

function Game.client_pack_SelectPack(self, button)
    if tonumber(self.MenuInstance.pack.selected_index) >= 0 then
        local index = self.MenuInstance.pack.selected_index + 1 + self.MenuInstance.pack.offset
        local uuid = self.MenuInstance.pack.number_index[index].uuid
        self:client_initializePlayMenu(uuid, true)
    end
end

function Game.client_play_SelectChallenge(self, button)
    self.MenuInstance.play.client_SelectChallenge(self.MenuInstance.play, button)
end

function Game.client_SelectPlay(self, button)
    self.MenuInstance.play.gui:close()
    self.MenuInstance.blur.gui:close()
    self.MenuInstance.blur.gui:destroy()
    local index = self.MenuInstance.play.selected_index + 1 + self.MenuInstance.play.offset
    local item = self.MenuInstance.play.challenge_levels[index]
    local index = 1
    for i, level in pairs(self.ChallengeData.packs[item.packUuid].levelList) do
        if level.uuid == item.uuid then
            index = i
            break
        end
    end
    self.network:sendToServer(
        "server_initializeChallengeGame",
        {packUuid = item.packUuid, index = index, level = item.uuid}
    )
end

function Game.client_initializePlayMenu(self, uuid, force)
    if uuid == nil or not sm.isHost then
        return
    end
    self.MenuInstance.pack.gui:close()

    self:client_initializeMenu()
    self:client_initializeBackground()

    if sm.exists(self.MenuInstance.play.gui) and force ~= true then
        self.MenuInstance.play.gui:open()
    else
        self.MenuInstance.play.uuid = uuid
        self.MenuInstance.play.challenge_levels = self.ChallengeData.packs[uuid].levelList
        --for _, level in pairs(self.ChallengeData.packs[uuid].levelList) do
        --    table.insert(self.MenuInstance.play.challenge_levels, self.ChallengeData.levels[level.uuid])
        --end
        _G["ChallengeModeMenuPlay_LoadFunctions"](self.MenuInstance.play)
        self.MenuInstance.play.gui =
            sm.gui.createGuiFromLayout(
            "$CONTENT_a65c170c-ede3-4757-9f1a-586eabf1a2bc/Gui/Layouts/ChallengeModeMenuPlay.layout"
        )
        self.MenuInstance.play.gui:setVisible("RecordContainer", false)
        self.MenuInstance.play.play_table =
            sm.json.open(
            "$CONTENT_a65c170c-ede3-4757-9f1a-586eabf1a2bc/Scripts/CustomGame/Json/ChallengeModeMenuPlay.json"
        )
        for _, item in pairs(self.MenuInstance.play.play_table.buttons) do
            self.MenuInstance.play.gui:setButtonCallback(item.name, item.method)
        end
        for _, item in pairs(self.MenuInstance.play.play_table.text) do
            self.MenuInstance.play.gui:setTextChangedCallback(item.name, item.method)
        end
    end
    self.MenuInstance.play.ChallengeModeMenuPlay_LOADED(self.MenuInstance.play, 0)

    self.network:sendToServer("server_updateGameState", States.PlayMenu)

    self.MenuInstance.play.gui:setFocus("xx01441")
end

function Game.server_fetchLevelData(self, data)
    local return_data = {}
    if tostring(type(data)) == "string" then
        local pack_uuid = data
        local pack = self.ChallengeData.packs[pack_uuid]
        if pack then
            for _, level in pairs(pack.levelList) do
                local uuid = sm.uuid.new(level.uuid)
                local time = sm.challenge.getCompletionTime(uuid)
                return_data[tostring(uuid)] = time
            end
        else
            local level = self.ChallengeData.levels[pack_uuid]
            if level then
                local uuid = sm.uuid.new(level.uuid)
                local time = sm.challenge.getCompletionTime(uuid)
                return_data[pack_uuid] = time
            end
        end
    else
        --[[
        local pack_uuid_list =
            sm.json.open(
            "$CHALLENGE_DATA/LocalChallengeList.json"
        ).challenges
        for _, c in pairs(sm.json.open("$CONTENT_e3589ff7-31ca-4f19-b1f0-bef055ba9200/ChallengeList.json").challenges) do
            table.insert(pack_uuid_list, c)
        end
        for _, pack_uuid in pairs(pack_uuid_list) do
            local pack = self.ChallengeData.packs[pack_uuid]
            if pack then
                local level_data = {}
                for _, level in pairs(pack.levelList) do
                    local uuid = sm.uuid.new(level.uuid)
                    local time = sm.challenge.getCompletionTime(uuid)
                    level_data[tostring(uuid)] = time
                end
                return_data[pack_uuid] = level_data
            end
        end
        ]]
    end
    self.network:sendToClients("client_recieveLevelTimes", return_data)
end

function Game.client_recieveLevelTimes(self, times)
    if self.state == States.PlayMenu and sm.isHost then
        self.MenuInstance.play.client_recieveLevelTimes(self.MenuInstance.play, times)
    elseif self.state == States.PackMenu and sm.isHost then
        self.MenuInstance.pack.client_recieveLevelTimes(self.MenuInstance.pack, times)
    elseif self.state == States.BuildMenu and sm.isHost then
        self.MenuInstance.build.client_recieveLevelTimes(self.MenuInstance.build, times)
    end
end

function Game.client_ScrollUp(self, button)
    if self.state == States.PackMenu then
        self.MenuInstance.pack.ChallengeModeMenuPack_LOADED(self.MenuInstance.pack, self.MenuInstance.pack.offset - 2)
    elseif self.state == States.PlayMenu then
        self.MenuInstance.play.ChallengeModeMenuPlay_LOADED(self.MenuInstance.play, self.MenuInstance.play.offset - 3)
    elseif self.state == States.BuildMenu then
        self.MenuInstance.build.ChallengeBuilder_LOADED(self.MenuInstance.build, self.MenuInstance.build.offset - 4)
    end
end

function Game.client_ScrollDown(self, button)
    if self.state == States.PackMenu then
        self.MenuInstance.pack.ChallengeModeMenuPack_LOADED(self.MenuInstance.pack, self.MenuInstance.pack.offset + 2)
    elseif self.state == States.PlayMenu then
        self.MenuInstance.play.ChallengeModeMenuPlay_LOADED(self.MenuInstance.play, self.MenuInstance.play.offset + 3)
    elseif self.state == States.BuildMenu then
        self.MenuInstance.build.ChallengeBuilder_LOADED(self.MenuInstance.build, self.MenuInstance.build.offset + 4)
    end
end

function Game.client_toggleShowing(self)
    if self.state == States.BuildMenu and sm.isHost then
        self.MenuInstance.build.client_toggleShowing(self.MenuInstance.build)
    end
end

function Game.client_shutDownMenu(self)
    if self.MenuInstance ~= nil then
        if self.MenuInstance.pack.gui ~= nil and self.MenuInstance.pack.gui:isActive() then
            self.MenuInstance.pack.gui:close()
        end
        if self.MenuInstance.blur.gui ~= nil and self.MenuInstance.blur.gui:isActive() then
            self.MenuInstance.blur.gui:close()
            self.MenuInstance.blur.gui:destroy()
        end
        if self.MenuInstance.build.gui ~= nil and self.MenuInstance.build.gui:isActive() then
            self.MenuInstance.build.gui:close()
        end
        if self.MenuInstance.play.gui ~= nil and self.MenuInstance.play.gui:isActive() then
            self.MenuInstance.play.gui:close()
        end
    end
    sm.camera.setCameraState(1)
    self.ready = nil
    sm.localPlayer.setLockedControls(false)
end

function Game.server_initializeChallengeGame(self, data)
    self.network:sendToClients("client_shutDownMenu")
    if self.ChallengeData == nil then
        self.ChallengeData = LoadChallengeData()
    end
    local pack = self.ChallengeData.packs[data.packUuid]
    sm.challenge.setChallengeUuid(pack.uuid)

    pack.startLevelIndex = data.index
    ChallengeGame.data = pack
    ChallengeGame.network = self.network
    --self.sv.saved.world:destroy()
    --self.sv.saved.world = nil

    for _, player in pairs(sm.player.getAllPlayers()) do
        sm.event.sendToPlayer(player, "server_updateGameRules", self.ChallengeData.levels[data.level].data)
    end

    self.network:sendToClients("client_initializeChallengeGame")
    self:server_updateGameState(States.Play)

    ChallengeGame.server_onCreate(ChallengeGame)

    sm.game.setLimitedInventory(ChallengeGame.enableLimitedInventory)
    sm.game.setEnableRestrictions(ChallengeGame.enableRestrictions)
    sm.game.setEnableAmmoConsumption(ChallengeGame.enableAmmoConsumption)
    sm.game.setEnableFuelConsumption(ChallengeGame.enableFuelConsumption)
    sm.game.setEnableUpgrade(ChallengeGame.enableUpgrade)
end

function Game.server_initializeChallengeBuild(self, uuid)
    self.network:sendToClients("client_shutDownMenu")
    if self.ChallengeData == nil then
        self.ChallengeData = LoadChallengeData()
    end
    local level = self.ChallengeData.levels[uuid]
    local uuid = level.packUuid
    if not uuid then
        uuid = level.uuid
    end
    sm.challenge.setChallengeUuid(uuid)

    level.startLevelIndex = nil
    ChallengeGame.data = level
    ChallengeGame.play = nil
    ChallengeGame.network = self.network
    --ChallengeGame.world = self.sv.saved.world

    sm.game.setLimitedInventory(false)
    sm.game.setEnableRestrictions(false)
    sm.game.setEnableAmmoConsumption(false)
    sm.game.setEnableFuelConsumption(false)
    sm.game.setEnableUpgrade(true)

    self.network:sendToClients("client_initializeChallengeGame")
    self:server_updateGameState(States.Build)
    ChallengeGame.server_onCreate(ChallengeGame)

    for _, player in pairs(sm.player.getAllPlayers()) do
        sm.event.sendToPlayer(player, "server_updateGameRules", {settings = {enable_health = false}})
    end
end

function Game.server_onChatCommand(self, params)
    if self.state == States.PlayBuild or self.state == States.Build then
        ChallengeGame.server_onChatCommand(ChallengeGame)
    end
end

local function EscapePattern(s)
    return s:gsub("([^%w])", "%%%1")
end

function Game.server_saveAsNow(self, _table)
    local path = _table.path
    local data = _table.data
    sm.old.json.save(data, path)
end

function Game.server_saveAsOverride(self, _table)
    local path = _table.path
    local data = _table.data
    local header = "$CONTENT_a65c170c-ede3-4757-9f1a-586eabf1a2bc/Overrides/"
    local stripped = string.gsub(path, EscapePattern("$CONTENT_"), "")
    local level = self.ChallengeData.levels[ChallengeGame.build.level.uuid]
    if #level.packUuid > 10 then
        header = header .. level.packUuid .. "."
        stripped = string.gsub(stripped, EscapePattern(level.packUuid), "")
    end
    header = header .. level.uuid
    stripped = string.gsub(stripped, EscapePattern(level.uuid), ""):gsub("/", ".")

    local new_path = header .. stripped
    sm.old.json.save(data, new_path)
end

function Game.server_stopTest(self)
    self:_server_onStopTest()
    --ChallengeGame.server_stopTest( ChallengeGame )
end

function Game.server_exportPackData(self, data)
    local newLevel = data.level
    local savePath = data.path
    local detailedLevel = self.ChallengeData.levels[newLevel.uuid]
    local pack = self.ChallengeData.packs[detailedLevel.packUuid]
    local newpack = {levelList = {}}
    for _, level in pairs(pack.levelList) do
        if level.uuid == newLevel.uuid then
            newLevel.smallIcon = level.smallIcon
            newLevel.description = level.description
            newLevel.largeIcon = level.largeIcon
            newLevel.name = level.name
            table.insert(newpack.levelList, newLevel)
        else
            table.insert(newpack.levelList, level)
        end
    end
    sm.old.json.save(newpack, savePath)
end

function Game.client_PlayBuild(self, uuid)
    local index = 1
    local level = self.ChallengeData.levels[uuid]
    local pack = self.ChallengeData.packs[level.packUuid]
    for i, level in pairs(pack.levelList) do
        if level.uuid == uuid then
            index = i
            break
        end
    end
    self.network:sendToServer(
        "server_initializeChallengeGame",
        {packUuid = level.packUuid, index = index, level = uuid}
    )
end

function Game.client_LoadBuild(self, uuid)
    self.network:sendToServer("server_initializeChallengeBuild", uuid)
end

function Game.client_initializeChallengeGame(self)
    ChallengeGame.client_onCreate(ChallengeGame)
end

function Game.server_worldScriptReady(self, caller)
    -- Block Player Calls
    if not sm.isServerMode() or caller ~= nil then
        return
    end
    -- Update World Script
    if sm.exists(self.sv.saved.world) then
        sm.event.sendToWorld(self.sv.saved.world, "server_updateGameState", self.state)
    end
end

function Game.sve_destroyWorld(self, world)
    if self.worldDestroyQueue == nil then
        self.worldDestroyQueue = {}
    end
    table.insert(self.worldDestroyQueue, {world = world, time = 21})
end

function Game.server_playerScriptReady(self, player, caller)
    -- Block Player Calls
    if not sm.isServerMode() or caller ~= nil then
        return
    end
    -- Update Players
    -- self:server_updateAllPlayerStates()
    sm.event.sendToPlayer(player, "server_updateGameState", self.state)
end

function Game.server_updateAllPlayerStates(self, caller)
    -- Update Player Scripts
    for _, player in pairs(sm.player.getAllPlayers()) do
        sm.event.sendToPlayer(player, "server_updateGameState", self.state)
    end
end

function Game.server_updateGameState(self, State, caller)
    -- Block Player Calls
    if sm.isServerMode() and (caller == nil or caller == sm.host) then
        -- Update Self
        self.state = State
        -- Send to all Clients
        self.network:sendToClients("client_updateGameState", State)
        -- Init items
        if self.state == 98 then
            self.state = States.PackMenu
            self.network:sendToClients("client_initializeApology", true)
        elseif self.state == States.PackMenu then
            self.network:sendToClients("client_initializePackMenu", true)
        elseif self.state == States.PlayMenu then
        elseif self.state == States.BuildMenu then
        end
        -- Update World Script
        if sm.exists(self.sv.saved.world) then
            sm.event.sendToWorld(self.sv.saved.world, "server_updateGameState", State)
        elseif sm.exists(ChallengeGame.world) then
            sm.event.sendToWorld(ChallengeGame.world, "server_updateGameState", State)
        end
        -- Update Player Scripts
        self:server_updateAllPlayerStates()
    end
end

function Game.loadCraftingRecipes(self)
    LoadCraftingRecipes(
        {
            craftbot = "$SURVIVAL_DATA/CraftingRecipes/craftbot.json"
        }
    )
end

function Game.client_updateGameState(self, State, caller)
    -- Block Player Calls, maybe
    if caller ~= nil or sm.isServerMode() then
        return
    end
    -- Update Self
    self.state = State
end

function Game.server_onPlayerJoined(self, player, isNewPlayer)
    print("Game.server_onPlayerJoined")
    if sm.host == nil then
        sm.host = sm.player.getAllPlayers()[1]
    end
    sm.event.sendToPlayer(player, "server_playerJoined", {isnew = isNewPlayer, state = self.state})
    if self.state == States.PackMenu or self.state == States.PlayMenu or self.state == States.BuildMenu then
        if not sm.exists(self.sv.saved.world) then
            sm.world.loadWorld(self.sv.saved.world)
        end
        self.sv.saved.world:loadCell(0, 0, player, "sv_createPlayerCharacter")
        -- Send to all Client
        self.network:sendToClient(player, "client_updateGameState", self.state)
        -- Init menu
        if player ~= sm.host then
            self.network:sendToClient(player, "client_initializePackMenu")
        end
    end

    if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
        ChallengeGame.server_onPlayerJoined(ChallengeGame, player, isNewPlayer)
    end
end

function Game.server_getHideAndSeekOptions( self, tool )
    sm.event.sendToTool(tool, "server_recieveOptionsFromGame", self.hideandseekoptions)
end

function Game.server_setHideAndSeekOptions(self, data)
    if not data then data = self.hideandseekoptions end
    
    if data then
        self.hideandseekoptions = data
        for _,player in pairs(sm.player.getAllPlayers()) do
            for _,rplayer in pairs(self.hideandseekoptions.players) do
                if rplayer.name == player:getName() then
                    goto skip1
                end
            end
            table.insert(self.hideandseekoptions.players, {name = player:getName(), state = 1})
            ::skip1::
        end
        for i,rplayer in pairs(self.hideandseekoptions.players) do
            for _,player in pairs(sm.player.getAllPlayers()) do
                if rplayer.name == player:getName() then
                    goto skip0
                end
            end
            table.remove(self.hideandseekoptions.players, i)
            ::skip0::
        end
        ChallengeGame.hideandseekoptions = self.hideandseekoptions
        sm.event.sendToWorld(ChallengeGame.world, "server_setHideAndSeekOptions", self.hideandseekoptions)
        for _,player in pairs(sm.player.getAllPlayers()) do
            sm.event.sendToPlayer(player, "server_setHideAndSeekOptions", self.hideandseekoptions)
        end
    end
end

function Game.sv_createPlayerCharacter(self, world, x, y, player, params)
    if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
        sm.event.sendToWorld(world, "server_spawnCharacter", {players = {player}, playCutscene = false})
    elseif sm.exists(world) then
        local vector = sm.vec3.new(0, -92.5, 5)
        local yaw = math.pi
        if player == sm.host then
            vector = sm.vec3.new(0.8375, -112.725, 6)
            yaw = yaw - 0.88
        end
        local character = nil
        if not player:getCharacter() then
            character = sm.character.createCharacter(player, world, vector, yaw, 0)
            player:setCharacter(character)
        else
            character = player:getCharacter()
        end     
        if player == sm.host then
            sm.event.sendToWorld(world, "server_setMenuLock", character)
        else
            sm.event.sendToWorld(world, "server_setMenuLockNil", character)
        end
        self.network:sendToClient(player, "client_getSelectedHotBarAndReturn", "server_setHostHammer")
        self.server_setHostHammer = function ( self, index )
            sm.game.setLimitedInventory(false)
            sm.container.beginTransaction()
            for i = 1, player:getHotbar():getSize() do
                sm.container.setItem(player:getHotbar(), i - 1, sm.uuid.getNil(), 1)
            end
            sm.container.setItem(player:getHotbar(), index, sm.uuid.new("9d4d51b5-f3a5-407f-a030-138cdcf30b4e"), 1)
            sm.container.endTransaction()
            sm.game.setLimitedInventory(true)
        end
    end
end

function Game.client_getSelectedHotBarAndReturn( self, callback )
	self.network:sendToServer(callback, sm.localPlayer.getSelectedHotbarSlot())
end

function Game.server_onFixedUpdate(self, timeStep)
    --if not self.player_script_loaded then
    --    self.player_script_loaded = _G.sm.load_player_script()
    --    return
    --end
    if not self.special_challenge_has_init then
        Game.server_onCreate(self)
        self.all_need_respawn = true
    end
    if self.all_need_respawn then
        self.all_need_respawn = false
        for _, player in pairs(sm.player.getAllPlayers()) do
            self:server_onPlayerJoined(player, false)
        end
    end
    if self.state == States.PackMenu or self.state == States.PlayMenu or self.state == States.BuildMenu then
        if #self.worldDestroyQueue > 0 then
            self.respawn_all = 1
            for index, item in pairs(self.worldDestroyQueue) do
                if item ~= nil and sm.exists(item.world) then
                    if item.time > 0 then
                        item.time = item.time - 1
                    else
                        item.world:destroy()
                        table.remove(self.worldDestroyQueue, index)
                    end
                end
            end
            if #self.worldDestroyQueue == 0 and self.respawn_all == 1 then
                self.respawn_all = 2
            end
        end
        if self.respawn_all == 2 then
            for _, player in pairs(sm.player.getAllPlayers()) do
                self:server_onPlayerJoined(player, false)
            end
            self.respawn_all = 0
        end
    elseif self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
        ChallengeGame.server_onFixedUpdate(ChallengeGame, timeStep)
    end
end

function Game.server_spawnNewCharacter(self, params, caller)
    sm.event.sendToWorld(ChallengeGame.world, "server_spawnNewCharacter", params)
end

function Game.server_worldReadyForPlayers(self)
    sm.event.sendToWorld(ChallengeGame.world, "server_spawnCharacter", {players = sm.player.getAllPlayers()})
end

function Game.server_onCellLoadComplete(self, data)
    if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
        data.world = ChallengeGame.world
        ChallengeGame.server_onCellLoadComplete(ChallengeGame, data)
    end
end

function Game.server_getLevelData(self)
    if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
        ChallengeGame.server_getLevelData(ChallengeGame)
    end
end

function Game.server_getLevelUuid(self)
    if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
        ChallengeGame.server_getLevelUuid(ChallengeGame)
    end
end

function Game.server_onFinishedLoadContent(self)
    if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
        ChallengeGame.server_onFinishedLoadContent(ChallengeGame)
    end
end

function Game.server_onChallengeStarted(self)
    if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
        ChallengeGame.server_onChallengeStarted(ChallengeGame)
    end
end

function Game.server_onChallengeCompleted(self, param)
    if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
        ChallengeGame.server_onChallengeCompleted(ChallengeGame, param)
    end
end

function Game.sv_e_respawn(self, params)
    if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
        ChallengeGame.sv_e_respawn(ChallengeGame, params)
    end
end

function Game.setupMessageGui(self)
    if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
        ChallengeGame.setupMessageGui(ChallengeGame)
    end
end

function Game.setupHUD(self)
    if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
        ChallengeGame.setupHUD(ChallengeGame)
    end
end

function Game.client_showMessage(self, params)
    if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
        ChallengeGame.client_showMessage(ChallengeGame, params)
    end
end

function Game.client_onNextPressed(self)
    if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
        ChallengeGame.network = self.network
        ChallengeGame.client_onNextPressed(ChallengeGame)
    end
end

function Game.client_onResetPressed(self)
    if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
        ChallengeGame.network = self.network
        ChallengeGame.client_onResetPressed(ChallengeGame)
    end
end

function Game.client_onChallengeReset(self)
    if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
        ChallengeGame.client_onChallengeReset(ChallengeGame)
    end
end

function Game.client_onChallengeStarted(self, params)
    if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
        ChallengeGame.client_onChallengeStarted(ChallengeGame, params)
    end
end

function Game.client_onChallengeCompleted(self, params)
    if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
        ChallengeGame.client_onChallengeCompleted(ChallengeGame, params)
    end
end

function Game.client_sessionStarted(self, id)
    if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
        ChallengeGame.client_sessionStarted(ChallengeGame, id)
    end
end

function Game.cl_e_leaveGame(self)
    if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
    --ChallengeGame.cl_e_leaveGame(ChallengeGame)
    end
end

function Game.client_onCreate(self)
    if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
        ChallengeGame.client_onCreate(ChallengeGame)
    end
end

function Game.client_setClientTool(self, tool)
    _G.GameRef = self
end

local function FloorVec(vec, f)
    return sm.vec3.new(
        math.floor(vec.x * math.pow(10, f)) / math.pow(10, f),
        math.floor(vec.y * math.pow(10, f)) / math.pow(10, f),
        math.floor(vec.z * math.pow(10, f)) / math.pow(10, f)
    )
end

function Game.server_removeCarry(self, container)
    sm.container.beginTransaction()
    for i = 0, container:getSize() do
        sm.container.setItem(container, i, sm.uuid.getNil(), 1)
    end
    sm.container.endTransaction()
end

function Game.client_removeCarry(self, container)
    self.network:sendToServer("server_removeCarry", container)
end

function Game.client_onUpdate(self, deltaTime)
    local exists, container = pcall(sm.localPlayer.getCarry)
    if exists and container and not container:isEmpty() then
        sm.event.sendToGame("client_removeCarry", container)
    end

    if not self.MenuInstance then
        self:client_initializeMenu()
    end

    if (self.MenuInstance.blur.blur_gui == nil or not sm.exists(self.MenuInstance.blur.blur_gui)) and sm.isHost then
        self.MenuInstance.blur.blur_gui =
            sm.gui.createGuiFromLayout(
            "$CONTENT_a65c170c-ede3-4757-9f1a-586eabf1a2bc/Gui/Layouts/darken/darken_new.layout",
            false,
            {
                isHud = true,
                isInteractive = false,
                needsCursor = true,
                hidesHotbar = true,
                isOverlapped = true,
                backgroundAlpha = 0
            }
        )
    end

    _G.GameRef = self

    if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
        ChallengeGame.client_onUpdate(ChallengeGame, deltaTime)
    end

    if self.MenuInstance.blur.blur_gui:isActive() and sm.exists(self.MenuInstance.blur.gui) and
            self.MenuInstance.blur.gui:isActive()
     then
        self.MenuInstance.blur.blur_gui:close()
    end
    deltaTime = deltaTime / 2
    if self.ready ~= nil and self.loading_screen_lifted and sm.isHost then
        if self.ready then
            local dtt = deltaTime
            if self.ready == true then
                self.ready = {
                    pos = sm.vec3.new(correctBasePos.x, correctBasePos.y, correctBasePos.z),
                    dir = sm.vec3.new(correctBaseDir.x, correctBaseDir.y, correctBaseDir.z),
                    dt = dtt
                }
                sm.camera.setCameraState(3)
                sm.camera.setFov(45)
            else
                self.ready.dt = self.ready.dt + dtt / 35
                dtt = self.ready.dt
            end
            self.ready.pos.x = sm.util.lerp(self.ready.pos.x, correctBasePos.x + pdiff.x, dtt)
            self.ready.pos.y = sm.util.lerp(self.ready.pos.y, correctBasePos.y + pdiff.y, dtt)
            self.ready.pos.z = sm.util.lerp(self.ready.pos.z, correctBasePos.z + pdiff.z, dtt)
            self.ready.dir.x = sm.util.lerp(self.ready.dir.x, correctBaseDir.x + ddiff.x, dtt)
            self.ready.dir.y = sm.util.lerp(self.ready.dir.y, correctBaseDir.y + ddiff.y, dtt)
            self.ready.dir.z = sm.util.lerp(self.ready.dir.z, correctBaseDir.z + ddiff.z, dtt)
            sm.camera.setPosition(self.ready.pos)
            sm.camera.setDirection(self.ready.dir)
            local posa = FloorVec(self.ready.pos, 1)
            local posb = FloorVec(correctBasePos + pdiff, 1)
            if posa == posb then
                self.ready = false
                self.MenuInstance.blur.remove_last = nil
                sm.camera.setPosition(correctBasePos + pdiff)
                sm.camera.setDirection(correctBaseDir + ddiff)
                self.MenuInstance.blur.gui =
                    sm.gui.createGuiFromLayout(
                    "$CONTENT_a65c170c-ede3-4757-9f1a-586eabf1a2bc/Gui/Layouts/darken/darken.layout",
                    true,
                    {
                        isHud = true,
                        isInteractive = false,
                        needsCursor = true,
                        hidesHotbar = true,
                        isOverlapped = true,
                        backgroundAlpha = 0
                    }
                )
                self.MenuInstance.blur.gui:open()
            else
                if sm.exists(self.MenuInstance.blur.gui) then
                    self.MenuInstance.blur.gui:close()
                end
                if not self.MenuInstance.blur.blur_gui:isActive() then
                    self.MenuInstance.blur.blur_gui:open()
                end
                if self.MenuInstance.blur.remove_last ~= nil then
                    self.MenuInstance.blur.blur_gui:setVisible("blur_box_" .. self.MenuInstance.blur.remove_last, false)
                else
                    self.MenuInstance.blur.blur_gui:setVisible("blur_box_1_00", false)
                end
                local e = 1 - (((posa - posb) / (correctBasePos + pdiff + sm.vec3.new(1, 0, 0))):length() * (4 / 3))
                local alpha = string.gsub(string.format("%.2f", e), "%.", "_")
                self.MenuInstance.blur.blur_gui:setVisible("blur_box_" .. alpha, true)
                self.MenuInstance.blur.remove_last = alpha
            end
        end
    end
    if self.inverse_camera_interpolate and sm.isHost then
        if sm.exists(self.MenuInstance.blur.gui) then
            self.MenuInstance.blur.gui:close()
            self.MenuInstance.blur.gui:destroy()
        end
        self.ready = nil
        local dtt = deltaTime
        if self.inverse_camera_interpolate == true then
            self.inverse_camera_interpolate = {pos = sm.camera.getPosition(), dir = sm.camera.getDirection(), dt = dtt}
            sm.camera.setCameraState(3)
            sm.camera.setFov(45)
        else
            self.inverse_camera_interpolate.dt = self.inverse_camera_interpolate.dt + dtt / 15
            dtt = self.inverse_camera_interpolate.dt
        end
        self.inverse_camera_interpolate.pos.x =
            sm.util.lerp(self.inverse_camera_interpolate.pos.x, correctBasePos.x, dtt)
        self.inverse_camera_interpolate.pos.y =
            sm.util.lerp(self.inverse_camera_interpolate.pos.y, correctBasePos.y, dtt)
        self.inverse_camera_interpolate.pos.z =
            sm.util.lerp(self.inverse_camera_interpolate.pos.z, correctBasePos.z, dtt)
        self.inverse_camera_interpolate.dir.x =
            sm.util.lerp(self.inverse_camera_interpolate.dir.x, correctBaseDir.x, dtt)
        self.inverse_camera_interpolate.dir.y =
            sm.util.lerp(self.inverse_camera_interpolate.dir.y, correctBaseDir.y, dtt)
        self.inverse_camera_interpolate.dir.z =
            sm.util.lerp(self.inverse_camera_interpolate.dir.z, correctBaseDir.z, dtt)
        sm.camera.setPosition(self.inverse_camera_interpolate.pos)
        sm.camera.setDirection(self.inverse_camera_interpolate.dir)
        local posa = FloorVec(self.inverse_camera_interpolate.pos, 3)
        local posb = FloorVec(correctBasePos, 3)
        if posa == posb then
            --self.MenuInstance.blur.blur_gui:close()
            self.inverse_camera_interpolate = false
            self.MenuInstance.blur.gui =
                sm.gui.createGuiFromLayout(
                "$CONTENT_a65c170c-ede3-4757-9f1a-586eabf1a2bc/Gui/Layouts/__invis.layout",
                false,
                {
                    isHud = true,
                    isInteractive = false,
                    needsCursor = false,
                    hidesHotbar = true,
                    isOverlapped = true,
                    backgroundAlpha = 0
                }
            )
            self.MenuInstance.blur.gui:open()
            self.MenuInstance.blur.remove_last = nil
            sm.camera.setPosition(correctBasePos)
            sm.camera.setDirection(correctBaseDir)
        else
            if not self.MenuInstance.blur.blur_gui:isActive() then
                self.MenuInstance.blur.blur_gui:open()
            end
            if self.MenuInstance.blur.remove_last ~= nil then
                self.MenuInstance.blur.blur_gui:setVisible("blur_box_" .. self.MenuInstance.blur.remove_last, false)
            else
                self.MenuInstance.blur.blur_gui:setVisible("blur_box_1_00", false)
            end
            local e = ((posa - posb) / (correctBasePos + pdiff + sm.vec3.new(1, 0, 0))):length() * (4 / 3)
            local alpha = string.gsub(string.format("%.2f", e), "%.", "_")
            self.MenuInstance.blur.blur_gui:setVisible("blur_box_" .. alpha, true)
            self.MenuInstance.blur.remove_last = alpha
        end
    end
end

function Game.server_onDestroy(self)
    if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
        ChallengeGame.server_onDestroy(ChallengeGame)
    end
end

function Game.client_onDestroy(self)
    if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
        ChallengeGame.client_onDestroy(ChallengeGame)
    end
end

function Game.server_onRefresh(self)
    if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
        ChallengeGame.server_onRefresh(ChallengeGame)
    end
end

function Game.client_onRefresh(self)
    if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
    --ChallengeGame.client_onRefresh( ChallengeGame )
    end
end

function Game._server_onReset(self)
    if self.state == States.Play or self.state == States.PlayBuild then
        ChallengeGame.network = self.network
        ChallengeGame.server_onReset(ChallengeGame)
    end
end

function Game._server_onRestart(self)
    if self.state == States.Play or self.state == States.PlayBuild then
        ChallengeGame.network = self.network
        ChallengeGame.server_onRestart(ChallengeGame)
    end
end

function Game._server_onSaveLevel(self)
    if self.state == States.Build then
        ChallengeGame.server_onSaveLevel(ChallengeGame)
    end
end

function Game._server_onTestLevel(self)
    if self.state == States.Build then
        self:server_updateGameState(States.PlayBuild)
        ChallengeGame.server_onTestLevel(ChallengeGame)
    end
end

function Game._server_onStopTest(self)
    if self.state == States.PlayBuild then
        self:server_updateGameState(States.Build)
        for _, player in pairs(sm.player.getAllPlayers()) do
            sm.event.sendToPlayer(player, "server_updateGameRules", nil)
        end
        ChallengeGame.server_onStopTest(ChallengeGame)
    end
end

function Game._client_onDestroy(self)
    if ChallengeGame.HUD ~= nil then
        ChallengeGame.HUD:close()
        ChallengeGame.HUD:destroy()
        ChallengeGame.HUD = nil
    end
    if ChallengeGame.messageGui ~= nil then
        ChallengeGame.messageGui:close()
        ChallengeGame.messageGui:destroy()
        ChallengeGame.messageGui = nil
    end
end

function Game.server_closeGui(self)
    ChallengeGame.server_closeGui(ChallengeGame)
end

function Game.client_onFixedUpdate(self, timeStep)
    --if not self.player_script_loaded and not sm.isHost then
    --    self.player_script_loaded = _G.sm.load_player_script()
    --    return
    --end
    local isAnyMenu = false
    if not self.has_client_init_once then
        self.has_client_init_once = true
        print("Modded Challenge Mode Version - 1.14.2")
    end
    if self.failed_tracker == nil then
        self.failed_tracker = 0
    end
    if self.state == States.PackMenu and sm.isHost then
        isAnyMenu = true
        if sm.exists(self.MenuInstance.pack.gui) then
            if not self.MenuInstance.pack.gui:isActive() then
                self.MenuInstance.pack.gui:open()
                self.failed_tracker = self.failed_tracker + 1
                if self.failed_tracker > 20 then
                    if ChallengeGame.messageGui then
                        ChallengeGame.messageGui:close()
                    end
                --print(self.MenuInstance.pack.gui:isActive())
                --self:client_initializePackMenu(true)
                --self.failed_tracker = 0
                end
            else
                self.failed_tracker = 0
            end
        elseif self.inverse_camera_interpolate == nil then
            self.inverse_camera_interpolate = true

            --self:client_initializePackMenu(true)
        end
    elseif self.state == States.BuildMenu and sm.isHost then
        isAnyMenu = true
        if sm.exists(self.MenuInstance.build.gui) then
            if not self.MenuInstance.build.gui:isActive() then
                --self.failed_tracker = self.failed_tracker + 1
                self.MenuInstance.build.gui:open()
            else
                self.failed_tracker = 0
            end
        else
            --self:client_initializePlayMenu(true)
            sm.event.sendToGame("client_initializeBuildMenu", true)
        end
    elseif self.state == States.PlayMenu and sm.isHost then
        isAnyMenu = true
        if sm.exists(self.MenuInstance.play.gui) then
            if not self.MenuInstance.play.gui:isActive() then
                --self.failed_tracker = self.failed_tracker + 1
                self.MenuInstance.play.gui:open()
            else
                self.failed_tracker = 0
            end
        else
            --self:client_initializePlayMenu(true)
            sm.event.sendToGame("client_initializePlayMenu", true)
        end
    end
end

function Game.client_onClientDataUpdate(self, data, channel)
    if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
        ChallengeGame.client_onClientDataUpdate(ChallengeGame)
    end
end

function Game.server_onNextPressed(self, params)
    if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
        ChallengeGame.server_onNextPressed(ChallengeGame, params)
    end
end

function Game.server_onResetPressed(self, data)
    if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
        ChallengeGame.network = self.network
        ChallengeGame.server_onResetPressed(ChallengeGame, data)
    end
end

function Game.server_onFinishPressed(self, params)
    if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
        ChallengeGame.server_onFinishPressed(ChallengeGame, params)
    end
end

function Game.server_start(self, player)
    if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
        ChallengeGame.server_start(ChallengeGame)
    end
end

function Game.server_onPlayerLeft(self, player)
    if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
    --ChallengeGame.server_onPlayerLeft( ChallengeGame )
    end
end

function Game.server_onReset(self)
    if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
        ChallengeGame.network = self.network
        ChallengeGame.server_onReset(ChallengeGame)
    end
end

function Game.server_onRestart(self)
    if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
        ChallengeGame.server_onRestart(ChallengeGame)
    end
end

function Game.server_onSaveLevel(self)
    if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
        ChallengeGame.server_onSaveLevel(ChallengeGame)
    end
end

function Game.server_onTestLevel(self)
    if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
        ChallengeGame.server_onTestLevel(ChallengeGame)
    end
end

function Game.server_onStopTest(self)
    if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
        ChallengeGame.server_onStopTest(ChallengeGame)
    end
end

function Game.client_onLoadingScreenLifted(self)
    self.loading_screen_lifted = true
    sm.event.sendToPlayer(sm.localPlayer.getPlayer(), "_client_onLoadingScreenLifted")
    if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
        ChallengeGame.client_onLoadingScreenLifted(ChallengeGame)
    end
end

function Game.sv_loadVictoryLevel(self)
    if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
        ChallengeGame.sv_loadVictoryLevel(ChallengeGame)
    end
end

function Game.client_onLanguageChange(self, language)
    if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
        ChallengeGame.client_onLanguageChange(ChallengeGame)
    end
end

function Game.server_loadLevel(self, loadJsonData, loadSaveData)
    if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
        ChallengeGame.server_loadLevel(ChallengeGame, loadJsonData, loadSaveData)
    end
end

function Game.server_loadJsonData(self, language)
    if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
        ChallengeGame.server_loadJsonData(ChallengeGame)
    end
end

function Game.server_loadSaveData(self, language)
    if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
        ChallengeGame.server_loadSaveData(ChallengeGame)
    end
end
