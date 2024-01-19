--I labeled things to try and make it easy to understand how things work in here just in case anyone is looking around trying to figure out what makes this mod work
--I haven't added any comments to newer additions because I am being lazy, so sorry if you find something and it isn't explained. I will hopefully be adding more comments soon when I am done being lazy
--If you still have any questions or need any help, DM me on Discord at ShrooToo#1548  :)
--Also please let me know if you see anything you think I can make better
--Thanks to wingcomstriker405 for inspiration and help!
SpectateBlock = class( nil )

function SpectateBlock.client_onDestroy(self)
	SpectateBlock.cl_exitCam(self)
end

function SpectateBlock.client_onCreate(self)
	if surveillancecamera == nil then
		surveillancecamera = {};
	end
	
	SpectateBlock.cl_resetEverything(self)
	self.network:sendToServer("sv_load", sm.localPlayer.getPlayer())
end

function SpectateBlock.client_triggerInteract(self, active)
	if active then
		sm.camera.setCameraState(2)
		sm.localPlayer.getPlayer():getCharacter():setLockingInteractable(self.interactable)
		self.network:sendToServer("sv_load", sm.localPlayer.getPlayer())
		self.EOn = true
		self.tickSaved = sm.game.getCurrentTick()
	end
end

--Client function that is called any time the player gives key or mouse input, each input is numbered (ie: A = 1) there are many inputs that are unnumbered and those inputs are 0, the input is given as the parameter 'input'
function SpectateBlock.client_onAction(self, input, active)
    print(input, active)
	if (input == 20) and active then
		self.devModeTicks = sm.game.getCurrentTick()
	end
	
	if(input == 21) and active and (self.devModeTicks > sm.game.getCurrentTick() - 5) then
		if self.devMode == false then
			self.devMode = true
			sm.gui.chatMessage("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n#D5D4FFMod developer mode now on.\n#910000If this was a mistake, you can turn it back off by pressing X then C in quick succession")
		else
			self.devMode = false
			sm.gui.chatMessage("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n#D5D4FFMod developer mode now off.")
		end
		self.devModeTicks = 0
	end

	--E key
	if (input == 15) and self.ePressed == false then
		self.ePressed = true
		self.ePressedTicks = sm.game.getCurrentTick()
	elseif (input == 15) and active and self.ePressed == true then
		self.ePressed = false
		--SpectateBlock.cl_exitCam(self)
	end
	
	--1 Key
	if (input == 5) and active then
		if self.mode == "Free Cam" then
			if self.optSaves == true then
				self.camPos = sm.camera.getPosition()
			end
			self.mode = "Player Cam"
		elseif self.mode == "Player Cam" and active then
			self.mode = "Player Cam"
		end
		if self.titlesOn == true then
			sm.gui.displayAlertText( self.mode )
		end
	end
	
	--2 Key
	if (input == 6) and active then
		SpectateBlock.cl_resetMovement(self)
	end
	
	--4 Key
	if (input == 8) and active then
		if self.optSaves == true then
			self.optSaves = false
			sm.gui.chatMessage("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n#D5D4FFFree cam position saving now off")
		else
			self.optSaves = true
			sm.gui.chatMessage("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n#D5D4FFFree cam position saving now on")
		end
	end

	--5 key
	if (input == 9) and active then
		if self.titlesOn == true then
			self.titlesOn = false
			sm.gui.chatMessage("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n#D5D4FFStatus titles now off")
		else 
			self.titlesOn = true
			sm.gui.chatMessage("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n#D5D4FFStatus titles now on")
		end
	end

	--0 key
	if (input == 14) and active then
		--SpectateBlock.cl_printControls(self)
	end

	--For free cam
	if self.mode == "Free Cam" then
		--A key
		if (input == 1) and self.AOn == false then
			self.AOn = true
		elseif (input == 1) and self.AOn == true then
			self.AOn = false
		end
		--D key
		if (input == 2) and self.DOn == false then
			self.DOn = true
		elseif (input == 2) and self.DOn == true then
			self.DOn = false
		end
		
		--3 Key
		if (input == 7) and active then
			sm.camera.setPosition(sm.localPlayer.getPlayer():getCharacter():getWorldPosition())
		end
		
		--8 key
		if (input == 12) and active then
			if self.playerPosFollow == false then
				self.playerPosFollow = true
				sm.gui.chatMessage("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n#D5D4FFYour character will now follow your free cam position \n#910000This is in early BETA and may have some problems.")
			else
				self.playerPosFollow = false
				sm.gui.chatMessage("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n#D5D4FFYour character will no longer follow your free cam position")
			end
		end
		--9 key
		if (input == 13) and active then
			if self.WSVertLock == false then
				self.WSVertLock = true
				sm.gui.chatMessage("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n#D5D4FFW/S vertical lock is now on")
			else
				self.WSVertLock = false
				sm.gui.chatMessage("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n#D5D4FFW/S vertical lock is now off")
			end
		end
		
		--E key
		if (input == 15) and self.EOn == false then
			self.EOn = true
		elseif (input == 15) and self.EOn == true then
			self.EOn = false
		end
		
		--X key/mouse scroll up
		if (input == 20) and active then
			if self.speed < 0.099 then
			self.speed = self.speed + 0.01
			elseif self.speed < 49.99 then
				self.speed = self.speed + 0.1
			end
		end
		--C key/mouse scroll down
		if (input == 21) and active then
			if self.speed > 0.19 then
				self.speed = self.speed - 0.1
			elseif self.speed > 0.019 then
				self.speed = self.speed - 0.01
			end
		end
		--Displays speed when it is changed (seperate from speed changing for if they are at a max or min)
		if(input == 20 or input == 21) and active and (self.titlesOn == true) then
		--											\/ This is to display the speed with only two decimal places just in case it has more.
			sm.gui.displayAlertText("Speed: " .. math.floor(self.speed*100 + 0.0001)/100)
		end
	end

	--W key
	if (input == 3) and self.WOn == false then
		self.WOn = true
	elseif (input == 3) and self.WOn == true then
		self.WOn = false
	end
	--S key
	if (input == 4) and self.SOn == false then
		self.SOn = true
	elseif (input == 4) and self.SOn == true then
		self.SOn = false
	end
	--Space bar
	if (input == 16) and self.spaceOn == false then
		self.spaceOn = true
	elseif (input == 16) and self.spaceOn == true then
		self.spaceOn = false
	end

	--For player cam
	if self.mode == "Player Cam" then
		SpectateBlock.cl_changeSpecPlayer(self, input, active)
		if (self.devMode == false) and active then
			local playerFromId = getPlayer(self.specPlayerId)
			if (input == 1) and (playerFromId == sm.localPlayer.getPlayer()) then
				SpectateBlock.cl_changeSpecPlayer(self, 1, active)
			elseif (input == 2) and (playerFromId == sm.localPlayer.getPlayer()) then
				SpectateBlock.cl_changeSpecPlayer(self, 2, active)
			end
		end
		--E key
		if (input == 15) and (self.specRotLock == false) and active then
			self.specRotLock = true
		elseif (input == 15) and (self.specRotLock == true) and active then
			self.specRotLock = false
		end
		
		--X key/mouse scroll up
		if (input == 20) and active then
			if self.zoom > 1 then
				self.zoom = self.zoom - 1
			end
		end
		--C key/mouse scroll down
		if (input == 21) and active then
			if self.zoom < 10 then
				self.zoom = self.zoom + 1
			end
		end
		--Displays zoom when it is changed (seperate from zoom changing for if they are at a max or min)
		if(input == 20 or input == 21) and active and (self.titlesOn == true) then
		--											\/ This is to display the zoom with only one decimal place just in case it has multiple.
			sm.gui.displayAlertText("Zoom: " .. self.zoom)
		end
	end	
	return true
end

function getPlayer(id)
	local players = sm.player.getAllPlayers()
	for i = 1, #players,1 do
		if players[i]:getId() == id then
			return players[i]
		end
	end
end

function getCamera(self, id)
	local cameras = self.survCamList
	for i = 1, #cameras,1 do
		if cameras[i].shape:getId() == id then
			return cameras[i]
		end
	end
end

function SpectateBlock.cl_changeSpecPlayer(self, input, active)
	--A key
	if (input == 1) and active and (self.specPlayerId - 1 == 0) then
		self.specPlayerId = #sm.player.getAllPlayers()
	elseif (input == 1) and active then
		self.specPlayerId = self.specPlayerId - 1
	end
	--D key
	if (input == 2) and active and (self.specPlayerId == #sm.player.getAllPlayers()) then
		self.specPlayerId = 1
	elseif (input == 2) and active then
		self.specPlayerId = self.specPlayerId + 1
	end
end

function SpectateBlock.cl_changeSurvCam(self, input, active)
	self.network:sendToServer("sv_sendToAllClients", {funcName = "cl_camChangeTexture", params = {camId = self.survCamList[self.survCam].shape:getId(), newState = "off"}})
	--A key
	if (input == 1) and active and self.survCam - 1 == 0 then
		self.survCam = #self.survCamList
	elseif (input == 1) and active then
		self.survCam = self.survCam - 1
	end
	--D key
	if (input == 2) and active and self.survCam == #self.survCamList then
		self.survCam = 1
	elseif (input == 2) and active then
		self.survCam = self.survCam + 1
	end
end

function SpectateBlock.cl_camHBSlider(self, name, newSetting)
end

function SpectateBlock.cl_guiClose(self)
	self.gui = nil
end

--Client function called every tick (40 times per second) that is used to do things over and over
function SpectateBlock.client_onUpdate(self, dt)
	self.survCamList = {}
	for i, cam in pairs (surveillancecamera) do
		if (cam.shape ~= nil) and (cam.shape:getColor() == self.shape:getColor()) then
			self.survCamList[#self.survCamList + 1] = cam
		end
	end
	if self.camHB and sm.isHost then
		for i, cam in pairs (self.survCamList) do
			if (cam:getHB() ~= self.camHB) and (cam:getHB() == nil) then
				cam:changeHB(self.camHB)
			end
		end
	end
	if (self.tickSaved + 2) == sm.game.getCurrentTick() then
		self.camOn = true
	end
	if self.camOn == true then
		SpectateBlock.cl_camMove(self)
		sm.gui.setInteractionText( "" )
		sm.gui.setInteractionText( "" )
	end
end

function SpectateBlock.sv_sendToAllClients(self, params)
	self.network:sendToClients(params.funcName, params.params)
end

function SpectateBlock.sv_movePlayer(self, params)
	params.player:setCharacter(sm.character.createCharacter(params.player, sm.world:getCurrentWorld(), params.pos))
end

function SpectateBlock.cl_camChangeTexture(self, params)
	local camera = getCamera(self, params.camId)
	if params.newState == "on" and camera then
		camera.interactable:setUvFrameIndex(1)
        camera.interactable:setPoseWeight(0, 1)
	elseif camera then
		camera.interactable:setUvFrameIndex(0)
        camera.interactable:setPoseWeight(0, 0)
	end
end

--Client function called every tick (40 times per second) that handles camera movements (and some other stuff)
function SpectateBlock.cl_camMove(self)
	
	if not self.survCamList[self.survCam] then
		self.survCam = 1
	end
	
	if (self.mode == "Player Cam") and (#sm.player.getAllPlayers() == 1) and (#self.survCamList == 0) and (self.devMode == false) then
		self.mode = "Free Cam"
		self.eOn = false
	end
	
	if (self.mode == "Surveillance Cam") and (#self.survCamList == 0) and (self.devMode == false) then
		self.mode = "Free Cam"
		self.eOn = false
	end
	
	if self.ePressedTicks + 10 < sm.game.getCurrentTick() then
		self.ePressed = false
	end
	
	
	
	--Free cam mode
	if self.mode == "Free Cam" then
		if self.WSVertLock == false then
			--Moving bits
			local movement = sm.vec3.new(0, 0, 0)
			--Forward
			if self.WOn == true then
				movement = movement + sm.camera.getDirection() * self.speed
			end
			--Left
			if self.AOn == true then
				movement = movement - sm.camera.getRight() * self.speed
			end
			--Backward
			if self.SOn == true then
				movement = movement - sm.camera.getDirection() * self.speed
			end
			--Right
			if self.DOn == true then
				movement = movement + sm.camera.getRight() * self.speed
			end
			--Up
			if self.spaceOn == true then
				movement = sm.vec3.new(movement["x"], movement["y"], movement["z"] + self.speed)
			end
			--Down
			if self.EOn == true then
				movement = sm.vec3.new(movement["x"], movement["y"], movement["z"] - self.speed)
			end
			sm.camera.setPosition(sm.camera.getPosition() + movement)
			--Turning bit
			sm.camera.setDirection(sm.localPlayer.getPlayer():getCharacter():getDirection())
			self.camPos = sm.camera.getPosition()
		else
			--Moving bits
			local movement = sm.vec3.new(0, 0, 0)
			--Forward
			if self.WOn == true then
				if sm.camera.getDirection()["z"] < 0 then
					--movement = movement + (sm.camera.getDirection() + sm.vec3.new(math.abs(sm.camera.getUp()["x"]), math.abs(sm.camera.getUp()["y"]), 0)) * self.speed
					movement = movement + (sm.vec3.new(sm.camera.getDirection()["x"], sm.camera.getDirection()["y"], 0) + sm.vec3.new(sm.camera.getUp()["x"], sm.camera.getUp()["y"], 0)) * self.speed
				else
					movement = movement + (sm.vec3.new(sm.camera.getDirection()["x"], sm.camera.getDirection()["y"], 0) - sm.vec3.new(sm.camera.getUp()["x"], sm.camera.getUp()["y"], 0)) * self.speed
				end
			end
			if self.AOn == true then
				movement = movement - sm.camera.getRight() * self.speed
			end
			--Backward
			if self.SOn == true then
				if sm.camera.getDirection()["z"] < 0 then
					--movement = movement + (sm.camera.getDirection() + sm.vec3.new(math.abs(sm.camera.getUp()["x"]), math.abs(sm.camera.getUp()["y"]), 0)) * self.speed
					movement = movement - (sm.vec3.new(sm.camera.getDirection()["x"], sm.camera.getDirection()["y"], 0) + sm.vec3.new(sm.camera.getUp()["x"], sm.camera.getUp()["y"], 0)) * self.speed
				else
					movement = movement - (sm.vec3.new(sm.camera.getDirection()["x"], sm.camera.getDirection()["y"], 0) - sm.vec3.new(sm.camera.getUp()["x"], sm.camera.getUp()["y"], 0)) * self.speed
				end
			end
			--Right
			if self.DOn == true then
				movement = movement + sm.camera.getRight() * self.speed
			end
			--Up
			if self.spaceOn == true then
				movement = sm.vec3.new(movement["x"], movement["y"], movement["z"] + self.speed)
			end
			--Down
			if self.EOn == true then
				movement = sm.vec3.new(movement["x"], movement["y"], movement["z"] - self.speed)
			end
			sm.camera.setPosition(sm.camera.getPosition() + sm.vec3.new(movement["x"], movement["y"], movement["z"]))
			--Turning bit
			sm.camera.setDirection(sm.localPlayer.getPlayer():getCharacter():getDirection())
			self.camPos = sm.camera.getPosition()
		end
		if self.playerPosFollow == true then
			--print(sm.camera)
			--self.network:sendToServer("sv_movePlayer",{player = sm.localPlayer.getPlayer(), pos = sm.camera.getPosition(), yaw = sm.camera.getDirection, pitch = sm.camera.getUp()})
			sm.physics.applyImpulse(sm.localPlayer.getPlayer():getCharacter(), (sm.camera.getPosition() - sm.localPlayer.getPlayer():getCharacter():getWorldPosition()) * 10)
		end
	end
	
	--Player cam mode
	if self.mode == "Player Cam" then
		local playerFromId = getPlayer(self.specPlayerId)
		if self.specRotLock == true then
			--Same thing for now, this will be changed to lock rotation to the spectated player's rotation
			sm.camera.setPosition(sm.vec3.new(playerFromId:getCharacter():getWorldPosition()["x"] + sm.camera.getRight()["y"] * self.zoom, playerFromId:getCharacter():getWorldPosition()["y"] - sm.camera.getRight()["x"] * self.zoom, playerFromId:getCharacter():getWorldPosition()["z"] + 1))
			
			sm.camera.setDirection(sm.localPlayer.getPlayer():getCharacter():getDirection())
		else
			sm.camera.setPosition(sm.vec3.new(playerFromId:getCharacter():getWorldPosition()["x"] + sm.camera.getRight()["y"] * self.zoom, playerFromId:getCharacter():getWorldPosition()["y"] - sm.camera.getRight()["x"] * self.zoom, playerFromId:getCharacter():getWorldPosition()["z"] + 1))
			
			sm.camera.setDirection(sm.localPlayer.getPlayer():getCharacter():getDirection())
		end
	end
	
	--Surveillance cam mode
	if self.mode == "Surveillance Cam" then
		local camera = self.survCamList[self.survCam]
		local direc = sm.vec3.new(0, 0, -1)
		if self.shape:getUp()["x"] ~= 0 then
			direc = sm.vec3.new(0.01, 0, -1)
		elseif self.shape:getUp()["y"] ~= 0 then
			direc = sm.vec3.new(0, 0, -1)
		end
		if camera:getActive() == true then
			--local vel = camera.shape:getVelocity()
			--local at = camera.shape:getAt()
			sm.camera.setPosition(camera.shape:getWorldPosition() + sm.camera.getDirection() / 5)
			--sm.camera.setPosition(camera.shape:getWorldPosition() + camera.shape:getAt() * 0.1 * math.abs(at.x * vel.x + at.y * vel.y + at.z * vel.z))
			sm.camera.setDirection(camera.shape:getUp())
		else
			if not self.inactiveTicksSaved then
				self.inactiveTicksSaved = sm.game.getCurrentTick()
			end
			if self.inactiveTicksSaved > sm.game.getCurrentTick() - 6 then
				sm.camera.setPosition((self.shape:getWorldPosition() + self.shape:getUp() / 5 - self.shape:getAt() / 9) - sm.vec3.new(0, 0, 0.05))
				sm.camera.setDirection(direc)
			elseif self.inactiveTicksSaved > sm.game.getCurrentTick() - 11 then
				sm.camera.setPosition((self.shape:getWorldPosition() + self.shape:getUp() / 10 - self.shape:getAt() / 9) - sm.vec3.new(0, 0, 0.05))
				sm.camera.setDirection(direc)
			elseif self.inactiveTicksSaved > sm.game.getCurrentTick() - 16 then
				sm.camera.setPosition((self.shape:getWorldPosition() + self.shape:getUp() / 15 - self.shape:getAt() / 9) - sm.vec3.new(0, 0, 0.05))
				sm.camera.setDirection(direc)
			else
				self.inactiveTicksSaved = sm.game.getCurrentTick()
			end
		end
		local o = 0
		for i, cam in pairs (self.survCamList) do
			if cam == camera then
				self.network:sendToServer("sv_sendToAllClients", {funcName = "cl_camChangeTexture", params = {camId = self.survCamList[self.survCam].shape:getId(), newState = "on"}})
			end
		end
	end
	
end

--Client function that resets all stored information to its default, as you'd expect a function called 'reset everything' to do
function SpectateBlock.cl_resetEverything(self)
	self.optSaves = true					--This is saved
	self.WOn = false
	self.AOn = false
	self.SOn = false
	self.DOn = false
	self.spaceOn = false
	self.EOn = false
	self.ePressedTicks = 0
	self.devModeTicks = 0
	self.ePressed = false
	self.ThreeOn = false
	self.FourOn = false
	self.FiveOn = false
	self.SevenOn = false
	self.EightOn = false
	self.NineOn = false
	self.ZeroOn = false
	self.WSVertLock = false					--This is saved
	self.specPlayerId = 1					--This is saved
	self.titlesOn = true					--This is saved
	self.speed = 0.1						--This is saved
	self.zoom = 1							--This is saved
	self.mode = "Free Cam"					--This is saved
	self.camPos = sm.camera.getPosition()	--This is saved
	self.specRotLock = true					--This is saved
	self.playerPosFollow = false			--This is saved
	self.camOn = false
	self.survCam = 1
	self.survCamList = {}
	self.camHBList = {"Nothing", "Disabled for 15 seconds", "Disabled for 30 seconds", "Disabled for 1 minute", "Disabled for 3 minutes", "Disabled for 5 minutes", "Disabled until manual reset", "Physical destruction"}
	self.tickSaved = 0
	self.gui = nil
	
	self.devMode = false --This bypasses things that would normally not be allowed (such as not being allowed to spectate self in player spectator mode) and also prints certain things to the debug console
	--You can set this to true if you want, but nothing really that cool will happen
end

--Client function that resets all movement related values (this is to fix any negated movement issues)
function SpectateBlock.cl_resetMovement(self)
	self.WOn = false
	self.AOn = false
	self.SOn = false
	self.DOn = false
	self.spaceOn = false
	self.EOn = false
	self.ePressed = false
end

function SpectateBlock.cl_save(self)
	local cam = self.survCamList[self.survCam]
	if not self.camHB then
		if cam then
			if cam:getHB() then
				self.camHB = cam:getHB()
			else
				self.camHB = 0
			end
		else
			self.camHB = 0
		end
	end
	local storing = {self.optSaves, self.specPlayerId, self.titlesOn, self.speed, self.zoom, self.mode, self.specRotLock, self.camHB, self.WSVertLock, self.playerPosFollow}
	if self.optSaves == true then
		table.insert(storing, self.camPos)
	else
		table.insert(storing, nil)
	end
	local userId = sm.localPlayer.getPlayer().id
	self.network:sendToServer("sv_save", {storing = storing, userId = userId})
end

function SpectateBlock.sv_save(self, params)
	local stored = self.storage:load()
	if stored == nil then
		stored = {}
	end
	for i=1, 11 do
		if params.storing[i] ~= nil then
			stored[i+11*(params.userId-1)] = params.storing[i]
			if self.devMode == true then
				print("Saving value position " .. i)
			end
		end
	end
	self.storage:save(stored)
	if self.devMode == true then
		print("Values saved!")
	end
end

function SpectateBlock.sv_load(self, player)
	local stored = self.storage:load()
	
	self.network:sendToClient(player, "cl_load", stored)
end

function SpectateBlock.cl_load(self, stored)
	local userId = sm.localPlayer.getPlayer().id
	if stored then
		self.optSaves = 	stored[1+10*(userId-1)]
		self.specPlayerId = stored[2+10*(userId-1)]
		self.titlesOn = 	stored[3+10*(userId-1)]
		self.speed = 		stored[4+10*(userId-1)]
		self.zoom = 		stored[5+10*(userId-1)]
		self.mode = 		stored[6+10*(userId-1)]
		self.specRotLock = 	stored[7+10*(userId-1)]
		self.camHB = 		stored[8+10*(userId-1)]
		self.WSVertLock =	stored[9+10*(userId-1)]
		if stored[10+10*(userId-1)] then
			self.camPos = 	stored[10+10*(userId-1)]
		end
		if self.devMode == true then
			print("Saved values loaded!")
		end
	end
	
	if self.optSaves == false then
		self.camPos = sm.localPlayer.getPlayer():getCharacter():getWorldPosition()
	end
end

function SpectateBlock.server_closeAll(self)
    self.network:sendToClients("cl_exitCam")
end

function SpectateBlock.cl_exitCam(self)
	self.camOn = false
	if self.gui then
		self.gui:close()
		self.gui = nil
	end
	if self.optSaves == true then
		self.camPos = sm.camera.getPosition()
	end
    if sm.localPlayer.getPlayer():getCharacter()
    and sm.localPlayer.getPlayer():getCharacter():getLockingInteractable() then
        --SpectateBlock.cl_save(self)
        sm.localPlayer.getPlayer():getCharacter():setLockingInteractable(nil)
        sm.camera.setCameraState(1)
    end
end