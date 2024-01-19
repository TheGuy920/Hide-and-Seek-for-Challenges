import os
import commentjson as json

game_directory = "F:\\SteamLibrary\\steamapps\\common\\Scrap Mechanic"
shape_sets_file = os.path.join(os.getcwd(), "Objects", "Database", "shapesets.shapedb")
master_file_path = os.path.join(os.getcwd(), "Objects", "Database", "ShapeSets", "master.json")

replacements = {
    "$GAME_DATA": os.path.join(game_directory, "Data"),
    "$SURVIVAL_DATA": os.path.join(game_directory, "Survival")
}

# Load master.json
with open(master_file_path, 'r') as master_file:
    master_data = json.load(master_file)

#master_part_uuids = {item['uuid'] for item in master_data['partList'] if isinstance(item, dict)}
master_block_uuids = {item['uuid'] for item in master_data['blockList'] if isinstance(item, dict)}

# Read shapesets.shapedb
with open(shape_sets_file, 'r') as f:
    shape_sets_data = json.load(f)

# Process each shapeset file
for shape_set in shape_sets_data.get('shapeSetList', []):
    original_path = shape_set
    # Replace with the appropriate path
    for k, v in replacements.items():
        shape_set = shape_set.replace(k, v)

    if os.path.exists(shape_set) and "$CONTENT_DATA" not in shape_set:  # Ignore $CONTENT_DATA paths
        with open(shape_set, 'r') as shape_file:
            shape_data = json.load(shape_file)

        # comment = f"// Content from {original_path}"
        # master_data['partList'].append(comment)
        # for part in shape_data.get('partList', []):
        #     part['stackSize'] = 10  # Ensure stackSize is set to 10
        #     if part['uuid'] not in master_uuids:  # If part not in master.json, add it.
        #         master_data['partList'].append(part)
        #         master_uuids.add(part['uuid'])

        # Add comments and blocks to blockList
        # block_comment = f"// Blocks Content from {original_path}"
        # master_data['blockList'].append(block_comment)
        # for block in shape_data.get('blockList', []):
        #     block['stackSize'] = 500  # Ensure stackSize is set to 500
        #     if block['uuid'] not in master_block_uuids:  # If block not in master.json, add it.
        #         master_data['blockList'].append(block)
        #         master_block_uuids.add(block['uuid'])


# Write the updated master.json
with open(master_file_path, 'w') as master_file:
    json.dump(master_data, master_file, indent=4)