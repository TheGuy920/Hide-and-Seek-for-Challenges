_G["ChallengeBuilder_LoadFunctions"] = function(self)
    print("Loaded Player Functions")

    self.ChallengeBuilder_LOADED = function(self, start, force)
        self.selected_index = 0
        local init = false
        if self.number_index == nil or force == true then
            self.number_index = {}
            self.times = {}
            init = true
        end

        if init then
            for _, level in pairs(self.challenge_levels) do
                if level.isLocal or not self.toggle then
                    table.insert(self.number_index, level)
                end
            end
        end
        table.sort(
            self.number_index,
            function(a, b)
                return a.uuid < b.uuid
            end
        )
        local index = 0
        local local_max = 23
        local _max = #self.number_index - local_max
        self.offset = max(min(start, _max), 0)
        if self.offset == 4 then self.offset = 5 end
        for index,level in pairs(self.number_index) do
            if index >= self.offset and self.selected_index <= local_max then
                self.gui:setVisible("ChallengeItem_" .. self.selected_index, true)
                self.gui:setImage("Preview_" .. (self.selected_index - (self.offset > 0 and 1 or 0)), level.image .. "")
                self.gui:setVisible("PreviewSelectBorder_" .. self.selected_index, false)
                self.gui:setVisible("SelectBorder_" .. self.selected_index, false)
                self.gui:setButtonCallback("Challenge_" .. self.selected_index, "client_level_SelectChallenge")
                self.selected_index = self.selected_index + 1
            end
        end
        if #self.number_index < local_max then
            local diff = local_max - #self.number_index + 1
            for i = local_max, #self.number_index, -1 do
                self.gui:setVisible("ChallengeItem_"..tostring(i), false)
            end
        end
        _max = #self.number_index - local_max
        if self.offset == _max then
            self.gui:setVisible("ChallengeItem_19", false)
            self.gui:setVisible("ChallengeItem_20", false)
            self.gui:setVisible("ChallengeItem_21", false)
            self.gui:setVisible("ChallengeItem_22", false)
            self.gui:setVisible("DownIcon", false)
            self.gui:setVisible("No_DownIcon", true)
        else
            if _max + local_max > 20 then
                self.gui:setVisible("ChallengeItem_19", true)
            end
            if _max + local_max > 21 then
                self.gui:setVisible("ChallengeItem_20", true)
            end
            if _max + local_max > 22 then
                self.gui:setVisible("ChallengeItem_21", true)
            end
            if _max + local_max > 23 then
                self.gui:setVisible("ChallengeItem_22", true)
            end
            if _max + local_max > 24 then
                self.gui:setVisible("DownIcon", true)
                self.gui:setVisible("No_DownIcon", false)
            else
                self.gui:setVisible("DownIcon", false)
                self.gui:setVisible("No_DownIcon", true)
            end
        end
        if self.offset >= 2 then
            self.gui:setVisible("UpIcon", true)
            self.gui:setVisible("No_UpIcon", false)
        else
            self.gui:setVisible("UpIcon", false)
            self.gui:setVisible("No_UpIcon", true)
        end

        self.gui:setButtonCallback("ChallengeNew", "client_level_NewChallenge")
        self.gui:setButtonCallback("ChallengeModeMenuPack", "client_level_OpenGui")
        self.gui:setVisible("BackgroundPlateSelected", false)
        self.gui:open()
    end

    self.client_loadChallengeData = function(self)
        local index = self.selected_index + 1 + self.offset
        if index > 0 and index <= #self.number_index then
            local level = self.number_index[index]
            local isLocal = level.isLocal
            local inPack = level.inPack
            local uuid = tostring(level.uuid)
            local dir = tostring(level.directory)
            local json_object = self:client_readFile(uuid, dir, inPack, isLocal)
            self.gui:setText("EditText_Title", json_object.name)
            if #json_object.name > 0 then
                self.gui:setVisible("DefaultText_Title", false)
            else
                self.gui:setVisible("DefaultText_Title", true)
            end
            self.gui:setText("EditText_Description", json_object.description)
            if #json_object.description > 0 then
                self.gui:setVisible("DefaultText_Description", false)
            else
                self.gui:setVisible("DefaultText_Description", true)
            end
            self.gui:setVisible("ChallengeIcon", true)
            self.gui:setImage("ChallengeIcon", self.number_index[index].image .. "")

            if not self.times[uuid] then
                self.network:sendToServer("server_fetchLevelData", uuid)
            else
                if self.times[uuid] > 0 then
                    self.gui:setVisible("RecordContainer", true)
                    self.gui:setVisible("HaveToBeatText", false)
                    self.gui:setVisible("HaveToBeatText2", false)
                    local passedTime = self.times[uuid]
                    local milliseconds = passedTime % 1.0
                    local seconds = (passedTime - milliseconds) % 60.0
                    local minutes = (passedTime - (seconds + milliseconds)) / 60
                    displayTime = string.format("%02i:%02i:%03i", minutes, seconds, milliseconds * 1000)
                    self.gui:setText("RecordTime", displayTime)
                else
                    self.gui:setVisible("RecordContainer", false)
                    self.gui:setVisible("HaveToBeatText", true)
                    self.gui:setVisible("HaveToBeatText2", true)
                end
            end
        else
            self.gui:setText("EditText_Title", "")
            self.gui:setVisible("DefaultText_Title", true)
            self.gui:setText("EditText_Description", "")
            self.gui:setVisible("DefaultText_Description", true)
            self.gui:setVisible("ChallengeIcon", false)
        end
    end

    self.client_toggleShowing = function ( self )
        self.toggle = not self.toggle
        if self.toggle then
            self.gui:setText("Toggle", "LOCAL")
        else
            self.gui:setText("Toggle", "ALL")
        end
        self.ChallengeBuilder_LOADED(self, self.offset, true)
    end

    self.client_recieveLevelTimes = function( self, table )
        for uuid,time in pairs(table) do
            if not self.times[uuid] then
                self.times[uuid] = time
            end
        end
        self:client_loadChallengeData() 
    end

    self.client_readFile = function(self, uuid, dir, inPack, isLocal)
        if inPack then
            for _, level in pairs(sm.json.open(dir .. "/challengePack.json", isLocal).levelList) do
                if level.uuid == uuid then
                    return level
                end
            end
        else
            return sm.json.open("$CONTENT_" .. uuid .. "/description.json", isLocal)
        end
    end

    self.client_saveFile = function(self, new, uuid, dir, inPack, isLocal)
        sm.challenge.setChallengeUuid(string.sub(dir, 10))
        local data
        if inPack then
            data = sm.json.open(dir .. "/challengePack.json", isLocal)
        else
            data = sm.json.open("$CONTENT_" .. uuid .. "/description.json", isLocal)
        end
        if inPack then
            for _, level in pairs(data.levelList) do
                if level.uuid == uuid then
                    data.levelList[_] = new
                    break
                end
            end
            sm.json.save(data, dir .. "/challengePack.json", isLocal)
        else
            sm.json.save(data, "$CONTENT_" .. uuid .. "/description.json", isLocal)
        end
    end

    self.client_saveDescriptionCurrent = function(self, description)
        local index = self.selected_index + 1 + self.offset
        if index > 0 and index <= #self.number_index then
            local level = self.number_index[index]
            local isLocal = level.isLocal
            local inPack = level.inPack
            local uuid = tostring(level.uuid)
            local dir = tostring(level.directory)
            local json_object = self:client_readFile(uuid, dir, inPack, isLocal)
            json_object.description = description
            self:client_saveFile(json_object, uuid, dir, inPack, isLocal)
        end
    end

    self.client_saveTitleCurrent = function(self, title)
        local index = self.selected_index + 1 + self.offset
        if index >= 0 and index <= #self.number_index then
            local level = self.number_index[index]
            local isLocal = level.isLocal
            local inPack = level.inPack
            local uuid = tostring(level.uuid)
            local dir = tostring(level.directory)
            local json_object = self:client_readFile(uuid, dir, inPack, isLocal)
            json_object.name = title
            self:client_saveFile(json_object, uuid, dir, inPack, isLocal)
        end
    end

    self.client_ChangeDescription = function(self, button, text)
        self:client_saveDescriptionCurrent(text)
        if #text > 0 then
            self.gui:setVisible("DefaultText_Description", false)
        else
            self.gui:setVisible("DefaultText_Description", true)
        end
    end

    self.client_ChangeTitle = function(self, button, text)
        self:client_saveTitleCurrent(text)
        if #text > 0 then
            self.gui:setVisible("DefaultText_Title", false)
        else
            self.gui:setVisible("DefaultText_Title", true)
        end
    end

    self.client_DeselectAll = function(self)
        self.gui:setVisible("BackgroundPlateSelected", false)
        for _ in pairs(self.number_index) do
            self.gui:setVisible("PreviewSelectBorder_" .. (_ - 1), false)
        end
    end

    self.client_SelectChallenge = function(self, button)
        self:client_DeselectAll()
        self.selected_index = string.gsub(string.sub(button, -2), "_", "")
        self.gui:setVisible("PreviewSelectBorder_" .. self.selected_index, true)
        self:client_loadChallengeData()
    end

    self.client_NewChallenge = function(self, button)
        self:client_DeselectAll()
        self.selected_index = -2
        self:client_loadChallengeData()
        self.gui:setVisible("BackgroundPlateSelected", true)
    end

    self.client_PlayChallenge = function(self, button)
        local index = self.selected_index + 1 + self.offset
        
        if index >= 0 and index < #self.number_index then
            local uuid = self.number_index[index].uuid
            sm.event.sendToGame("client_PlayBuild", uuid)
        end
    end

    self.client_BuildChallenge = function(self, button)
        local index = self.selected_index + 1 + self.offset
        if index >= 0 and index <= #self.number_index then
            local uuid = self.number_index[index].uuid
            print(uuid)
            sm.event.sendToGame("client_LoadBuild", uuid)
        end
    end

    self.client_AddChallenge = function(self, button)
        print(button)
    end
end

_G["ChallengeBuilder_UnLoadFunctions"] = function(self)
    self.client_AddChallenge = nil
    self.client_BuildChallenge = nil
    self.client_PlayChallenge = nil
    self.client_NewChallenge = nil
    self.client_SelectChallenge = nil
    self.client_DeselectAll = nil
    self.client_ChangeTitle = nil
    self.client_ChangeDescription = nil
    self.client_saveFile = nil
    self.client_readFile = nil
    self.client_loadChallengeData = nil
    self.ChallengeBuilder_LOADED = nil
    self.client_setImage = nil
    self.server_getPath = nil
    self.client_OpenGui = nil
    print("Unloaded Player Functions")
end
