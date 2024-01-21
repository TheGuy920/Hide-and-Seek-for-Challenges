CELL_SIZE = 64

DESERT_FADE_RANGE = 128
DESERT_FADE_START = 512
DESERT_FADE_END = DESERT_FADE_START + DESERT_FADE_RANGE
BARRIER_START = 704
BARRIER_END = 704 + 64

function Init()
	print( "Init terrain" )
end

function Create( xMin, xMax, yMin, yMax, seed, data )

	g_uuidToPath = {}
	g_cellData = {
		bounds = { xMin = xMin, xMax = xMax, yMin = yMin, yMax = yMax },
		seed = seed,
		-- Per Cell
		uid = {},
		xOffset = {},
		yOffset = {},
		rotation = {}
	}

	for cellY = yMin, yMax do
		g_cellData.uid[cellY] = {}
		g_cellData.xOffset[cellY] = {}
		g_cellData.yOffset[cellY] = {}
		g_cellData.rotation[cellY] = {}

		for cellX = xMin, xMax do
			g_cellData.uid[cellY][cellX] = sm.uuid.getNil()
			g_cellData.xOffset[cellY][cellX] = 0
			g_cellData.yOffset[cellY][cellX] = 0
			g_cellData.rotation[cellY][cellX] = 0
		end
	end
	--print(yMin, yMax, xMin, xMax)
	local jWorld = sm.json.open( "$CONTENT_DATA/Terrain/Worlds/example.world")
	for _, cell in pairs( jWorld.cellData ) do
		if cell.path ~= "" then
			local uid = sm.terrainTile.getTileUuid( cell.path )
			--print(cell.y, cell.x)
			g_cellData.uid[cell.y][cell.x] = uid
			g_cellData.xOffset[cell.y][cell.x] = cell.offsetX
			g_cellData.yOffset[cell.y][cell.x] = cell.offsetY
			g_cellData.rotation[cell.y][cell.x] = cell.rotation

			g_uuidToPath[tostring(uid)] = cell.path
		end
	end

	sm.terrainData.save( { g_uuidToPath, g_cellData } )
end

function Load()
	if sm.terrainData.exists() then
		local data = sm.terrainData.load()
		g_uuidToPath = data[1]
		g_cellData = data[2]
		return true
	end
	return false
end

function GetTilePath( uid )
	if not uid:isNil() then
		return g_uuidToPath[tostring(uid)]
	end
	return ""
end

function GetCellTileUidAndOffset( cellX, cellY )
	if InsideCellBounds( cellX, cellY ) then
		return	g_cellData.uid[cellY][cellX],
				g_cellData.xOffset[cellY][cellX],
				g_cellData.yOffset[cellY][cellX]
	end
	return sm.uuid.getNil(), 0, 0
end

function GetTileLoadParamsFromWorldPos( x, y, lod )
	local cellX, cellY = GetCell( x, y )
	local uid, tileCellOffsetX, tileCellOffsetY = GetCellTileUidAndOffset( cellX, cellY )
	local rx, ry = InverseRotateLocal( cellX, cellY, x - cellX * CELL_SIZE, y - cellY * CELL_SIZE )
	if lod then
		return  uid, tileCellOffsetX, tileCellOffsetY, lod, rx, ry
	else
		return  uid, tileCellOffsetX, tileCellOffsetY, rx, ry
	end
end

function GetTileLoadParamsFromCellPos( cellX, cellY, lod )
	local uid, tileCellOffsetX, tileCellOffsetY = GetCellTileUidAndOffset( cellX, cellY )
	if lod then
		return  uid, tileCellOffsetX, tileCellOffsetY, lod
	else
		return  uid, tileCellOffsetX, tileCellOffsetY
	end
end

function GetHeightAt( x, y, lod )
	return sm.terrainTile.getHeightAt( GetTileLoadParamsFromWorldPos( x, y, lod ) )
end

--[[
function GetColorAt( x, y, lod )
	return sm.terrainTile.getColorAt( GetTileLoadParamsFromWorldPos( x, y, lod ) )
end
]]

function getCell( x, y )
	return math.floor( x / CELL_SIZE), math.floor( y / CELL_SIZE )
end

function GetColorAt( x, y, lod )
	local cellX, cellY = getCell( x, y )
	local uid, tileCellOffsetX, tileCellOffsetY = GetCellTileUidAndOffset( cellX, cellY )

	local r, g, b = sm.terrainTile.getColorAt( uid, tileCellOffsetX, tileCellOffsetY, lod, x - cellX * CELL_SIZE, y - cellY * CELL_SIZE )

	local noise = sm.noise.octaveNoise2d( x / 8, y / 8, 5, 45 )
	local brightness = noise * 0.25 + 0.75
	local color = { r, g, b }
	
	local desertColor = { 255 / 255, 171 / 255, 111 / 255 }
	
	local maxDist = math.max( math.abs(x), math.abs(y) )
	if maxDist >= DESERT_FADE_END then
		color[1] = desertColor[1]
		color[2] = desertColor[2]
		color[3] = desertColor[3]
	else
		if maxDist > DESERT_FADE_START then
			local fade = ( maxDist - DESERT_FADE_START ) / DESERT_FADE_RANGE
			color[1] = color[1] + ( desertColor[1] - color[1] ) * fade
			color[2] = color[2] + ( desertColor[2] - color[2] ) * fade
			color[3] = color[3] + ( desertColor[3] - color[3] ) * fade
		end
	end

	return color[1] * brightness, color[2] * brightness, color[3] * brightness
end


function GetMaterialAt( x, y, lod )
	return sm.terrainTile.getMaterialAt( GetTileLoadParamsFromWorldPos( x, y, lod ) )
end
--[[
function GetClutterIdxAt( x, y )
	return sm.terrainTile.getClutterIdxAt( GetTileLoadParamsFromWorldPos( x, y ) )
end
]]

function GetClutterIdxAt( x, y )
	local cellX = math.floor( x / ( CELL_SIZE * 2 ) )
	local cellY = math.floor( y / ( CELL_SIZE * 2 ) )
	local uid, tileCellOffsetX, tileCellOffsetY = GetCellTileUidAndOffset( cellX, cellY )

	local rx, ry = InverseRotateLocal( cellX, cellY, x - cellX * CELL_SIZE * 2, y - cellY * CELL_SIZE * 2, CELL_SIZE * 2 - 1 )

	local clutterIdx = sm.terrainTile.getClutterIdxAt( uid, tileCellOffsetX, tileCellOffsetY, rx, ry )
	return clutterIdx
end

function GetAssetsForCell( cellX, cellY, lod )
	local assets = sm.terrainTile.getAssetsForCell( GetTileLoadParamsFromCellPos( cellX, cellY, lod ) )
	for _, asset in ipairs( assets ) do
		local rx, ry = RotateLocal( cellX, cellY, asset.pos.x, asset.pos.y )
		asset.pos = sm.vec3.new( rx, ry, asset.pos.z )
		asset.rot = GetRotationQuat( cellX, cellY ) * asset.rot
	end
	return assets
end

function GetNodesForCell( cellX, cellY )
	local nodes = sm.terrainTile.getNodesForCell( GetTileLoadParamsFromCellPos( cellX, cellY ) )
	for _, node in ipairs( nodes ) do
		local rx, ry = RotateLocal( cellX, cellY, node.pos.x, node.pos.y )
		node.pos = sm.vec3.new( rx, ry, node.pos.z )
		node.rot = GetRotationQuat( cellX, cellY ) * node.rot
	end
	return nodes
end

function GetCreationsForCell( cellX, cellY )
	local uid, tileCellOffsetX, tileCellOffsetY = GetCellTileUidAndOffset( cellX, cellY )
	if not uid:isNil() then
		local cellCreations = sm.terrainTile.getCreationsForCell( uid, tileCellOffsetX, tileCellOffsetY )
		for i,creation in ipairs( cellCreations ) do
			local rx, ry = RotateLocal( cellX, cellY, creation.pos.x, creation.pos.y )

			creation.pos = sm.vec3.new( rx, ry, creation.pos.z )
			creation.rot = GetRotationQuat( cellX, cellY ) * creation.rot
		end

		return cellCreations
	end

	return {}
end

function GetHarvestablesForCell( cellX, cellY, lod )
	local harvestables = sm.terrainTile.getHarvestablesForCell( GetTileLoadParamsFromCellPos( cellX, cellY, lod ) )
	for _, harvestable in ipairs( harvestables ) do
		local rx, ry = RotateLocal( cellX, cellY, harvestable.pos.x, harvestable.pos.y )
		harvestable.pos = sm.vec3.new( rx, ry, harvestable.pos.z )
		harvestable.rot = GetRotationQuat( cellX, cellY ) * harvestable.rot
	end
	return harvestables
end

function GetKinematicsForCell( cellX, cellY, lod )
	local kinematics = sm.terrainTile.getKinematicsForCell( GetTileLoadParamsFromCellPos( cellX, cellY, lod ) )
	for _, kinematic in ipairs( kinematics ) do
		local rx, ry = RotateLocal( cellX, cellY, kinematic.pos.x, kinematic.pos.y )
		kinematic.pos = sm.vec3.new( rx, ry, kinematic.pos.z )
		kinematic.rot = GetRotationQuat( cellX, cellY ) * kinematic.rot
	end
	return kinematics
end

function GetDecalsForCell( cellX, cellY, lod )
	local decals = sm.terrainTile.getDecalsForCell( GetTileLoadParamsFromCellPos( cellX, cellY, lod ) )
	for _, decal in ipairs( decals ) do
		local rx, ry = RotateLocal( cellX, cellY, decal.pos.x, decal.pos.y )
		decal.pos = sm.vec3.new( rx, ry, decal.pos.z )
		decal.rot = GetRotationQuat( cellX, cellY ) * decal.rot
	end
	return decals
end






----------------------------------------------------------------------------------------------------
-- Utility
----------------------------------------------------------------------------------------------------

CELL_SIZE = 64

function InsideCellBounds( cellX, cellY )
	if cellX < g_cellData.bounds.xMin or cellX >g_cellData.bounds.xMax then
		return false
	elseif cellY < g_cellData.bounds.yMin or cellY >g_cellData.bounds.yMax then
		return false
	end
	return true
end

----------------------------------------------------------------------------------------------------

function GetClosestCorner( x, y )
	return math.floor( x / CELL_SIZE + 0.5 ), math.floor( y / CELL_SIZE + 0.5 )
end

----------------------------------------------------------------------------------------------------

function GetCell( x, y )
	return math.floor( x / CELL_SIZE ), math.floor( y / CELL_SIZE )
end

----------------------------------------------------------------------------------------------------

function GetFraction( x, y )
	local cellX, cellY = GetCell( x, y )
	return x / CELL_SIZE - cellX, y / CELL_SIZE - cellY
end

----------------------------------------------------------------------------------------------------

function GetCellRotation( cellX, cellY )
	if InsideCellBounds( cellX, cellY ) then
		if g_cellData.rotation then
			if g_cellData.rotation[cellY] then
				return g_cellData.rotation[cellY][cellX]
			end
		end
	end
	return 0
end

----------------------------------------------------------------------------------------------------

function RotateLocal( cellX, cellY, x, y, cellSize )
	cellSize = cellSize or CELL_SIZE

	local rotation = GetCellRotation( cellX, cellY )

	local rx, ry
	if rotation == 1 then
		rx = cellSize - y
		ry = x
	elseif rotation == 2 then
		rx = cellSize - x
		ry = cellSize - y
	elseif rotation == 3 then
		rx = y
		ry = cellSize - x
	else
		rx = x
		ry = y
	end

	return rx, ry
end

----------------------------------------------------------------------------------------------------

function InverseRotateLocal( cellX, cellY, x, y, cellSize )
	cellSize = cellSize or CELL_SIZE

	local rotation = GetCellRotation( cellX, cellY )

	local rx, ry
	if rotation == 1 then
		rx = y
		ry = cellSize - x
	elseif rotation == 2 then
		rx = cellSize - x
		ry = cellSize - y
	elseif rotation == 3 then
		rx = cellSize - y
		ry = x
	else
		rx = x
		ry = y
	end

	return rx, ry
end

----------------------------------------------------------------------------------------------------

function GetRotationQuat( cellX, cellY )
	local rotation = GetCellRotation( cellX, cellY )
	if rotation == 1 then
		return sm.quat.new( 0, 0, 0.70710678118654752440084436210485, 0.70710678118654752440084436210485 )
	elseif rotation == 2 then
		return sm.quat.new( 0, 0, 1, 0 )
	elseif rotation == 3 then
		return sm.quat.new( 0, 0, -0.70710678118654752440084436210485, 0.70710678118654752440084436210485 )
	end

	return sm.quat.new( 0, 0, 0, 1 )
end

----------------------------------------------------------------------------------------------------

function SquareDistance( x0, y0, x1, y1 )
	return ( x0 - x1 )^2 + ( y0 - y1 )^2
end

----------------------------------------------------------------------------------------------------

function Distance( x0, y0, x1, y1 )
	return math.sqrt( dist2( x0, y0, x1, y1 ) )
end

----------------------------------------------------------------------------------------------------

function ValueExists( array, value )
	for _, v in ipairs( array ) do
		if v == value then
			return true
		end
	end
	return false
end

----------------------------------------------------------------------------------------------------

function CreateReflectionNode( z )
	return {
		pos = sm.vec3.new( 32, 32, z ),
		rot = sm.quat.new( 0.707107, 0, 0, 0.707107 ),
		scale = sm.vec3.new( 64, 64, 64 ),
		tags = { "REFLECTION" }
	}
end

----------------------------------------------------------------------------------------------------

-- Rotate local foreign connections
function RotateLocalWaypoint( cellX, cellY, node )
	local rotationStep = GetCellRotation( cellX, cellY )
	if rotationStep ~= 0 and ValueExists( node.tags, "WAYPOINT" ) then
		for _, other in ipairs( node.params.connections.otherIds ) do
			if ( type(other) == "table" ) and other.cell then
				local cx = other.cell[1]
				local cy = other.cell[2]
				if rotationStep == 1 then
					other.cell[1] = -cy
					other.cell[2] = cx
				elseif rotationStep == 2 then
					other.cell[1] = -cx
					other.cell[2] = -cy
				elseif rotationStep == 3 then
					other.cell[1] = cy
					other.cell[2] = -cx
				end
			end
		end
	end
end

function CalculateTileStorageKey( worldId, cellX, cellY )
	local rotation = g_cellData.rotation[cellY][cellX]
	local xOffset = g_cellData.xOffset[cellY][cellX]
	local yOffset = g_cellData.yOffset[cellY][cellX]

	local rx, ry
	if rotation == 1 then
		rx = -yOffset
		ry = xOffset
	elseif rotation == 2 then
		rx = -xOffset
		ry = -yOffset
	elseif rotation == 3 then
		rx = yOffset
		ry = -xOffset
	else
		rx = xOffset
		ry = yOffset
	end

	local tx = cellX - rx
	local ty = cellY - ry

	--local x = cellX * 64 + 32
	--local y = cellY * 64 + 32
	--local z = getElevationHeightAt( x, y ) + getCliffHeightAt( x, y )
	--local fromPosition = sm.vec3.new( x, y, z )
	--local toPosition = sm.vec3.new( tx * 64 + 32, ty * 64 + 32, z )
	--local color = sm.color.new( 0, 0, 1 )
	--sm.debugDraw.addArrow( "Kin"..cellX..","..cellY, fromPosition, toPosition, color )

	return "ts_"..worldId..":("..tx..","..ty..")"
end
