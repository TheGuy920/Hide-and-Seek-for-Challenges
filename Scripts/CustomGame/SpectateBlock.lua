SpectateBlock = class()

local Controls = {
    W = 3,
    S = 4,
    A = 1,
    D = 2,
    One = 5,
    Mouse1 = 19,
    Mouse2 = 18,
    ScrollUp = 20,
    ScrollDown = 21
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
    self.zoom = 0
end

function SpectateBlock.client_bindPlayer( self, player )
    self.player = player
    if player:getCharacter() then
        sm.camera.setCameraState(sm.camera.state.cutsceneTP)
        player.character:setLockingInteractable(self.interactable)
        local players = sm.player.getAllPlayers()

        self:client_findAvailablePlayer()
    end
end

function SpectateBlock.client_findAvailablePlayer( self )
    local players = sm.player.getAllPlayers()

    ::SCheck::
    if self.spectateIndex > #players - 1 then
        self.spectateIndex = 0
    end

    self.target = players[self.spectateIndex+1]
    if self.target == sm.localPlayer.getPlayer() then
        self.spectateIndex = self.spectateIndex + 1
        goto SCheck
    end

end

function SpectateBlock.client_unBindPlayer( self, player )
    self.player = nil
    if player:getCharacter() then
        sm.camera.setCameraState(sm.camera.state.cutsceneFP)
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
        if self.target and self.target.character then
            local pos = self.target.character:getWorldPosition()
            if not self.camera_pos then
                self.camera_pos = pos + sm.vec3.new(0,0,1)
            end
            local deltaX, deltaY = sm.localPlayer.getMouseDelta()
            local dir = (self.camera_pos - pos):normalize()
            
            -- Define orbit distance if not already defined
            local orbitDistance = dir:length() + self.zoom

            -- Convert direction to spherical coordinates (theta, phi)
            local r = dir:length()
            local theta = math.atan2(dir.y, dir.x)
            local phi = math.acos(dir.z / r)

            -- Adjust theta and phi based on mouse movement
            -- sensitivity factors should be adjusted as needed
            theta = theta - deltaX * -3
            phi = math.max(0.1, math.min(math.pi - 0.1, phi - deltaY * -3))

            -- Convert back to Cartesian coordinates
            dir.x = r * math.sin(phi) * math.cos(theta)
            dir.y = r * math.sin(phi) * math.sin(theta)
            dir.z = r * math.cos(phi)

            -- Ensure the camera maintains the orbit distance
            dir = dir:normalize() * orbitDistance

            -- Update camera position
            self.camera_pos = pos + dir

            -- Update camera position
            self.camera_pos = pos + dir
            
            -- Set camera position and direction
            local old = sm.camera.getPosition()
            local oldd = sm.camera.getDirection()
            local fpos = self.camera_pos + sm.vec3.new(0,0,0.5) + self.target:getCharacter():getVelocity() * 0.025
            sm.camera.setPosition(magicPositionInterpolation(old, fpos, deltaTime, 1))
            sm.camera.setDirection(magicPositionInterpolation(oldd, -dir, deltaTime, 1))
        end
    elseif self.mode == Modes.Free and self.player then
        self.target = nil

        if self.wdown then
            self.camera_pos = self.camera_pos + sm.camera.getDirection() * deltaTime * 10
        end
        if self.sdown then
            self.camera_pos = self.camera_pos - sm.camera.getDirection() * deltaTime * 10
        end
        if self.adown then
            self.camera_pos = self.camera_pos - sm.camera.getRight() * deltaTime * 10
        end
        if self.ddown then
            self.camera_pos = self.camera_pos + sm.camera.getRight() * deltaTime * 10
        end

        local old = sm.camera.getPosition()
        local oldd = sm.camera.getDirection()
        sm.camera.setPosition(magicPositionInterpolation(old, self.camera_pos, deltaTime, 1))
        sm.camera.setDirection(magicPositionInterpolation(oldd, self.player.character:getDirection(), deltaTime, 1))
    end
end

function SpectateBlock.client_onAction( self, input, active )

    if active then
        local players = sm.player.getAllPlayers()

        if input == Controls.W then self.wdown = true end 
        if input == Controls.S then self.sdown = true end
        if input == Controls.A then self.adown = true end
        if input == Controls.D then self.ddown = true end

        if input == Controls.One then
            if self.mode == Modes.Follow then
                self.mode = Modes.Free
            else
                self.mode = Modes.Follow
                self:client_findAvailablePlayer()
            end
        end

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

    if input == Controls.ScrollUp and active then
        self.zoom = math.max(self.zoom - 0.5, 0.15)
    elseif input == Controls.ScrollDown and active then
        self.zoom = math.min(self.zoom + 0.5, 20)
    end

    if input == 15 then
        self:client_unBindPlayer(self.player)
    end

    print(input)

    return true
end