extends CharacterBody3D

const WALK_SPEED := 5.2
const MOUSE_SENSITIVITY := 0.0025
var camera_pivot: Node3D
var camera: Camera3D
var car: CharacterBody3D
var in_car := false
var pitch := -0.18
var shoot_cooldown := 0.0

func _ready() -> void:
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.38
	capsule.height = 1.75
	var visual := MeshInstance3D.new()
	visual.mesh = capsule
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("d6b58c")
	visual.material_override = mat
	visual.position.y = 0.88
	add_child(visual)
	var collider := CollisionShape3D.new()
	var capsule_shape := CapsuleShape3D.new()
	capsule_shape.radius = 0.38
	capsule_shape.height = 1.75
	collider.shape = capsule_shape
	collider.position.y = 0.88
	add_child(collider)
	camera_pivot = Node3D.new()
	camera_pivot.position = Vector3(0, 1.35, 0)
	add_child(camera_pivot)
	camera = Camera3D.new()
	camera.position = Vector3(0, 1.0, 5.5)
	camera.current = true
	camera_pivot.add_child(camera)
	camera.look_at(Vector3(0, 0.5, 0))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		pitch = clampf(pitch - event.relative.y * MOUSE_SENSITIVITY, -0.85, 0.38)
		camera_pivot.rotation.x = pitch

func _physics_process(delta: float) -> void:
	shoot_cooldown = maxf(0.0, shoot_cooldown - delta)
	if Input.is_key_pressed(KEY_E) and not _e_was_down:
		_toggle_car()
	_e_was_down = Input.is_key_pressed(KEY_E)
	var forward := float(Input.is_key_pressed(KEY_W)) - float(Input.is_key_pressed(KEY_S))
	var sideways := float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	if in_car and is_instance_valid(car):
		car.call("drive", forward, sideways, delta)
		camera_pivot.global_position = car.global_position + Vector3(0, 1.45, 0)
		return
	var direction := (global_transform.basis * Vector3(sideways, 0, -forward)).normalized()
	if direction.length() > 0.01:
		velocity.x = direction.x * WALK_SPEED
		velocity.z = direction.z * WALK_SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, WALK_SPEED * 5.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, WALK_SPEED * 5.0 * delta)
	velocity.y -= 24.0 * delta
	move_and_slide()

var _e_was_down := false

func _toggle_car() -> void:
	if not is_instance_valid(car):
		return
	if in_car:
		in_car = false
		visible = true
		global_position = car.global_position + car.global_transform.basis.x * 1.8 + Vector3(0, 0.1, 0)
		camera_pivot.position = Vector3(0, 1.35, 0)
	else:
		if global_position.distance_to(car.global_position) < 4.0:
			in_car = true
			visible = false

func shoot() -> bool:
	if shoot_cooldown > 0.0 or not is_inside_tree():
		return false
	shoot_cooldown = 0.22
	var from := camera.global_position
	var to := from + -camera.global_transform.basis.z * 80.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.collider.has_method("hit"):
		hit.collider.hit()
	return true
