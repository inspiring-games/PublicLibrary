class_name BlackHole
extends Area2D

@export var growth_speed = 30.0  # How fast the black hole grows.
@export var pull_strength = 5.0  # Strength of the pull towards the black hole.
@export var max_radius = 200.0  # Maximum influence radius.
@export var min_radius = 10.0  # Start influence radius.

var current_radius = min_radius  # Current influence radius.

@onready var black_hole_shader = $BlackHoleShader

func _physics_process(delta: float) -> void:
	# Grow the black hole radius over time.
	current_radius += growth_speed * delta
	if current_radius > max_radius:
		current_radius = max_radius

	# Update the collision shape (radius of influence).
	self.scale = Vector2(1,1) * (current_radius / 50)
	# Pull objects towards the center and scale them down.
	for body in get_overlapping_bodies():
		if body.get_parent() is PathFollow2D:
			var level_node:Node = Globals.find_level(body)
			if level_node:
				var child_pos = body.global_position
				body.get_parent().remove_child(body)
				level_node.add_child(body)
				body.global_position = child_pos
		if body is Rocket and (body as Rocket).status == Rocket.ROCKET_STATUS.running:
			(body as Rocket).status = Rocket.ROCKET_STATUS.blackhole
			
		if body is CharacterBody2D and body.visible:
			pull_object(body, delta)

func get_body_radius(body: CharacterBody2D) -> float:
	for child in body.get_children():
		if child is CollisionShape2D and child.shape is CircleShape2D:
			return child.shape.radius
	return 0.0


func pull_object(body: CharacterBody2D, delta: float) -> void:
	if body is Rocket and (body as Rocket).status not in [Rocket.ROCKET_STATUS.running,Rocket.ROCKET_STATUS.blackhole]:
		return #dont swallow rockets not running
	var direction = global_position - body.global_position
	var distance = direction.length()
	var body_radius = Globals.get_widest_collision_shape(body)
	var effect_area = (body_radius + current_radius)
	if distance > effect_area: 
		#is it within the effect area?
		return
	var pos_distance_0_1 = distance / effect_area # the distance from center to center, because the pull affects the body aleady at the edge.
	var pos_y = pow(pos_distance_0_1-1,4) # a concave curved path
	pull_strength = 1.0
	if body is Rocket:
		pull_strength = 5.0
	var force = direction * pull_strength * delta
#* pos_y
	var scale_distance_0_1 = clampf(distance / current_radius,0,1) # the distance from center to edge of body, because the shrinkage should only start once the body is within the edge
	var scale_y = pow((scale_distance_0_1 - 0.1), 0.3) # a convex curved path
	var total_force = force * scale_y
	body.position += force
		
	if body is Rocket:
		if scale_y < 1 and scale_y < (body as Rocket).lowest_size:
			(body as Rocket).lowest_size = scale_y
			Globals.rocket_engine.pitch_scale = max(0.5,scale_y)
				
		if (scale_y < 1 and scale_y > (body as Rocket).lowest_size) or distance < (current_radius/10) or scale_y <= 0.2: #spaghettified
			(body as Rocket).status = Rocket.ROCKET_STATUS.spaghettified
			body.visible = false
			body.collision_layer = 0
			body.collision_mask = 0
			Globals.rocket_engine.playing = false
			Globals.rocket_engine.pitch_scale = 1.0
			return

	body.scale = Vector2(scale_y,scale_y)
	if scale_y < 0.5:
		body.modulate = Color(body.modulate,(scale_y * 9.5))
	# Set the object to zero scale if it reaches the black hole's center.
	if scale_y <= 0.2:
		body.visible = false
		body.collision_layer = 0
		body.collision_mask = 0
