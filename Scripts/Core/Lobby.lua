dofile("$CONTENT_DATA/Scripts/Core/Util.lua")
World = class( nil )
World.terrainScript = "$CONTENT_DATA/Scripts/Core/terrain.lua"
World.cellMinX = -2
World.cellMaxX = 1
World.cellMinY = -2
World.cellMaxY = 1
World.worldBorder = true
World.enableSurface = true
World.enableAssets = true
World.enableClutter = true
World.enableNodes = false
World.enableCreations = false
World.enableHarvestables = false
World.enableKinematics = false

local MenuLockUuid = sm.uuid.new("b9e418dd-5875-4ca6-85f1-48154fa81643")
local OrderList = {
	sm.uuid.new("d8669091-5ed8-41af-90dd-60e6f5d1f282"),
	sm.uuid.new("d8669091-5ed8-41af-90dd-60e6f5d1f282"),
	sm.uuid.new("1be96842-cb7d-4748-b159-3dbc61ca1f40"),
	sm.uuid.new("1be96842-cb7d-4748-b159-3dbc61ca1f40")
}
local posOffset = {
	sm.vec3.new(-0.55,0,0),
	sm.vec3.new(0.3,0,0),
	sm.vec3.new(0,-0.55,0),
	sm.vec3.new(0,0.3,0)
}

function World.server_onCreate( self )
    print("World.server_onCreate")
	sm.event.sendToGame("sve_maybeDestroyWorld", self.world)
    sm.event.sendToGame("server_worldScriptReady")
	self.menu_lock = nil
	self.barrier = {}
	for _,body in pairs(sm.body.getAllBodies()) do
		for _,shape in pairs(body:getShapes()) do
			if shape.uuid == MenuLockUuid then
				self.menu_lock = shape:getInteractable()
			end
			if shape.uuid == OrderList[1] or shape.uuid == OrderList[3] then
				table.insert(self.barrier, shape)
			end
		end
	end
	if self.menu_lock == nil then
		self.menu_lock = sm.shape.createPart( MenuLockUuid, sm.vec3.new(0,0,-500), nil, false, true ):getInteractable()
	end
	if #self.barrier ~= 4 then
		for _,shape in pairs(self.barrier) do
			shape:destroyShape()
		end
		self.barrier = {}
		for index = 1, 4 do
			table.insert(self.barrier, sm.shape.createPart( OrderList[index], sm.vec3.new(0.8375, -112.725, -4) + posOffset[index], nil, false, true ))
		end
	end
	local host = sm.player.getAllPlayers()[1]
	for _,player in pairs(sm.player.getAllPlayers()) do
		if player:getCharacter() ~= nil then
			if player == host then
				player.character:setLockingInteractable(self.menu_lock)
			else
				player.character:setLockingInteractable(nil)
			end
		end
	end
end


function World.client_setLighting( self )
	sm.render.setOutdoorLighting( 0.5 )
end

function World.server_setMenuLockNil( self, char )
	if char:getLockingInteractable() then
		char:setLockingInteractable(nil)
	end
end

function World.server_setMenuLock( self, char )
	if sm.exists(char) then
		char:setLockingInteractable(self.menu_lock)
	end
end

function World.server_updateGameState( self, State, caller )
    if not sm.isServerMode() or caller ~= nil then return end
    self.state = State
end

function World.client_onCreate( self )
	self:client_setLighting()
end

function World.server_onDestroy( self )
end

function World.client_onDestroy( self )
end

function World.server_onRefresh( self )
end

function World.client_onRefresh( self )
	self:client_setLighting()
end

function World.server_onFixedUpdate( self, timeStep )
end

function World.client_onFixedUpdate( self, timeStep )
end

function World.client_onUpdate( self, deltaTime )
end

function World.client_onClientDataUpdate( self, data, channel )
end

function World.server_onCollision( self, objectA, objectB, position, pointVelocityA, pointVelocityB, normal )
end

function World.client_onCollision( self, objectA, objectB, position, pointVelocityA, pointVelocityB, normal )
end

function World.server_onCellCreated( self, x, y )
end

function World.server_onCellLoaded( self, x, y )
end

function World.server_onCellUnloaded( self, x, y )
end

function World.server_onInteractableCreated( self, interactable )
end

function World.server_onInteractableDestroyed( self, interactable )
end

function World.server_onProjectile( self, position, airTime, velocity, projectileName, shooter, damage, customData, normal, target, uuid )
end

function World.server_onExplosion( self, center, destructionLevel )
end

function World.server_onMelee( self, position, attacker, target, damage, power, direction, normal )
end

function World.server_onProjectileFire( self, position, velocity, projectileName, shooter, uuid )
end

function World.client_onCellLoaded( self, x, y )
end

function World.client_onCellUnloaded( self, x, y )
end

function World.server_spawnNewCharacter( self, params )
	self:server_spawnCharacter( params )
end

function World.server_spawnCharacter( self, params )
	print("World: spawnCharacter")
	for _, player in pairs( params.players ) do
		local char = CreateCharacterOnSpawner( self, self.world, player, {}, sm.vec3.new( 0.8375, -112.725, 6 ), false )
		if player == sm.player.getAllPlayers()[1] then
			char:setLockingInteractable(self.menu_lock)
		else
			char:setLockingInteractable(nil)
		end
		sm.event.sendToPlayer( player, "sv_e_onSpawnCharacter")
		self.network:sendToClient(player, "client_getSelectedHotBarAndReturn", "server_setHostHammer")
		self.server_setHostHammer = function ( self, index )
			sm.container.beginTransaction()
			for i=1,player:getHotbar():getSize() do
				sm.container.setItem( player:getHotbar(), i - 1, sm.uuid.getNil(), 1 )
			end
			sm.container.setItem( player:getHotbar(), index, sm.uuid.new("9d4d51b5-f3a5-407f-a030-138cdcf30b4e"), 1 )
			sm.container.endTransaction()
		end
	end
end

function World.client_getSelectedHotBarAndReturn( self, callback )
	self.network:sendToServer(callback, sm.localPlayer.getSelectedHotbarSlot())
end