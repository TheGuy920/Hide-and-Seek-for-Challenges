if _G["ChallengeModeMenuPlay_LoadFunctions"] == nil then
    _G["ChallengeModeMenuPlay_LoadFunctions"] = function( self )

        print("Loaded Player Functions Play")

        self.ChallengeModeMenuPlay_LOADED = function( self, start, force )
            self.selected_index = 0
            local init = false

            local local_max = 18
            local _max = #self.challenge_levels - local_max
            self.offset = max(min(start, _max), 0)

            if self.offset == _max then
                self.gui:setVisible("ChallengePlay_18", false)
                self.gui:setVisible("ChallengePlay_19", false)
                self.gui:setVisible("ChallengePlay_20", false)
                self.gui:setVisible("DownIcon", false)
                self.gui:setVisible("No_DownIcon", true)
            else
                
                if _max + local_max > 18 then self.gui:setVisible("ChallengePlay_18", true) end
                if _max + local_max > 19 then self.gui:setVisible("ChallengePlay_19", true) end
                if _max + local_max > 20 then self.gui:setVisible("ChallengePlay_20", true) end
                if _max + local_max > 21 then
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

            if sm.exists(self.gui) then
                for _,challenge in pairs(self.challenge_levels) do
                    local index = _ - 1
                    if index > self.offset + 21 then break end
                    if index >= self.offset and self.selected_index <= local_max + 2 then
                        local data = sm.json.open("$CONTENT_"..self.uuid.."/description.json")
                        self.gui:setText("Name_"..self.selected_index, challenge.name)
                        if data.fileId == nil then self.gui:setVisible("ModIcon_"..self.selected_index, false) end
                        self.gui:setVisible("ChallengePlay_"..self.selected_index, true)
                        self.gui:setImage("Preview_"..self.selected_index, challenge.image)
                        self.gui:setVisible("PreviewSelectBorder_"..self.selected_index, false)
                        self.gui:setVisible("SelectBorder_"..self.selected_index, false)
                        self.gui:setButtonCallback( "ChallengeButton_"..self.selected_index, "client_play_SelectChallenge" )
                        self.selected_index = self.selected_index + 1
                    end
                end
                self.gui:setVisible("RecordContainer", false)
                self.gui:setText("ChallengeName", "")
                self.gui:open()
            end

            self.network:sendToServer("server_fetchLevelData", self.uuid)
        end

        self.client_recieveLevelTimes = function( self, times )
            self.times = times
            local completed = 0
            local total = 0
            for _,time in pairs(times) do
                if time > 0 then completed = completed + 1 end
                total = total + 1
            end
            self.gui:setText("RightValue", tostring(total))
            self.gui:setText("LeftValue", tostring(completed))
        end

        self.client_SelectChallenge = function( self, button )
            self:client_DeselectAll()
            self.selected_index = string.gsub(string.sub(button, -2), "_", "")
            self.gui:setVisible("PreviewSelectBorder_"..self.selected_index, true)
            self.gui:setVisible("SelectBorder_"..self.selected_index, true)
            local level = self.challenge_levels[self.offset + self.selected_index + 1]
            self.gui:setVisible("RecordContainer", true)
            self.gui:setText("ChallengeName", level.name)
            if self.times then
                local passedTime = self.times[level.uuid]
                local milliseconds = passedTime % 1.0
                local seconds = (passedTime - milliseconds) % 60.0
                local minutes = (passedTime - (seconds + milliseconds)) / 60
                displayTime = string.format("%02i:%02i:%03i", minutes, seconds, milliseconds * 1000)
                self.gui:setText("RecordTime", displayTime)
            end
            --self.gui:setText("RecordTimeLabel", "#{PLAYTIME}")
        end

        self.client_DeselectAll = function( self )
            local _ = 1
            for uuid,challenge in pairs(self.challenge_levels) do
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
    end
end