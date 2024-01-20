SpectateBlock = class()

local Controls = {
    W = 3,
    S = 4,
    A = 1,
    D = 2,
    One = 5,
    Spacebar = 16,
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
    self.spacedown = false
    self.spectateIndex = 0
    self.mode = Modes.Follow
    self.zoom = 0
end

function SpectateBlock.client_bindPlayer( self, player )
    self.player = player
    if player:getCharacter() then
        self.original_pos = player:getCharacter():getWorldPosition()
        player.character:setLockingInteractable(self.interactable)
        sm.camera.setCameraState(sm.camera.state.cutsceneTP)
        self:client_findAvailablePlayer()
        self.gui = sm.gui.createGuiFromLayout('$CONTENT_DATA/Gui/Layouts/spectate.layout', false,
        {
            isHud = true,
            isInteractive = false,
            needsCursor = false,
            hidesHotbar = true,
            isOverlapped = true,
            backgroundAlpha = 0
        })
        self.gui:setText("interact", sm.gui.getKeyBinding( "Use", false ))
        self.gui:setText("cam", self.mode == Modes.Follow and "Player Cam" or "Free Cam")
        self.gui:open()
        self.camera_pos = self.original_pos + sm.vec3.new(0,0,1)
        self.network:sendToServer("server_requestMovePlayer", player)
        sm.camera.setFov( sm.camera.getDefaultFov() )
    end
end

function SpectateBlock.server_resetPosition( self, dta )
    local player = dta.player
    local pos = dta.pos
    player:getCharacter():setWorldPosition(pos)
end

function SpectateBlock.server_recieveSpectators( self, data )
    self.network:sendToClients("client_recieveSpectators", data.players)
    sm.event.sendToPlayer(data.player, "server_confirmSpectators")
end

function SpectateBlock.client_recieveSpectators( self, players )
    self.spectators = players
    self:client_findAvailablePlayer(0)
end

function SpectateBlock.client_isPlayerSpectating( self, player )
    if self.spectators then
        for _,p in pairs(self.spectators) do
            if p == player then return true end
        end
    end
    return false
end

function SpectateBlock.server_requestMovePlayer( self, player )
    local players = sm.player.getAllPlayers()
    local index = 0
    for _,p in pairs(players) do if p == player then break end index = index + 1 end
    local offset = sm.vec3.new(index, index, 0)
    -- platform
    sm.shape.createBlock(
        sm.uuid.new("5f41af56-df4c-4837-9b3c-10781335757f"),
        sm.vec3.new(3,3,1),
        sm.vec3.new(-0.25,-0.25,9999)+offset,
        sm.quat.identity(),
        false,
        true
    )
    -- N wall
    sm.shape.createBlock(
        sm.uuid.new("5f41af56-df4c-4837-9b3c-10781335757f"),
        sm.vec3.new(1,3,10),
        sm.vec3.new(-0.5,-0.25,9999)+offset,
        sm.quat.identity(),
        false,
        true
    )
    -- W wall
    sm.shape.createBlock(
        sm.uuid.new("5f41af56-df4c-4837-9b3c-10781335757f"),
        sm.vec3.new(3,1,10),
        sm.vec3.new(-0.25,-0.5,9999)+offset,
        sm.quat.identity(),
        false,
        true
    )
    -- E wall
    sm.shape.createBlock(
        sm.uuid.new("5f41af56-df4c-4837-9b3c-10781335757f"),
        sm.vec3.new(3,1,10),
        sm.vec3.new(-0.25,0.5,9999)+offset,
        sm.quat.identity(),
        false,
        true
    )
    -- S wall
    sm.shape.createBlock(
        sm.uuid.new("5f41af56-df4c-4837-9b3c-10781335757f"),
        sm.vec3.new(1,3,10),
        sm.vec3.new(0.5,-0.25,9999)+offset,
        sm.quat.identity(),
        false,
        true
    )
    player:getCharacter():setWorldPosition( sm.vec3.new(0.125,0.125,9999+1.5)+offset )
end

function SpectateBlock.client_findAvailablePlayer( self, degree )
    local players = sm.player.getAllPlayers()
    if #players > 1 and not (self.spectators and #self.spectators >= #players) then
        ::SCheck::
        if self.spectateIndex > #players - 1 then
            self.spectateIndex = 0
        end

        self.target = players[self.spectateIndex+1]
        if self.target == sm.localPlayer.getPlayer() or (self:client_isPlayerSpectating(self.target)) then
            self.spectateIndex = self.spectateIndex + degree
            goto SCheck
        end
        if self.gui then
            self.gui:setText("PlayerName", self.target:getName())
        end
    else
        if self.gui then
            self.gui:setText("cam", "Free Cam")
        end
        self.mode = Modes.Free
    end
end

function SpectateBlock.client_unBindPlayer( self, player )
    self.player = nil
    if player:getCharacter() then
        sm.camera.setCameraState(sm.camera.state.default)
        player:getCharacter():setLockingInteractable(nil)
        self.network:sendToServer("server_resetPosition", {player = player, pos = self.original_pos})
    end
    if self.gui then
        self.gui:destroy()
        self.gui = nil
    end
end

function SpectateBlock.client_unbindAll( self, players )
    for _,player in pairs(players) do
        if player and player:getCharacter()
            and player:getCharacter():getLockingInteractable() then
                player:getCharacter():setLockingInteractable(nil)
        end
    end
    if self.gui then
        self.gui:destroy()
        self.gui = nil
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
            theta = theta - deltaX * -sm.localPlayer.getAimSensitivity() * math.pi * 4/3
            phi = math.max(0.1, math.min(math.pi - 0.1, phi - deltaY * -sm.localPlayer.getAimSensitivity() * math.pi * 4/3))

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
        if self.target then
            self.target = nil
            self.gui:setText("PlayerName", "")
        end
        if not self.camera_pos then self.camera_pos = sm.camera.getPosition() end
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
        if self.spacedown then
            self.camera_pos = self.camera_pos + sm.vec3.new(0,0,1) * deltaTime * 10
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
        if input == Controls.Spacebar then self.spacedown = true end

        if input == Controls.One then
            if self.mode == Modes.Follow then
                self.mode = Modes.Free
                self.gui:setText("cam", "Free Cam")
            else
                self.mode = Modes.Follow
                self.gui:setText("cam", "Player Cam")
                self:client_findAvailablePlayer(1)
            end
        end

        if #players > 1 then
            if input == Controls.Mouse1 then
                self.spectateIndex = self.spectateIndex + 1
                if self.spectateIndex > #players - 1 then
                    self.spectateIndex = 0
                end
                self:client_findAvailablePlayer(1)
            elseif input == Controls.Mouse2 then
                self.spectateIndex = self.spectateIndex - 1
                if self.spectateIndex < 0 then
                    self.spectateIndex = #players - 1
                end
                self:client_findAvailablePlayer(-1)
            end
        end
    else
        if input == Controls.W then self.wdown = false end 
        if input == Controls.S then self.sdown = false end
        if input == Controls.A then self.adown = false end
        if input == Controls.D then self.ddown = false end
        if input == Controls.Spacebar then self.spacedown = false end
    end

    if input == Controls.ScrollUp and active then
        self.zoom = math.max(self.zoom - 0.5, 0.15)
    elseif input == Controls.ScrollDown and active then
        self.zoom = math.min(self.zoom + 0.5, 20)
    end

    if input == 15 and sm.isHost and active then
        self:client_unBindPlayer(self.player)
    end

    return true
end