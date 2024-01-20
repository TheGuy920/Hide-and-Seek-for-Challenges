dofile("$CONTENT_a65c170c-ede3-4757-9f1a-586eabf1a2bc/Scripts/Core/Util.lua")
Player = class(nil)

function Player.server_onCreate(self)
	print("Player.server_onCreate")
	ChallengePlayer.server_onCreate(self)
	self.start = sm.game.getCurrentTick()
	sm.event.sendToGame("server_playerScriptReady", self.player)
	self.lasting_health_rule = false
end

function Player.server_updateGameRules(self, rules)
	if rules and rules.settings then
		self.lasting_health_rule = rules.settings.enable_health == true
	else
		self.lasting_health_rule = false
	end
end

function Player.server_playerJoined(self, data)
	self:server_updateGameState(data.state)
	if self.sv.spawnparams == nil then
		ChallengePlayer.sv_init(self)
	end
end

function Player.cl_n_startFadeToBlack(self, param)
	BasePlayer.cl_n_startFadeToBlack(self, param)
end

function Player.server_updateGameState(self, State, caller)
	if not sm.isServerMode() or caller ~= nil then
		return
	end
	self.state = State

	print("Sending Game state to clients", State)
	self.network:sendToClients("client_updateGameState", State)

	if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
		self.server_ready = false
		ChallengePlayer.server_onCreate(self)
		self.network:sendToClient(self.player, "_client_onCreate")
	elseif self.player ~= sm.player.getAllPlayers()[1] then
		sm.container.beginTransaction()
		local inv = self.player:getInventory()
		for i = 1, inv:getSize() do
			sm.container.setItem(inv, i - 1, sm.uuid.getNil(), 1)
		end
		sm.container.endTransaction()
	end
end

function Player.client_updateGameState(self, State, caller)
	if sm.isServerMode() or caller ~= nil then
		return
	end
	print("Client recieved game state", State)
	self.state = State
end

function Player.cl_n_onEvent(self, data)
	if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
		BasePlayer.cl_n_onEvent(self, data)
	end
end

function Player.client_getMode(self, tool)
	if sm.exists(tool) then
		sm.event.sendToTool(tool, "client_setMode", self.state)
	end
end

function Player.cl_n_onInventoryChanges(self, data)
	if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
		ChallengePlayer.cl_n_onInventoryChanges(self, data)
	end
end

function Player._server_onCreate(self)
	if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
		ChallengePlayer.server_onCreate(self)
		self.server_ready = true
	end
end

function Player._client_onCreate(self)
	if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
		ChallengePlayer.client_onCreate(self)
		self.network:sendToServer("_server_onCreate")
	end
end

function Player.client_onCreate(self)
	ChallengePlayer.client_onCreate(self)
end

function Player.server_onDestroy(self)
	if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
		ChallengePlayer.server_onDestroy(self)
	end
end

function Player.sv_updateTumbling(self)
	if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
		BasePlayer.sv_updateTumbling(self)
	end
end

function Player.client_onDestroy(self)
	if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
		ChallengePlayer.client_onDestroy(self)
	end
end

function Player.server_onRefresh(self)
	if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
		ChallengePlayer.server_onRefresh(self)
	end
end

function Player.client_onRefresh(self)
	if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
		BasePlayer.client_onRefresh(self)
	end
end

local waterSpeedFactor = 4
function Player.server_onFixedUpdate(self, timeStep)
	-- build mode
	if self.state == States.Build then
		if self.player.character ~= nil then
			if not self.player.character:isSwimming() then
				-- set thingies
				if sm.isHost then
					if self.player.character.publicData then
						self.player.character.publicData.waterMovementSpeedFraction = waterSpeedFactor
					end
				else
					if self.player.character.clientPublicData then
						self.player.character.clientPublicData.waterMovementSpeedFraction = waterSpeedFactor
					end
				end
				-- set swim
				self.player.character:setSwimming(true)
			end
		end
	end
	if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
		if self.server_ready == true then
			ChallengePlayer.server_onFixedUpdate(self, timeStep)
		end
		if self.spectators and self.spectate_part and not self.spectate_51sf61 then
			sm.event.sendToInteractable(self.spectate_part, "server_recieveSpectators", {player=self.player,players=self.spectators})
		elseif not self.spectate_part then
			self.spectate_51sf61 = nil
		end
	end
end

function Player.sv_e_challengeReset(self)
	ChallengePlayer.sv_e_challengeReset(self)
end

function Player.sv_e_respawn(self)
	ChallengePlayer.sv_e_respawn(self)
end

function Player.client_onFixedUpdate(self, timeStep)
	if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
	--ChallengePlayer.client_onFixedUpdate( self, timeStep )
	end
end

function Player.server_requestGameState( self, player )
	print("Fetching Game State for", player, self.state)
	if self.state ~= nil then
		self.network:sendToClient(player, "client_updateGameState", self.state)
	else
		sm.event.sendToGame("server_playerScriptReady", player)
	end
end

function Player.client_onUpdate(self, dt)
	local local_player = sm.localPlayer.getPlayer()
	if not sm.isHost and self.client_updateGameState == nil then
		for index, value in pairs(Player) do
			local found = string.find(tostring(type(value)), "function")
			if found then
				self[index] = value
			end
		end
		return
	end
	if self.state == nil and not sm.isHost then
		self.network:sendToServer("server_requestGameState", local_player)
		return
	end

	if not sm.isHost and self.state == States.PackMenu or self.state == States.PlayMenu or self.state == States.BuildMenu then
		if local_player.character ~= nil then
			if local_player.character:getLockingInteractable() ~= nil then
				local_player.character:setLockingInteractable(nil)
			end
		end
	end
	if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
		ChallengePlayer.client_onUpdate(self, deltaTime)
	end
end

function Player.client_onClientDataUpdate(self, data)
	ChallengePlayer.client_onClientDataUpdate(self, data)
end

function Player.server_onProjectile(
	self,
	position,
	airTime,
	velocity,
	projectileName,
	shooter,
	damage,
	customData,
	normal,
	uuid)
	if self.state == States.Play or self.state == States.PlayBuild then
		ChallengePlayer.server_onProjectile(
			self,
			position,
			airTime,
			velocity,
			projectileName,
			shooter,
			damage,
			customData,
			normal,
			uuid
		)
	end
end

function Player.server_onExplosion(self, center, destructionLevel)
	if self.state == States.Play or self.state == States.PlayBuild then
		ChallengePlayer.server_onExplosion(self, center, destructionLevel)
	end
end

function Player.server_onMelee(self, position, attacker, damage, power, direction, normal)
	if self.state == States.Play or self.state == States.PlayBuild then
		BasePlayer.server_onMelee(self, position, attacker, damage, power, direction, normal)
	end
end

function Player.cl_n_endFadeToBlack(self, param)
	BasePlayer.cl_n_endFadeToBlack(self, param)
end

function Player.sv_e_onSpawnCharacter(self)
	if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
		ChallengePlayer.sv_e_onSpawnCharacter(self)
	end
end

function Player.cl_localPlayerUpdate(self, dt)
	if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
		ChallengePlayer.cl_localPlayerUpdate(self, position, attacker, damage, power, direction, normal)
	end
end

function Player.sv_takeDamage(self, damage, string)
	if self.state == States.Play or self.state == States.PlayBuild then
		ChallengePlayer.sv_takeDamage(self, damage, string)
	end
end

function Player.sv_init(self)
	if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
		ChallengePlayer.sv_init(self)
	end
end

function Player.cl_init(self)
	if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
		BasePlayer.cl_init(self)
	end
end

function Player.server_onCollision(self, other, position, selfPointVelocity, otherPointVelocity, normal)
	if self.state == States.Play or self.state == States.PlayBuild then
		ChallengePlayer.server_onCollision(self, other, position, selfPointVelocity, otherPointVelocity, normal)
	end
end

function Player.server_onCollisionCrush(self)
	if self.state == States.Play or self.state == States.PlayBuild then
	--ChallengePlayer.server_onCollisionCrush( self )
	end
end

function Player.server_onShapeRemoved(self, items)
	--items = { { uuid = uuid, amount = integer, type = string }, .. }
	if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
	--ChallengePlayer.server_onShapeRemoved( self, items )
	end
end

function Player.server_onInventoryChanges(self, inventory, changes)
	--changes = { { uuid = Uuid, difference = integer, tool = Tool }, .. }
	if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
		self.network:sendToClient(self.player, "cl_n_onInventoryChanges", {container = container, changes = changes})
	end
end

function Player.client_onInteract(self, character, state)
	if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
		ChallengePlayer.client_onInteract(self, character, state)
	end
end

function Player.server_setHideAndSeekOptions(self, options)
	self.hideandseekoptions = options
end

function Player.sv_n_tryRespawn(self)
	if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
		ChallengePlayer.sv_n_tryRespawn(self, character, state)
	end
end

function Player.client_onCancel(self)
	if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
		ChallengePlayer.client_onCancel(self)
	end
end

function Player.client_onReload(self)
	if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
		ChallengePlayer.client_onReload(self)
	end
end

function Player.cl_n_fillWater(self)
	BasePlayer.cl_n_fillWater(self)
end

function Player.server_destroyCharacter(self)
	--self.player:setCharacter(nil)
end

function Player.sv_e_enableHealth(self, enableHealth)
	if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
		ChallengePlayer.sv_e_enableHealth(self, enableHealth)
	end
end

function Player.server_setMaxHp(self, maxhp)
	if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
		ChallengePlayer.server_setMaxHp(self, maxhp)
	end
end

function Player.server_setSpectate(self, data)
	if self.state == States.Play or self.state == States.PlayBuild or self.state == States.Build then
		self.spectate = data.state
		self.spectate_part = data.part
		if self.spectate_part and self.spectators then 
			sm.event.sendToInteractable(self.spectate_part, "server_recieveSpectators", {player=self.player,players=self.spectators})
		end
		self.network:sendToClient(self.player, "client_setSpectate", data)
	end

	if not data.state then
		if sm.exists(self.spectate_part) then
			sm.event.sendToInteractable(self.spectate_part, "server_unBindAll")
		else
			self.network:sendToClient(self.player, "client_manualReset")
		end
	end
end

function Player.client_manualReset(self)
	if self.player:getCharacter() then
		self.player:getCharacter():setLockingInteractable(nil)
	end
	sm.camera.setCameraState(sm.camera.state.default)
end

function Player.server_setSpectatorList( self, list )
	if not self.spectators then
		self.spectators = {}
	end
	for _, spectator in pairs( list ) do
		for _, player in pairs(self.spectators) do
			if player == spectator then
				goto pass0
			end
		end
		table.insert( self.spectators, spectator )
		::pass0::
	end
end

function Player.server_confirmSpectators( self )
	self.spectate_51sf61 = true
end

function Player.client_setSpectate(self, data)
	self.spectate = data.state
	if data.part then self.spectate_part = data.part end
	if self.spectate_part and sm.exists(self.spectate_part) then
		if self.spectate then
			sm.event.sendToInteractable(self.spectate_part, "client_bindPlayer", self.player)
		else
			sm.camera.setCameraState(sm.camera.state.default)
			sm.event.sendToInteractable(self.spectate_part, "client_unBindPlayer", self.player)
			self.player:getCharacter():setLockingInteractable(nil)
		end
	end
end

function Player._client_onLoadingScreenLifted(self)
	if self.state == States.PackMenu or self.state == States.PlayMenu then
		if sm.localPlayer.getPlayer().character ~= nil then
			self.network:sendToServer("server_destroyCharacter")
		end
	end
end
