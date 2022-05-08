extends CharacterBody3D

###################-VARIABLES-####################

# Camera

@export var mouse_sensitivity: float = 8.0
@export var head_path: NodePath = "Head"
@export var cam_path: NodePath = "Head/Camera"
@export var FOV: float = 80.0
var mouse_axis := Vector2()
@onready var head: Node3D = get_node(head_path)
@onready var cam: Camera3D = get_node(cam_path)
# Move
var direction := Vector3()
var move_axis := Vector2()
var snap := Vector3()
# Walk
const FLOOR_MAX_ANGLE: float = deg2rad(46.0)
@export var gravity: float = 30.0
@export var walk_speed: int = 10
@export var acceleration: int  = 8
@export var deacceleration: int  = 10
@export_range( 0.0, 1.0, 0.05) var air_control: float = 0.3
#dash
@export var dash_duration: float = 0.8
@export var dash_speed: int = 20
@export var dash_boost: float = 1.5
var _dash_direction := Vector3()
var _dash_timer: float = 0
var _speed: int
var _is_dashing_input := false

##################################################

# Called when the node enters the scene tree
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	cam.fov = FOV


# Called every frame. 'delta' is the elapsed time since the previous frame
func _process(_delta: float) -> void:
	move_axis.x = Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward")
	move_axis.y = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
		
	if Input.is_action_just_pressed("move_dash"):
		_is_dashing_input = true


# Called every physics tick. 'delta' is constant
func _physics_process(delta: float) -> void:
	walk(delta)


# Called when there is an input event
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_axis = event.relative
		camera_rotation()


func walk(delta: float) -> void:
	direction_input()
	
	if is_on_floor():
		snap = -get_floor_normal() - get_platform_velocity() * delta
		
		# Workaround for sliding down after jump on slope
		if velocity.y < 0:
			velocity.y = 0
		
	else:
		# Workaround for 'vertical bump' when going off platform
		if snap != Vector3.ZERO && velocity.y != 0:
			velocity.y = 0
		
		snap = Vector3.ZERO
		
		velocity.y -= gravity * delta
	
	_speed = walk_speed
	
	dash(delta)
	
	accelerate(delta)
	
	
	#velocity = move_and_slide(velocity, snap, Vector3.UP, true, 4, FLOOR_MAX_ANGLE)
	move_and_slide()
	_is_dashing_input = false


func camera_rotation() -> void:
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		return
	if mouse_axis.length() > 0:
		var horizontal: float = -mouse_axis.x * (mouse_sensitivity / 100)
		var vertical: float = -mouse_axis.y * (mouse_sensitivity / 100)
		
		mouse_axis = Vector2()
		
		rotate_y(deg2rad(horizontal))
		head.rotate_x(deg2rad(vertical))
		
		# Clamp mouse rotation
		var temp_rot: Vector3 = head.rotation
		temp_rot.x = clamp(temp_rot.x, deg2rad(-90), deg2rad(90))
		head.rotation = temp_rot


func direction_input() -> void:
	direction = Vector3()
	print(_dash_timer)
	if(is_dash_in_progress()):
		direction = _dash_direction
	else: 
		var aim: Basis = get_global_transform().basis
		if move_axis.x >= 0.5:
			direction -= aim.z
		if move_axis.x <= -0.5:
			direction += aim.z
		if move_axis.y <= -0.5:
			direction -= aim.x
		if move_axis.y >= 0.5:
			direction += aim.x
		direction.y = 0
		direction = direction.normalized()


func accelerate(delta: float) -> void:
	# Where would the player go
	var _temp_vel: Vector3 = velocity
	var _temp_accel: float
	var _target: Vector3 = direction * _speed
	
	_temp_vel.y = 0
	if direction.dot(_temp_vel) > 0:
		_temp_accel = acceleration
		
	else:
		_temp_accel = deacceleration
	
	if not is_on_floor():
		_temp_accel *= air_control
	
	# Interpolation
	_temp_vel = _temp_vel.lerp(_target, _temp_accel * delta)
	
	velocity.x = _temp_vel.x
	velocity.z = _temp_vel.z
	
	# Make too low values zero
	if direction.dot(velocity) == 0:
		var _vel_clamp := 0.01
		if abs(velocity.x) < _vel_clamp:
			velocity.x = 0
		if abs(velocity.z) < _vel_clamp:
			velocity.z = 0


func dash(delta: float) -> void:
	if _is_dashing_input:
		_dash_timer = dash_duration
		_dash_direction = direction
	
	if _dash_timer > 0.0:
		_dash_timer -= delta
		_speed = dash_speed

func is_dash_in_progress() -> bool:
	return _dash_timer > 0
