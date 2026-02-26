class_name ModLoaderCurrentOptions
extends Resource

# The default options set for the mod loader
@export var current_options: Resource = load("res://addons/mod_loader/options/profiles/default.tres")


# Overrides for all available feature tags through OS.has_feature()
# Format: Dictionary[String: ModLoaderOptionsProfile] where the string is a tag
# Warning: Some tags can occur at the same time (Windows + editor for example) -
# In a case where multiple apply, the last one in the dict will override all others
var editorRes = load("res://addons/mod_loader/options/profiles/editor.tres")
@export var feature_override_options: Dictionary = {
	"editor": editorRes
}
