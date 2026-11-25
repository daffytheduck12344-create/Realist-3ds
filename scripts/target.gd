extends StaticBody3D

var hits := 0
var original_material: StandardMaterial3D

func _ready() -> void:
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.55
	sphere.height = 1.1
	mesh.mesh = sphere
	original_material = StandardMaterial3D.new()
	original_material.albedo_color = Color("e4b74b")
	mesh.material_override = original_material
	mesh.position.y = 0.7
	add_child(mesh)
	var collider := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.55
	collider.shape = shape
	collider.position.y = 0.7
	add_child(collider)

func hit() -> void:
	hits += 1
	original_material.albedo_color = Color("59bd83") if hits >= 3 else Color("e4b74b")
