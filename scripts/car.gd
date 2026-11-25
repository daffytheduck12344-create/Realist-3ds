extends CharacterBody3D

var speed := 0.0

func drive(forward: float, steering: float, delta: float) -> void:
	if absf(forward) > 0.01:
		speed = move_toward(speed, forward * 17.0, 12.0 * delta)
	else:
		speed = move_toward(speed, 0.0, 6.0 * delta)
	if absf(speed) > 0.2:
		rotate_y(-steering * delta * signf(speed) * 1.5)
	var movement := -global_transform.basis.z * speed
	var collision := move_and_collide(movement * delta)
	if collision:
		speed *= -0.2
