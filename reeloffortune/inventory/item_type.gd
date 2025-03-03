class_name ItemType
extends Resource

@export var name: String
@export var item_size: Vector2i = Vector2i(1, 1)
@export var attributes: ItemAttributes
@export var sprite: Texture

@export var breakdown: Array[ItemType]

static func _get_all_file_paths(path: String) -> Array[String]:  
	var file_paths: Array[String] = []  
	var dir = DirAccess.open(path)  
	dir.list_dir_begin()  
	var file_name = dir.get_next()  
	while file_name != "":  
		var file_path = path + "/" + file_name  
		if dir.current_is_dir():  
			file_paths += _get_all_file_paths(file_path)  
		else:  
			file_paths.append(file_path)  
		file_name = dir.get_next()  
	return file_paths

static func load_all() -> Array[ItemType]:
	var items: Array[ItemType] = []
	var paths = _get_all_file_paths("res://inventory/items")
	for path in paths:
		items.append(load(path))
	return items
