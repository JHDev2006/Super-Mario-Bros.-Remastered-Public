class_name ModUserProfile
extends Resource
## This Class is used to represent a User Profile for the ModLoader.


## The name of the profile
var name := ""
## A list of all installed mods
## [codeblock]
## "mod_list": {
##     "Namespace-ModName": {
##         "current_config": "default",
##         "is_active": false,
##         "zip_path": "",
##     },
## [/codeblock]
var mod_list := {}


func _init(_name := "", _mod_list := {}) -> void:
	name = _name
	mod_list = _mod_list
