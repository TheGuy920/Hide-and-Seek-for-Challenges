if _G["ChallengeModeMenuPack_LoadFunctions"] == nil then
    _G["ChallengeModeMenuPack_LoadFunctions"] = function( self )

        print("Loaded Player Functions Pack")

        self.ChallengeModeMenuPack_LOADED = function( self, start, force )
            self.selected_index = 0
            local init = false
            if self.number_index == nil or force == true then self.number_index = {} init = true end

            local local_max = 11
            --local uuid_list = {}--sm.json.open("$CHALLENGE_DATA/LocalChallengeList.json").challenges
            --for _,c in pairs(sm.json.open("$CONTENT_e3589ff7-31ca-4f19-b1f0-bef055ba9200/ChallengeList.json").challenges) do table.insert(uuid_list, c) end
            local uuid_list =sm.json.open("$CONTENT_e3589ff7-31ca-4f19-b1f0-bef055ba9200/ChallengeList.json").challenges
            local _max = #self.number_index - local_max
            self.offset = max(min(start, _max), 0)
            local index = 0
            if sm.exists(self.gui) then
                for _,uuid in pairs(uuid_list) do
                    if self.challenge_packs[uuid] ~= nil then
                        local challenge = self.challenge_packs[uuid]
                        if init then table.insert(self.number_index, challenge) end
                        if index >= self.offset and self.selected_index <= local_max + 1 then
                            local data = sm.json.open("$CONTENT_"..challenge.uuid.."/description.json")
                            self.gui:setText("Name_"..self.selected_index, data.name)
                            local author = data.fileId ~= nil and data.fileId or "Author not supported"
                            self.gui:setText("ByLine_"..self.selected_index, author.."")
                            if data.fileId == nil then
                                self.gui:setVisible("ModIcon_"..self.selected_index, false)
                            else
                                self.gui:setVisible("ModIcon_"..self.selected_index, true)
                            end
                            self.gui:setVisible("ChallengePack_"..self.selected_index, true)
                            self.gui:setImage("Preview_"..self.selected_index, challenge.image)
                            self.gui:setVisible("PreviewSelectBorder_"..self.selected_index, false)
                            self.gui:setVisible("SelectBorder_"..self.selected_index, false)
                            if self.times and self.times[challenge.uuid] then
                                local completed = 0
                                level_times = self.times[challenge.uuid]
                                for _,time in pairs(level_times) do if time > 0 then completed = completed + 1 end end
                                self.gui:setText("LeftValue_"..self.selected_index, tostring(completed))
                            end
                            self.gui:setText("RightValue_"..self.selected_index, ""..#challenge.levelList)
                            self.gui:setButtonCallback( "ChallengeButton_"..self.selected_index, "client_pack_SelectChallenge" )
                            self.selected_index = self.selected_index + 1
                        end
                        index = index + 1
                    end
                end
                _max = #self.number_index - local_max
                if self.offset >= _max then
                    self.gui:setVisible("ChallengePack_10", false)
                    self.gui:setVisible("ChallengePack_11", false)
                    self.gui:setVisible("DownIcon", false)
                    self.gui:setVisible("No_DownIcon", true)
                else
                    if _max + local_max > 8 then self.gui:setVisible("ChallengePack_10", true) end
                    if _max + local_max > 9 then self.gui:setVisible("ChallengePack_11", true) end
                    if _max + local_max > 10 then
                        self.gui:setVisible("DownIcon", true)
                        self.gui:setVisible("No_DownIcon", false)
                    else
                        self.gui:setVisible("DownIcon", false)
                        self.gui:setVisible("No_DownIcon", true)
                    end
                end
                if self.offset > 0 then
                    self.gui:setVisible("UpIcon", true)
                    self.gui:setVisible("No_UpIcon", false)
                else
                    self.gui:setVisible("UpIcon", false)
                    self.gui:setVisible("No_UpIcon", true)
                end
                self.gui:open()
            end
            self.selected_index = -2

            if self.times == nil or force then
                self.network:sendToServer("server_fetchLevelData", {})
            end
        end

        self.client_recieveLevelTimes = function( self, times )
            self.times = times
            self.ChallengeModeMenuPack_LOADED( self, self.offset, false)
        end

        self.client_SelectChallenge = function( self, button )
            self:client_DeselectAll()
            self.selected_index = string.gsub(string.sub(button, -2), "_", "")
            self.gui:setVisible("PreviewSelectBorder_"..self.selected_index, true)
            self.gui:setVisible("SelectBorder_"..self.selected_index, true)
        end

        self.client_DeselectAll = function( self )
            local _ = 1
            for uuid,challenge in pairs(self.challenge_packs) do
                self.gui:setVisible("PreviewSelectBorder_"..(_-1), false)
                self.gui:setVisible("SelectBorder_"..(_-1), false)
                _ = _ + 1
            end
        end

        self.client_CloseMenu = function( self, button )
            --sm.localPlayer.setLockedControls( false )
            self.gui:close()
            self.gui:destroy()
        end

        self.client_SelectPack = function( self, button )
            --local uuid = self.number_index[self.selected_index+1].uuid
        end

        self.client_OpenGui = function( self, button )
            --local uuid = self.challenge_packs[self.selected_index+1].uuid
            --self:client_initializePlayMenu()
        end
    end
end