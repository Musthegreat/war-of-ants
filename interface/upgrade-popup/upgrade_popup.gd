extends Control
class_name UpgradePopup

var selected_city: City

func _ready() -> void:
	%Cancel.pressed.connect(hide)
	%Factory.pressed.connect(_upgrade.bind(City.TYPE.factory))
	%PowerPlant.pressed.connect(_upgrade.bind(City.TYPE.powerplant))
	%Fort.pressed.connect(_upgrade.bind(City.TYPE.fort))
	%Artillery.pressed.connect(_upgrade.bind(City.TYPE.artillery))

func _upgrade(type: City.TYPE) -> void:
	if selected_city.is_multiplayer_authority():
		selected_city.attempt_upgrade.rpc(type)
	
	hide()
