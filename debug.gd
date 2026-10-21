extends Control
class_name DebugHelper

func build_minimap(game: Game) -> void:
	var image := Image.create_empty(game.map.cities.size(), game.map.cities.size(), false, Image.FORMAT_RGBA8)
	
	for row in game.map.cities.size():
		for column in game.map.cities[row].size():
			
			if game.map.cities[row][column] == null:
				image.set_pixel(row, column, Color.BLACK)
			else:
				var connection_count: int = game.map.cities[row][column].connections_from.size() + game.map.cities[row][column].connections_to.size()
				image.set_pixel(row, column, Color(Color.WHITE, connection_count / 10.0))
	
	%MiniMap.texture = ImageTexture.create_from_image(image)
