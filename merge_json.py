import json

def merge_json_files(file_paths):
    merged_dict = {}

    for file_path in file_paths:
        with open(file_path, 'r') as file:
            current_dict = json.load(file)

            for key, value in current_dict.items():
                if key in merged_dict:
                    if isinstance(value, list) and isinstance(merged_dict[key], list):
                        merged_dict[key] = merge_lists(merged_dict[key], value)
                    elif isinstance(value, dict) and isinstance(merged_dict[key], dict):
                        merged_dict[key] = json.loads(merge_jsons(json.dumps(merged_dict[key]), json.dumps(value)))
                    else:
                        merged_dict[key] = value
                else:
                    merged_dict[key] = value

    return json.dumps(merged_dict, indent=2)

def merge_jsons(json_str1, json_str2):
    dict1 = json.loads(json_str1)
    dict2 = json.loads(json_str2)
    merged_dict = {**dict1, **dict2}

    for key, value in merged_dict.items():
        if key in dict1 and key in dict2:
            if isinstance(dict1[key], list) and isinstance(dict2[key], list):
                merged_dict[key] = merge_lists(dict1[key], dict2[key])
            elif isinstance(dict1[key], dict) and isinstance(dict2[key], dict):
                merged_dict[key] = json.loads(merge_jsons(json.dumps(dict1[key]), json.dumps(dict2[key])))

    return json.dumps(merged_dict)

def merge_lists(list1, list2):
    result = []
    asset_set_map = {}

    for item in list1 + list2:
        if isinstance(item, dict) and 'assetSet' in item:
            asset_set = item['assetSet']
            if asset_set not in asset_set_map:
                asset_set_map[asset_set] = item
            else:
                # Merge categories if it exists
                if 'categories' in item and isinstance(item['categories'], list):
                    existing_categories = asset_set_map[asset_set].get('categories', [])
                    merged_categories = list(set(existing_categories + item['categories']))
                    asset_set_map[asset_set]['categories'] = merged_categories
        else:
            result.append(item)  # Append non-dict items directly

    result.extend(asset_set_map.values())
    return result

# Example usage
file_paths = [
    r'F:\SteamLibrary\steamapps\common\Scrap Mechanic\Data\Terrain\Database\assetsets.json',
    r'C:\Users\Matthew\AppData\Roaming\Axolot Games\Scrap Mechanic\User\User_76561198299556567\Mods\Hide and Seek for Challenges\Terrain\Database\assetsets.assetdb',
    r'F:\SteamLibrary\steamapps\common\Scrap Mechanic\Survival\Terrain\Database\assetsets.json'
]
merged_json = merge_json_files(file_paths)
print(merged_json)
