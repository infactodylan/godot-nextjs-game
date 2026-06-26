extends Node

const MIN_CENTER_SEPARATION := 38.0
const LANE_Y_TOLERANCE := 72.0
const SEPARATION_BACKOFF_TIME := 1.0

var _jumping_enemy: WeakRef
var _spacing_queued := false


func request_jump(enemy: Node) -> bool:
	var current: Node = _jumping_enemy.get_ref() if _jumping_enemy else null
	if current != null and is_instance_valid(current):
		return false
	_jumping_enemy = weakref(enemy)
	return true


func release_jump(enemy: Node) -> void:
	if _jumping_enemy == null:
		return
	var current: Node = _jumping_enemy.get_ref()
	if current == enemy:
		_jumping_enemy = null


func clear_jump_if(enemy: Node) -> void:
	release_jump(enemy)


func queue_spacing() -> void:
	_spacing_queued = true


func _process(_delta: float) -> void:
	if not _spacing_queued:
		return
	_spacing_queued = false
	_check_enemy_overlaps()


func _check_enemy_overlaps() -> void:
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null or not is_instance_valid(player):
		return

	var enemies: Array[CharacterBody2D] = []
	for node in get_tree().get_nodes_in_group("enemy"):
		if not node is CharacterBody2D:
			continue
		var enemy := node as CharacterBody2D
		if enemy.has_method("is_active") and not enemy.is_active():
			continue
		if not enemy.is_on_floor():
			continue
		enemies.append(enemy)

	if enemies.size() < 2:
		return

	enemies.sort_custom(
		func(a: CharacterBody2D, b: CharacterBody2D) -> bool:
			return a.global_position.x < b.global_position.x
	)

	for lane_y in _lane_centers(enemies):
		_check_lane_overlaps(enemies, lane_y, player)


func _lane_centers(enemies: Array[CharacterBody2D]) -> Array[float]:
	var centers: Array[float] = []
	for enemy in enemies:
		var y := enemy.global_position.y
		var matched := false
		for center in centers:
			if absf(y - center) <= LANE_Y_TOLERANCE:
				matched = true
				break
		if not matched:
			centers.append(y)
	return centers


func _enemy_in_lane(enemy: CharacterBody2D, lane_y: float) -> bool:
	return absf(enemy.global_position.y - lane_y) <= LANE_Y_TOLERANCE


func _check_lane_overlaps(
	enemies: Array[CharacterBody2D],
	lane_y: float,
	player: CharacterBody2D
) -> void:
	var lane_enemies: Array[CharacterBody2D] = []
	for enemy in enemies:
		if _enemy_in_lane(enemy, lane_y):
			lane_enemies.append(enemy)

	for i in range(lane_enemies.size()):
		for j in range(i + 1, lane_enemies.size()):
			var first := lane_enemies[i]
			var second := lane_enemies[j]
			if absf(second.global_position.x - first.global_position.x) >= MIN_CENTER_SEPARATION:
				continue

			var first_distance := absf(player.global_position.x - first.global_position.x)
			var second_distance := absf(player.global_position.x - second.global_position.x)
			var rear := second if second_distance >= first_distance else first
			if rear.has_method("begin_separation_backoff"):
				rear.begin_separation_backoff(SEPARATION_BACKOFF_TIME)


func is_lead_enemy(enemy: CharacterBody2D, player: CharacterBody2D) -> bool:
	if player == null or not is_instance_valid(player):
		return true

	var my_distance := absf(player.global_position.x - enemy.global_position.x)
	for node in enemy.get_tree().get_nodes_in_group("enemy"):
		if node == enemy or not node is CharacterBody2D:
			continue
		var other := node as CharacterBody2D
		if other.has_method("is_active") and not other.is_active():
			continue
		if absf(other.global_position.y - enemy.global_position.y) > LANE_Y_TOLERANCE:
			continue

		var other_distance := absf(player.global_position.x - other.global_position.x)
		if other_distance < my_distance - 2.0:
			return false

	return true
