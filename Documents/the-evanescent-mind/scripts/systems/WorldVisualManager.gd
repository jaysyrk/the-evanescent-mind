extends Node
## WorldVisualManager — drives post-processing shader uniforms and
## WorldEnvironment parameters in response to MentalStateManager axes.
## Attach this to your main scene or a persistent SceneManager node.
## It expects a CanvasLayer > ColorRect with res://shaders/mental_state.gdshader assigned.


@export var post_process_rect: ColorRect
@export var world_environment: WorldEnvironment

# Smoothing speed — how fast visual effects chase the mental state value
const LERP_SPEED := 2.0

# Current smoothed values (interpolated each frame toward targets)
var _chromatic:    float = 0.0
var _vignette:     float = 0.0
var _desaturate:   float = 0.0
var _oversaturate: float = 0.0
var _jitter:       float = 0.0
var _fog_density:  float = 0.0


func _ready() -> void:
	EventBus.mental_state_changed.connect(_on_mental_state_changed)


func _process(delta: float) -> void:
	var m   := MentalStateManager
	var t   := delta * LERP_SPEED

	# Compute targets from mental state axes
	var target_desaturate   := clampf(abs(minf(m.mood, 0.0)) * 1.2, 0.0, 1.0)  # depressive
	var target_oversaturate := clampf(maxf(m.mood, 0.0) * 1.5, 0.0, 1.0)       # manic
	var target_chromatic    := clampf(m.anxiety * 0.8, 0.0, 1.0)
	var target_vignette     := clampf(m.anxiety * 0.7 + abs(minf(m.mood, 0.0)) * 0.3, 0.0, 1.0)
	var target_jitter       := clampf(m.anxiety - 0.6, 0.0, 0.4)               # only extreme anxiety
	var target_fog          := clampf(abs(minf(m.mood, 0.0)) * 0.8, 0.0, 1.0)

	# Smooth toward targets
	_desaturate   = lerpf(_desaturate,   target_desaturate,   t)
	_oversaturate = lerpf(_oversaturate, target_oversaturate, t)
	_chromatic    = lerpf(_chromatic,    target_chromatic,    t)
	_vignette     = lerpf(_vignette,     target_vignette,     t)
	_jitter       = lerpf(_jitter,       target_jitter,       t)
	_fog_density  = lerpf(_fog_density,  target_fog,          t)

	_apply_shader_params()
	_apply_environment_params()


func _apply_shader_params() -> void:
	if post_process_rect == null or post_process_rect.material == null:
		return
	var mat := post_process_rect.material as ShaderMaterial
	if mat == null:
		return
	mat.set_shader_parameter("desaturate",   _desaturate)
	mat.set_shader_parameter("oversaturate", _oversaturate)
	mat.set_shader_parameter("chromatic",    _chromatic)
	mat.set_shader_parameter("vignette",     _vignette)
	mat.set_shader_parameter("jitter",       _jitter)
	mat.set_shader_parameter("time",         Time.get_ticks_msec() / 1000.0)


func _apply_environment_params() -> void:
	if world_environment == null:
		return
	var env := world_environment.environment
	if env == null:
		return
	# Fog density driven by depressive state
	env.fog_enabled = _fog_density > 0.05
	env.fog_density = _fog_density * 0.08
	# Glow driven by manic state
	env.glow_enabled = _oversaturate > 0.1
	env.glow_intensity = _oversaturate * 0.6


func _on_mental_state_changed(_axis: String, _value: float) -> void:
	pass  # _process handles smoothing — no per-signal jump needed
