extends Node2D
 
var next_node_id: int = 0
var radius = 48
var adjacency_list: Dictionary = {}
var selected_nodes = []
var lines = []
var is_dijkstrated = false
var distance
@onready var nodes_container = $Nodes

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and !$UI/Button.is_hovered():
		if is_dijkstrated:
			deselect_nodes()
			unpaint_lines()
			is_dijkstrated = false
		if is_placeable(event.position):
			add_node(event.position)
		else:
			var node = is_node_clicked_get(event.position)
			if node != null:
				if !selected_nodes.has(node):
					if selected_nodes.size() == 2:
						$UI/Button.disabled = true
						$UI/LineEdit.visible = false
						deselect_nodes()
					paint_node_green(node)
					selected_nodes.append(node)
					if selected_nodes.size() == 2:
						$UI/Button.disabled = false
						open_edge_weight_dialog()
				elif selected_nodes.size() == 2:
					$UI/LineEdit.visible = false
					$UI/Button.disabled = true
					deselect_nodes()
					paint_node_green(node)
					selected_nodes.append(node)			

func _draw() -> void:	 		
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color.STEEL_BLUE)
	for line in lines:
		draw_line(line[0], line[1], line[2], 2.5, true) 
		var mid_position = (line[0] + line[1]) / 2
		mid_position.y = mid_position.y - 5
		draw_string($UI/LineEdit.get_theme_default_font(), mid_position, str(line[3]), HORIZONTAL_ALIGNMENT_CENTER, -1, 26)
		
func is_placeable(position: Vector2):
	var space = 40
		
	for node in nodes_container.get_children():
		distance = node.global_position.distance_to(position)
		if distance <= 2 * radius + space: # fiz a conta ilustrando como seria com duas bolas e considerando o raio de cada bola (48px)
			return false
	return true

func is_node_clicked_get(position: Vector2):
	for node in nodes_container.get_children():
		distance = node.global_position.distance_to(position)
		if distance <= radius:
			return node
	return null
	
func paint_node_green(node: Node2D):
	node.get_child(0).texture = load("res://assets/green_circle.png")

func paint_node_white(node: Node2D):
	node.get_child(0).texture = load("res://assets/white_circle.png")	
		
func add_node(position: Vector2):
	var node_scene = load(("res://scenes/node.tscn")).instantiate()
	node_scene.position = position
	node_scene.set_id(next_node_id)
	node_scene.get_node("Label").text = str(next_node_id)
	nodes_container.add_child(node_scene)
	adjacency_list[node_scene] = []
	next_node_id += 1

func open_edge_weight_dialog():
	var position_node1 = selected_nodes[0].global_position
	var position_node2 = selected_nodes[1].global_position
	var position = (position_node1 + position_node2) / 2
	$UI/LineEdit.set_position(position)
	$UI/LineEdit.text = ""
	$UI/LineEdit.visible = true
	$UI/LineEdit.grab_focus()

func _on_line_edit_text_submitted(weight: String) -> void:
	if !weight.is_empty() and (!weight.is_valid_float() or float(weight) < 0):
		$UI/LineEdit.text = ""
		return	
	var node1 = selected_nodes[0]
	var node2 = selected_nodes[1]
	if weight.is_empty():
		for edge1 in adjacency_list[node1]:
			if edge1[0] == node2:
				adjacency_list[node1].erase(edge1)
				for edge2 in adjacency_list[node2]:
					if edge2[0] == node1:
						adjacency_list[node2].erase(edge2)
						for line in lines:
							if line.has(node1.global_position) and line.has(node2.global_position):
								lines.erase(line)
								hide_box_and_default()
								queue_redraw()
								return
		hide_box_and_default()
		return	
		
	$UI/LineEdit.text = weight
	$UI/LineEdit.visible = false
	add_edge(node1, node2, float(weight))
	deselect_nodes()
	queue_redraw()

func hide_box_and_default():
	$UI/LineEdit.visible = false
	$UI/Button.disabled = true
	deselect_nodes()
	
func add_edge(node1: Node2D, node2: Node2D, weight: float):
	$UI/Button.disabled = true
	for edge1 in adjacency_list[node1]:
		if edge1[0] == node2:
			edge1[1] = weight
			for edge2 in adjacency_list[node2]:
				if edge2[0] == node1:
					edge2[1] = weight
					for line in lines:
						if line.has(node1.global_position) and line.has(node2.global_position):
							line[3] = str(weight)
							return
	
	adjacency_list[node1].append([node2, weight])
	adjacency_list[node2].append([node1, weight])
	lines.append([node1.global_position, node2.global_position, Color.BLACK, weight])
	
func dijkstra(start: Node2D, end: Node2D) -> Array:
	if start not in adjacency_list or end not in adjacency_list:
		push_error("Start and end nodes must be in the graph")
		return []

	var visited = []
	var predecessors = {}
	var distance_from_start = {}

	for node in adjacency_list.keys():
		distance_from_start[node] = INF
	distance_from_start[start] = 0

	while distance_from_start.keys().size() > 0:
		var smallest_distance = INF
		var current_node = -1
		for node in distance_from_start.keys():
			if distance_from_start[node] < smallest_distance:
				smallest_distance = distance_from_start[node]
				current_node = node

		distance_from_start.erase(current_node)
		visited.append(current_node)

		if current_node == end:
			var path = [current_node]
			while current_node != start:
				current_node = predecessors[current_node]
				path.insert(0, current_node)
			return path

		for neighbor_data in adjacency_list[current_node]:
			var neighbor = neighbor_data[0]
			var weight = neighbor_data[1]
			if neighbor not in visited:
				var new_distance = smallest_distance + weight
				if new_distance < distance_from_start[neighbor]:
					distance_from_start[neighbor] = new_distance
					predecessors[neighbor] = current_node
	return [] 
	
func deselect_nodes():
	for node in selected_nodes:
		paint_node_white(node)
	selected_nodes = []
	
func unpaint_lines():
	for line in lines:
		line[2] = Color.BLACK
	queue_redraw()
	
func _on_button_pressed() -> void:
	$UI/LineEdit.visible = false
	$UI/Button.disabled = true
	for node in selected_nodes:
		if adjacency_list[node].size() == 0:
			deselect_nodes()
			return
	var path_result = dijkstra(selected_nodes[0], selected_nodes[1])
	for line in lines:
		for i in range(path_result.size() - 1):
			var node1 = path_result[i]
			var node2 = path_result[i + 1]
			if line.has(node1.global_position) and line.has(node2.global_position):
				line[2] = Color.GREEN
	queue_redraw()
	is_dijkstrated = true
