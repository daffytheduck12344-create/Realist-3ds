extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const CAR_SCRIPT = preload("res://scripts/car.gd")
const TARGET_SCRIPT = preload("res://scripts/target.gd")

var ui: CanvasLayer
var menu: Control
var hud: Label
var mode_label: Label
var o3ds_mode := false
var game_started := false
var player: CharacterBody3D
var car: CharacterBody3D
var targets: Array[Node3D] = []
var shots_left := 0

func _ready() -> void:
	_build_world()
	_build_menu()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _build_world() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.68, 0.76)
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = env
	add_child(environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	add_child(sun)

	var ground := _box("Ground", Vector3(0, -0.5, 0), Vector3(240, 1, 240), Color("536b58"))
	add_child(ground)
	# A compact, original low-poly street grid; buildings are generated from simple shapes.
	for z in [-42, -14, 14, 42]:
		_add_road(Vector3(0, 0.02, z), Vector3(240, 0.08, 8))
	for x in [-42, -14, 14, 42]:
		_add_road(Vector3(x, 0.03, 0), Vector3(8, 0.08, 240))
	for x in range(-5, 6):
		for z in range(-5, 6):
			if abs(x) < 2 and abs(z) < 2:
				continue
			var h := 7.0 + float(posmod(x * 13 + z * 7, 17))
			var w := 8.0 + float(posmod(x * 3 + z * 11, 5))
			var building := _box("Building", Vector3(x * 20.0, h * 0.5, z * 20.0), Vector3(w, h, w), _building_color(x, z))
			add_child(building)
			_add_windows(building, h, w)

	player = CharacterBody3D.new()
	player.name = "Player"
	player.set_script(PLAYER_SCRIPT)
	player.position = Vector3(0, 0.1, 8)
	add_child(player)
	player.car = null

	car = CharacterBody3D.new()
	car.name = "Car"
	car.set_script(CAR_SCRIPT)
	car.position = Vector3(3, 0.35, 8)
	add_child(car)
	_add_car_mesh(car)
	player.car = car

	for p in [Vector3(-8, 0.1, -8), Vector3(8, 0.1, -24), Vector3(24, 0.1, 10), Vector3(-24, 0.1, 30)]:
		var target := StaticBody3D.new()
		target.set_script(TARGET_SCRIPT)
		target.position = p
		add_child(target)
		targets.append(target)

func _building_color(x: int, z: int) -> Color:
	var colors := [Color("8c8a83"), Color("9c806b"), Color("687981"), Color("b2a38e"), Color("77736e")]
	return colors[posmod(x * 5 + z * 3, colors.size())]

func _add_road(pos: Vector3, size: Vector3) -> void:
	var road := _box("Road", pos, size, Color("303236"))
	add_child(road)

func _box(label: String, pos: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = label
	body.position = pos
	var mesh := MeshInstance3D.new()
	var shape_mesh := BoxMesh.new()
	shape_mesh.size = size
	mesh.mesh = shape_mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	mesh.material_override = material
	body.add_child(mesh)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(collider)
	return body

func _add_windows(building: StaticBody3D, height: float, width: float) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("9ac3cb")
	material.metallic = 0.15
	material.roughness = 0.25
	var floors := int(height / 3.0)
	for floor_index in range(1, floors):
		for side in [-1, 1]:
			var window_mesh := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(1.0, 1.0, 0.08)
			window_mesh.mesh = box
			window_mesh.material_override = material
			window_mesh.position = Vector3(float(side) * width * 0.26, float(floor_index) * 2.7 - height * 0.5, width * 0.5 + 0.05)
			building.add_child(window_mesh)

func _add_car_mesh(root: Node3D) -> void:
	var paint := StandardMaterial3D.new()
	paint.albedo_color = Color("b94335")
	paint.metallic = 0.45
	paint.roughness = 0.3
	var body_mesh := MeshInstance3D.new()
	var body_box := BoxMesh.new()
	body_box.size = Vector3(1.9, 0.65, 3.8)
	body_mesh.mesh = body_box
	body_mesh.position.y = 0.15
	body_mesh.material_override = paint
	root.add_child(body_mesh)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color("9ebbc2")
	glass.metallic = 0.2
	for z in [-0.45, 0.65]:
		var cabin := MeshInstance3D.new()
		var cabin_box := BoxMesh.new()
		cabin_box.size = Vector3(1.45, 0.65, 1.15)
		cabin.mesh = cabin_box
		cabin.position = Vector3(0, 0.72, z)
		cabin.material_override = glass
		root.add_child(cabin)
	var wheel_material := StandardMaterial3D.new()
	wheel_material.albedo_color = Color("17191b")
	for x in [-1.0, 1.0]:
		for z in [-1.2, 1.2]:
			var wheel := MeshInstance3D.new()
			var wheel_mesh := CylinderMesh.new()
			wheel_mesh.top_radius = 0.34
			wheel_mesh.bottom_radius = 0.34
			wheel_mesh.height = 0.22
			wheel.mesh = wheel_mesh
			wheel.rotation_degrees.z = 90
			wheel.position = Vector3(x, -0.12, z)
			wheel.material_override = wheel_material
			root.add_child(wheel)

func _build_menu() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	menu = Control.new()
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(menu)
	var panel := ColorRect.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.color = Color(0.04, 0.06, 0.08, 0.84)
	menu.add_child(panel)
	var title := Label.new()
	title.text = "REALIST"
	title.add_theme_font_size_override("font_size", 48)
	title.position = Vector2(70, 55)
	menu.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "OPEN CITY • ORIGINAL GAME PROTOTYPE"
	subtitle.position = Vector2(75, 118)
	menu.add_child(subtitle)
	var play := _button("Start exploring", Vector2(75, 190))
	play.pressed.connect(_start_game)
	menu.add_child(play)
	var mode := _button("O3DS-style mode: OFF", Vector2(75, 245))
	mode.pressed.connect(_toggle_o3ds)
	mode_label = mode
	menu.add_child(mode)
	var info := Label.new()
	info.text = "WASD move • Mouse look • Left click fire training pistol • E enter/exit car • Esc menu"
	info.position = Vector2(75, 320)
	menu.add_child(info)
	var note := Label.new()
	note.text = "O3DS-style mode is a low-resolution display preset, not a native Nintendo 3DS build."
	note.position = Vector2(75, 350)
	menu.add_child(note)
	hud = Label.new()
	hud.position = Vector2(20, 18)
	hud.add_theme_font_size_override("font_size", 20)
	ui.add_child(hud)
	hud.hide()

func _button(text: String, pos: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.position = pos
	button.custom_minimum_size = Vector2(330, 42)
	return button

func _toggle_o3ds() -> void:
	o3ds_mode = not o3ds_mode
	mode_label.text = "O3DS-style mode: " + ("ON" if o3ds_mode else "OFF")
	if o3ds_mode:
		get_window().size = Vector2i(800, 480)
		get_viewport().scaling_3d_scale = 0.65
	else:
		get_window().size = Vector2i(1280, 720)
		get_viewport().scaling_3d_scale = 1.0

func _start_game() -> void:
	game_started = true
	menu.hide()
	hud.show()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if not game_started:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		menu.show()
		game_started = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if player and player.shoot():
			shots_left += 1
			_update_hud()

func _update_hud() -> void:
	var mode_text := "O3DS-style" if o3ds_mode else "Standard"
	var car_text := "Driving" if player and player.in_car else "On foot"
	hud.text = "REALIST  |  %s  |  %s  |  Training shots: %d  |  WASD move • Mouse aim • E car • LMB fire • Esc menu" % [mode_text, car_text, shots_left]
