SpectateBlock = class()

local Controls = {
    W = 3,
    S = 4,
    A = 1,
    D = 2,
    Mouse1 = 19,
    Mouse2 = 18,
}

local Modes = {
    Free = 1,
    Follow = 2
}

function SpectateBlock.server_onCreate( self )

end

function SpectateBlock.client_onCreate( self )
    self.edown = false
    self.wdown = false
    self.sdown = false
    self.adown = false
    self.ddown = false
    self.spectateIndex = 0
    self.mode = Modes.Follow
end

function SpectateBlock.client_bindPlayer( self, player )
    self.player = player
    if player:getCharacter() then
        sm.camera.setCameraState(2)
        player.character:setLockingInteractable(self.interactable)
    end
end

function SpectateBlock.client_unBindPlayer( self, player )
    self.player = nil
    if player:getCharacter() then
        sm.camera.setCameraState(sm.camera.default)
        player.character:setLockingInteractable(nil)
    end
end

function SpectateBlock.client_unbindAll( self, players )
    for _,player in pairs(players) do
        if player and player:getCharacter()
            and player.character:getLockingInteractable() then
                player.character:setLockingInteractable(nil)
        end
    end
end

function SpectateBlock.client_onUpdate( self, deltaTime )
    if self.mode == Modes.Follow then
        if self.target then       
            sm.camera.setPosition(self.target.character.worldPosition)
        end
    else
        self.target = nil
    end
end

function SpectateBlock.client_onAction( self, input, active )

    if active then
        local players = sm.player.getAllPlayers()

        if input == Controls.W then self.wdown = true end 
        if input == Controls.S then self.sdown = true end
        if input == Controls.A then self.adown = true end
        if input == Controls.D then self.ddown = true end

        if #players > 1 then
            if input == Controls.Mouse1 then
                self.spectateIndex = self.spectateIndex + 1
                ::M1Check::
                if self.spectateIndex > #players - 1 then
                    self.spectateIndex = 0
                end

                self.target = players[self.spectateIndex+1]
                if self.target == sm.localPlayer.getPlayer() then
                    self.spectateIndex = self.spectateIndex + 1
                    goto M1Check
                end
            elseif input == Controls.Mouse2 then

                self.spectateIndex = self.spectateIndex - 1
                ::M2Check::
                if self.spectateIndex < 0 then
                    self.spectateIndex = #players - 1
                end

                self.target = players[self.spectateIndex+1]
                if self.target == sm.localPlayer.getPlayer() then
                    self.spectateIndex = self.spectateIndex - 1
                    goto M2Check
                end
            end
        end
    else
        if input == Controls.W then self.wdown = false end 
        if input == Controls.S then self.sdown = false end
        if input == Controls.A then self.adown = false end
        if input == Controls.D then self.ddown = false end
    end

    print(self.wdown, self.sdown, self.adown, self.ddown)
    print(self.spectateIndex)

    return true
end