extends Resource
class_name Map

var cities: Array

static func new_city() -> Dictionary:
	var data := {
		"uid": randi(),
		"position": Vector2.ZERO,
		"jitter": Vector2.ZERO,
		"type": 0,
		"ownership": "",
		"connections_from": [],
		"connections_to": [],
		"troops": 25
	}
	return data

func find_city_template(uid: int) -> Dictionary:
	for row in cities.size():
		for column in cities[row].size():
			if cities[row][column] == null:
				continue
			
			if cities[row][column].uid == uid:
				return cities[row][column]
	return {}
