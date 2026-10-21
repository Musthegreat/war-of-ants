extends AStar2D
class_name CustomAStar2D

func _compute_cost(u, v):
	var u_pos = get_point_position(u)
	var v_pos = get_point_position(v)
	return u_pos.distance_squared_to(v_pos)
	#abs(u_pos.x - v_pos.x) + abs(u_pos.y - v_pos.y)

func _estimate_cost(u, v):
	var u_pos = get_point_position(u)
	var v_pos = get_point_position(v)
	return u_pos.distance_squared_to(v_pos)#abs(u_pos.x - v_pos.x) + abs(u_pos.y - v_pos.y)
