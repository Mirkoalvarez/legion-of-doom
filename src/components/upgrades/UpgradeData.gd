extends Resource
class_name UpgradeData

@export var id: String
@export var name: String
@export var desc: String = ""
@export_enum("stat", "flag", "active") var type: String = "stat"
# Diccionario de efectos clave -> valor (ver UpgradeManager.apply_upgrade)
@export var effects: Dictionary = {}
