function getCreationsShapeCount( creations )

	local usedShapes = {}
	for _, blueprintObject in ipairs( creations ) do

		-- Count joints used in the blueprint
		if blueprintObject.joints then
			for _, joint in ipairs( blueprintObject.joints ) do
				if usedShapes[joint.shapeId] == nil then
					usedShapes[joint.shapeId] = 0
				end
				usedShapes[joint.shapeId] = usedShapes[joint.shapeId] + 1
			end
		end
		
		-- Count parts and blocks used in the blueprint
		if blueprintObject.bodies then
			for _, body in ipairs( blueprintObject.bodies ) do
				if body.childs then
					for _, child in ipairs( body.childs ) do
						if child.bounds then
							if usedShapes[child.shapeId] == nil then
								usedShapes[child.shapeId] = 0
							end
							usedShapes[child.shapeId] = usedShapes[child.shapeId] + child.bounds.x * child.bounds.y * child.bounds.z
						else
							if usedShapes[child.shapeId] == nil then
								usedShapes[child.shapeId] = 0
							end
							usedShapes[child.shapeId] = usedShapes[child.shapeId] + 1
						end									
					end
				end
			end
		end
	end
	
	return usedShapes
end

function resolveContentPaths( levelData )
	print( "Resolving content paths" )
	if levelData.levelCreations ~= nil then
		for i,path in ipairs( levelData.levelCreations ) do
			local success, exists = pcall(sm.json.fileExists, path)
			if not success or not exists then
				path = sm.challenge.resolveContentPath(path)
			end
			levelData.levelCreations[i] = path
		end
	end
	if levelData.startCreations ~= nil then
		for i,path in ipairs( levelData.startCreations ) do
			local success, exists = pcall(sm.json.fileExists, path)
			if not success or not exists then
				path = sm.challenge.resolveContentPath(path)
			end
			levelData.startCreations[i] = path
		end
	end
	if levelData.tiles ~= nil then
		for i,path in ipairs( levelData.tiles ) do
			local success, exists = pcall(sm.json.fileExists, path)
			if not success or not exists then
				path = sm.challenge.resolveContentPath(path)
			end
			levelData.tiles[i] = path
		end
	end
	if type(levelData) == "string" then
		return sm.challenge.resolveContentPath(levelData)
	end
end

function isFinalLevel( play )
	if play then
		return play.currentLevelIndex == #play.levelList
	end
	return true
end
