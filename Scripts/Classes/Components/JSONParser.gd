class_name JSONParser extends Object

# By DawnLR but nobody cares

## Parse the file to a dictionary using the path to the file.
static func parse_to_dict(file_path: String) -> Dictionary:
	# Don't load the file if it doesn't exist.
	if (!FileAccess.file_exists(file_path)):
		printerr("\"%s\" is not a existing file!" % file_path)
		return {}
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	if (file == null):
		# This method finds the error for the latest opened file, returning a value from the error enum.
		var file_error := FileAccess.get_open_error()

		Global.log_error("Mod File not opened: \"%s\", an error has occured.\nCODE: %s" % [file_path, error_string(file_error)])
		return {}

	var json_str := file.get_as_text()
	file.close()
	
	return parse_string(file_path, json_str)

## Parse the string to a dictionary, skipping the file reading part.
static func parse_string(file_path: String, json_str: String) -> Dictionary:
	var json_obj := JSON.new()
	var json_error = json_obj.parse(json_str)
	
	# Parsing from an object returns to us an error code, but keep the data to itself.
	if (json_error == OK):
		return json_obj.data
	else:
		# This error is given if something is wrong with the json, the rest is treated to the script that asked for it.
		Global.log_error("Error parsing JSON file at path \"%s\"! %s at line %s." % [file_path, json_obj.get_error_message(), json_obj.get_error_line()])
		return {}

## Save the provided data into a file. If the data is not String, it will be stringified first.
static func save_to_file(data: Variant, saving_path: String) -> Error:
	if (data is not String):
		# We almost always use Dictionaries anyways LOL!
		data = JSON.stringify(data, "\t", false)
	
	var file := FileAccess.open(saving_path, FileAccess.WRITE)
	
	# Don't load the file if you... can't.
	if (file == null):
		var file_error := FileAccess.get_open_error()
		Global.log_error("File couldn't be created: \"%s\", an error has occured.\nCODE: %s" % [saving_path, error_string(file_error)])
		
		return file_error
	
	file.store_string(data)
	file.close()
	
	return OK
