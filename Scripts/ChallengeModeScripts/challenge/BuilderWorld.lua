dofile( "$CONTENT_DATA/Scripts/ChallengeModeScripts/challenge/ChallengeBaseWorld.lua")
dofile( "$CONTENT_DATA/Scripts/ChallengeModeScripts/challenge/world_util.lua" )
dofile( "$CONTENT_DATA/Scripts/ChallengeModeScripts/game/challenge_shapes.lua" )
dofile( "$CONTENT_DATA/Scripts/ChallengeModeScripts/game/challenge_tools.lua" )

BuilderWorld = class( ChallengeBaseWorld )
BuilderWorld.terrainScript = "$CONTENT_DATA/Scripts/ChallengeModeScripts/challenge/terrain_challengebuilder.lua"
--BuilderWorld.terrainScript = "$CONTENT_DATA/Scripts/Core/terrain.lua"
BuilderWorld.enableSurface = false
BuilderWorld.enableAssets = true
BuilderWorld.enableClutter = true
BuilderWorld.enableNodes = true
BuilderWorld.enableCreations = true
BuilderWorld.enableHarvestables = true
BuilderWorld.enableKinematics = true
BuilderWorld.cellMinX = -6
BuilderWorld.cellMaxX = 5
BuilderWorld.cellMinY = -7
BuilderWorld.cellMaxY = 6

function BuilderWorld.server_onCreate( self )

	-- if not sm.world.isTargetWorld(self.world) then
	-- 	sm.event.sendToGame("sve_destroyWorld", self.world)
	-- 	self.waitingForDeath = true
	-- 	self.network:sendToClients("client_waitingForDeath")
	-- 	return
	-- end

	ChallengeBaseWorld.server_onCreate( self )
	self.unloadedCells = ( 1 + self.cellMaxX - self.cellMinX ) * ( 1 + self.cellMaxY - self.cellMinY )
	self.playerSpawners = {}
	self.buildAreaTriggers = {}
	sm.storage.saveAndSync( "levelSettings", self.data.settings or {} )
end

function BuilderWorld.server_onRefresh( self )
	print( "BuilderWorld.server_onRefresh" )
end

function BuilderWorld.server_onFixedUpdate( self )
	ChallengeBaseWorld.server_onFixedUpdate( self )

	-- Set builder restrictions
	local bodies = sm.body.getAllBodies()
	for _, body in ipairs( bodies ) do
		body:setBuildable( true )
		body:setErasable( true )
		body:setConnectable( true )
		body:setPaintable( true )
		body:setLiftable( true )
		body:setUsable( true )
		
		body:setDestructable( false )
		body:setConvertibleToDynamic( true )
	end
end

function BuilderWorld.server_onCellCreated( self, x, y )
	self.unloadedCells = self.unloadedCells - 1
	--print( "Cell ("..x..","..y..") loaded! "..self.unloadedCells.." left..." )
	if self.unloadedCells == 0 then
		sm.event.sendToGame("server_worldReadyForPlayers", self.world)
		--print("self.world", sm.exists(self.world), self.world)
		sm.event.sendToGame( "server_onCellLoadComplete", { world = self.world, x = x, y = y, fromBuild = true } )
		ChallengeBaseWorld.server_onFinishedCellLoading( self )
	end
end

function BuilderWorld.server_onInteractableCreated( self, interactable )
	ChallengeBaseWorld.server_onInteractableCreated( self, interactable )
	if( interactable.shape and interactable.shape.shapeUuid == obj_interactive_startposition ) then
		AddToArrayIfNotExists( self.playerSpawners, interactable )
	end
	if( interactable.shape and interactable.shape.shapeUuid == obj_interactive_buildarea ) then
		local filter = sm.areaTrigger.filter.dynamicBody + sm.areaTrigger.filter.staticBody -- Find static on the lift
		local halfSize = sm.vec3.new( 6, 4, 6 )
		self.buildAreaTriggers[tostring( interactable.id )] = sm.areaTrigger.createAttachedBox( interactable, halfSize, sm.vec3.new( 0, 4.5, 0 ), sm.quat.identity(), filter )
	end
end

function BuilderWorld.server_onInteractableDestroyed( self, interactable )
	ChallengeBaseWorld.server_onInteractableDestroyed( self, interactable )
	-- Can unly use simple checks like id compare since object is already destroyed
	removeFromArray( self.playerSpawners, function( value ) return value == interactable; end )
	if self.buildAreaTriggers[tostring( interactable.id )] ~= nil then
		self.buildAreaTriggers[tostring( interactable.id )] = nil
	end
end

-- (Event) Called from Game
function BuilderWorld.server_spawnNewCharacter( self, params )
	self:server_spawnCharacter( params )
end

-- (Event) Called from Game
function BuilderWorld.server_spawnCharacter( self, params )
	print( "World: spawnCharacter" )
	if params.inventory then g_inventoriesBuildMode = params.inventory end
	for _,player in ipairs( params.players ) do
		BuilderWorld.server_loadSpawners( self )
		CreateCharacterOnSpawner( self, self.world, player, self.playerSpawners, sm.vec3.new( 2, 2, 9.7 ), false, params.build )
		self:server_loadSavedInventory( player )
	end
end

function BuilderWorld.server_loadSpawners( self )
	self.playerSpawners = {}
	for _,body in pairs(sm.body.getAllBodies()) do
		for _,shape in pairs(body:getShapes()) do
			-- Find start positions
			if shape.uuid == obj_interactive_startposition then
				local spawner = shape:getInteractable()
				local spawnDir = -spawner.shape:getUp()
				table.insert(self.playerSpawners, {
					pos = spawner.shape.worldPosition + spawner.shape:getAt() * 0.825,
					pitch = math.asin( spawnDir.z ),
					yaw = math.atan2( spawnDir.x, -spawnDir.y )
				})
			end
		end
	end
end

function BuilderWorld.server_loadSavedInventory( self, player )
	if g_inventoriesBuildMode == nil then
		g_inventoriesBuildMode = {}
	end
	-- Set starting items in no items exist
	if g_inventoriesBuildMode[player.id] == nil then
		local inventoryList = {}
		
		for i = 1, player:getHotbar():getSize() do
			inventoryList[i] = { uuid = sm.uuid.getNil(), quantity = 0 }
		end

		-- Fill in the first hotbar
		inventoryList[1] = { uuid = blk_challenge01, quantity = 1 }
		inventoryList[2] = { uuid = blk_challenge02, quantity = 1 }
		inventoryList[3] = { uuid = obj_interactive_radio, quantity = 1 }
		inventoryList[4] = { uuid = obj_interactive_startposition, quantity = 1 }
		inventoryList[5] = { uuid = obj_interactive_buildarea, quantity = 1 }
		inventoryList[6] = { uuid = obj_interactive_goal, quantity = 1 }
		inventoryList[7] = { uuid = obj_interactive_challengechest, quantity = 1 }
		inventoryList[8] = { uuid = tool_weldtool, quantity = 1 }
		inventoryList[9] = { uuid = tool_lift_creative, quantity = 1 }
		inventoryList[10] = { uuid = tool_connecttool, quantity = 1 }
		
		g_inventoriesBuildMode[player.id] = inventoryList
	end

	-- Add to inventory
	local savedInventory = g_inventoriesBuildMode[player.id]
	if savedInventory then
		sm.container.beginTransaction()
		for i, slot in ipairs( savedInventory ) do
			sm.container.setItem( player:getHotbar(), i - 1, slot["uuid"], slot["quantity"] ) -- container is 0 indexed
		end
		sm.container.endTransaction()
	end

	-- Clear carry
	local carryContainer = player:getCarry()
	sm.container.beginTransaction()
	for i = 0, carryContainer:getSize() - 1 do
		sm.container.setItem( carryContainer, i, sm.uuid.getNil(), 0 )
	end
	sm.container.endTransaction()
end

-- (Event) Called from Game
function BuilderWorld.server_loadWorldContent( self, data )
	print( "World: loadWorldContent" )
	
	--Creations
	for _, creation in ipairs( g_savedCreations ) do
		local creation = sm.creation.importFromString( self.world, creation, sm.vec3.zero(), sm.quat.identity(), true, true )
		for _,body in ipairs(creation) do
			body.destructable = false
		end
	end
	
	sm.event.sendToGame( "server_onFinishedLoadContent" )
end

function BuilderWorld.server_export( self, data )
	local beginTime = os.clock()
	
	local levelCreations = sm.body.getCreationsFromBodies( sm.body.getAllBodies() )
	local startCreations = {}
	
	-- Add all creations in the build area triggers to startCreations
	for _, areaTrigger in pairs( self.buildAreaTriggers ) do
		local triggerCreations = sm.body.getCreationsFromBodies( areaTrigger:getContents() )
		for _, creation in ipairs( triggerCreations ) do
			startCreations[#startCreations + 1] = creation
		end
	end
	
	-- Filter out creations containing static bodies from startCreations
	removeFromArray( startCreations, function( creation )
		for _, body in ipairs( creation ) do
			if body:isStatic() and not body:isOnLift() then
				return true
			end
		end
		return false
	end )

	-- Put the startCreation bodies in a lookup table
	local startBodies = {}
	for _, creation in ipairs( startCreations ) do
		for _, body in ipairs( creation ) do
			startBodies[tostring( body.id )] = true
		end
	end

	-- Remove from levelCreations if found in startBodies
	removeFromArray( levelCreations, function( creation )
		return startBodies[tostring( creation[1].id )]
	end )

	print( "Exporting challenge level containing "..#levelCreations.." level creations and "..#startCreations.." start creations" )

	local challengeLevel = {}
	challengeLevel.data = {}
	challengeLevel.data.levelCreations = {}
	challengeLevel.data.startCreations = {}
	challengeLevel.data.tiles = { "$CONTENT_DATA/Terrain/Tiles/ChallengeBuilderDefault.tile" }
	challengeLevel.data.settings = sm.storage.load( "levelSettings" )

	local header = ""
	local topHeader = ""
	local packid = data.directory:sub(10)

	if not data.isLocal then
		if data.inPack then
			topHeader = "$CONTENT_DATA/Overrides/" .. packid .. "."
			header = topHeader .. data.uuid .. "."
		else
			header = "$CONTENT_DATA/Overrides/" .. data.uuid .. "."
			topHeader = header
		end
	else
		if data.inPack then
			topHeader = "$CONTENT_" .. packid .. "/"
			header = topHeader .. data.uuid .. "/"
		else
			header = "$CONTENT_" .. data.uuid .. "/"
			topHeader = header
		end
	end

	for i, creation in ipairs( levelCreations ) do
		challengeLevel.data.levelCreations[i] = header.."LevelCreation_"..i..".blueprint"

		local resolvedBlueprintPath = sm.json.checkPath( challengeLevel.data.levelCreations[i], data.isLocal )
		print( "Exporting '"..resolvedBlueprintPath.."'" )

		-- Replace with sm.creation.exportToFile?
		local blueprintJsonString = sm.creation.exportToString( creation[1], true, false ) -- First body, exportToString finds the rest
		local blueprint = sm.json.parseJsonString( blueprintJsonString )
		pcall(function()sm.json.save( blueprint, resolvedBlueprintPath, data.isLocal )end)
	end

	for i, creation in ipairs( startCreations ) do
		challengeLevel.data.startCreations[i] = header.."StartCreation_"..i..".blueprint"

		local resolvedBlueprintPath = sm.json.checkPath( challengeLevel.data.startCreations[i], data.isLocal )
		print( "Exporting '"..resolvedBlueprintPath.."'" )

		-- Replace with sm.creation.exportToFile?
		local blueprintJsonString = sm.creation.exportToString( creation[1], true, true ) -- First body, exportToString finds the rest
		local blueprint = sm.json.parseJsonString( blueprintJsonString )
		pcall(function()sm.json.save( blueprint, resolvedBlueprintPath, data.isLocal )end)
	end

	local challengeLevelPath = sm.json.checkPath( header.."challengeLevel.json", data.isLocal )
	print( "Exporting '"..challengeLevelPath.."'" )
	pcall(function()sm.json.save( challengeLevel, challengeLevelPath, data.isLocal )end)
	if data.inPack then
		challengeLevel.uuid = data.uuid
		sm.event.sendToGame("server_exportPackData", {level = challengeLevel, path = topHeader.."challengePack.json"})
	end
	sm.challenge.takePicturesForMenu()
	--sm.challenge.takePicture( 8192, 8192 )

	self.challengeLevel = challengeLevel

	local endTime = os.clock()
	local time = tostring(( endTime - beginTime ) * 1000)
	print( "Export time: "..time )
	if #time > 4 then time = string.sub(time, 1, 4) end
	sm.gui.chatMessage( "#fc7b03Level saved in: #09ff00".. time .. "ms#ffffff")
end

function BuilderWorld.server_test( self )
	sm.event.sendToGame( "server_startTest", self.challengeLevel.data )
end

function BuilderWorld.client_onCreate( self )
	ChallengeBaseWorld.client_onCreate( self )
	self.floorEffect = sm.effect.createEffect( "BuildMode - Floor" )
	self.floorEffect:start()
	--BuilderWorld.client_onRefresh( self )
end

function BuilderWorld.client_onDestroy( self )
	self.floorEffect:stop()
end

function BuilderWorld.client_showSetting( self, params )
	sm.gui.chatMessage( params )
end
