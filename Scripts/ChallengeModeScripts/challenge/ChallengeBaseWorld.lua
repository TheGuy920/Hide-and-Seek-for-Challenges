dofile( "$SURVIVAL_DATA/Scripts/game/managers/PesticideManager.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_projectiles.lua" )

ChallengeBaseWorld = class( nil )
ChallengeBaseWorld.renderMode = "challenge"

function ChallengeBaseWorld.server_onCreate( self )
	if self.waitingForDeath == true then return end
	self.pesticideManager = PesticideManager()
	self.pesticideManager:sv_onCreate()
	self.container_table = {}
	for _,path in pairs(self.data.levelCreations) do
		local bodies = sm.json.open(path, true).bodies
		for _,body in pairs(bodies) do
			for _,child in pairs(body.childs) do
				if child.controller ~= nil then
					if child.controller.container ~= nil then
						table.insert(self.container_table, { id = child.controller.id, container = child.controller.container })
					end
				end
			end
		end
	end
end

function ChallengeBaseWorld.server_onFinishedCellLoading( self )
	local idTable = {}
	for _,body in pairs(sm.body.getAllBodies()) do
		for _,inter in pairs(body:getInteractables()) do
			local container = inter:getContainer()
			if container ~= nil then
				table.insert(idTable, { id = inter:getId(), container = container})
			end
		end
	end
	table.sort(idTable, function(a, b) return a.id < b.id end)
	for _,box in pairs(idTable) do
		print(box.id, box.container:getItem( 0 ))
	end
end

function ChallengeBaseWorld.server_exitToMenu( self, f )
	for _,body in pairs(sm.body.getAllBodies()) do
        for _,shape in pairs(body:getShapes()) do
            shape:destroyShape( 0 )
        end
    end
	if f == true then 
		self.network:sendToClients("client_closeAllMenu")
	end
	sm.event.sendToGame("server_exitToMenu2", {world=self.world, first=f})
end

function ChallengeBaseWorld.client_closeAllMenu( self )
	if sm.exists(_G.g_survivalHud) then
		_G.g_survivalHud:close()
		_G.g_survivalHud:destroy()
	end
	sm.camera.setCameraState( sm.camera.state.default )
end

function ChallengeBaseWorld.client_onRefresh( self )
	self:client_setLighting()
end

function ChallengeBaseWorld.client_setLighting( self )
	sm.render.setOutdoorLighting( 0.3 )
end

function ChallengeBaseWorld.client_onCreate( self )
	if self.waitingForDeath == true then return end
	if self.pesticideManager == nil then
		assert( not sm.isHost )
		self.pesticideManager = PesticideManager()
	end
	self.pesticideManager:cl_onCreate()
	self:client_setLighting()
end

function ChallengeBaseWorld.server_onFixedUpdate( self )
	if self.waitingForDeath == true then return end
	self.pesticideManager:sv_onWorldFixedUpdate( self )
end

function ChallengeBaseWorld.cl_n_pesticideMsg( self, msg )
	if self.waitingForDeath == true then return end
	self.pesticideManager[msg.fn]( self.pesticideManager, msg )
end

function ChallengeBaseWorld.server_onProjectileFire( self, firePos, fireVelocity, _, attacker, projectileUuid )
	if self.waitingForDeath == true then return end
	if isAnyOf( projectileUuid, _G.g_potatoProjectiles ) then
		local units = sm.unit.getAllUnits()
		for i, unit in ipairs( units ) do
			if InSameWorld( self.world, unit ) then
				sm.event.sendToUnit( unit, "sv_e_worldEvent", { eventName = "projectileFire", firePos = firePos, fireVelocity = fireVelocity, projectileUuid = projectileUuid, attacker = attacker })
			end
		end
	end
end

function ChallengeBaseWorld.server_onInteractableCreated( self, interactable )
	if self.waitingForDeath == true then return end
	_G.g_unitManager:sv_onInteractableCreated( interactable )
end

function ChallengeBaseWorld.server_onInteractableDestroyed( self, interactable )
	if self.waitingForDeath == true then return end
	_G.g_unitManager:sv_onInteractableDestroyed( interactable )
end

function ChallengeBaseWorld.server_onProjectile( self, hitPos, hitTime, hitVelocity, _, attacker, damage, userData, hitNormal, target, projectileUuid )
	if self.waitingForDeath == true then return end
	-- Notify units about projectile hit
	if isAnyOf( projectileUuid, _G.g_potatoProjectiles ) then
		local units = sm.unit.getAllUnits()
		for i, unit in ipairs( units ) do
			if InSameWorld( self.world, unit ) then
				sm.event.sendToUnit( unit, "sv_e_worldEvent", { eventName = "projectileHit", hitPos = hitPos, hitTime = hitTime, hitVelocity = hitVelocity, attacker = attacker, damage = damage })
			end
		end
	end

	if projectileUuid == projectile_pesticide then
		local forward = sm.vec3.new( 0, 1, 0 )
		local randomDir = forward:rotateZ( math.random( 0, 359 ) )
		local effectPos = hitPos
		local success, result = sm.physics.raycast( hitPos + sm.vec3.new( 0, 0, 0.1 ), hitPos - sm.vec3.new( 0, 0, PESTICIDE_SIZE.z * 0.5 ), nil, sm.physics.filter.static + sm.physics.filter.dynamicBody )
		if success then
			effectPos = result.pointWorld + sm.vec3.new( 0, 0, PESTICIDE_SIZE.z * 0.5 )
		end
		self.pesticideManager:sv_addPesticide( self, effectPos, sm.vec3.getRotation( forward, randomDir ) )
	end

	--if projectileUuid == projectile_glowstick then
	--	sm.harvestable.createHarvestable( hvs_remains_glowstick, hitPos, sm.vec3.getRotation( sm.vec3.new( 0, 1, 0 ), hitVelocity:normalize() ) )
	--end

	if projectileUuid == projectile_explosivetape then
		sm.physics.explode( hitPos, 7, 2.0, 6.0, 25.0, "RedTapeBot - ExplosivesHit" )
	end
end

function ChallengeBaseWorld.server_onCollision( self, objectA, objectB, collisionPosition, objectAPointVelocity, objectBPointVelocity, collisionNormal )
	if self.waitingForDeath == true then return end
	_G.g_unitManager:sv_onWorldCollision( self, objectA, objectB, collisionPosition, objectAPointVelocity, objectBPointVelocity, collisionNormal )
end