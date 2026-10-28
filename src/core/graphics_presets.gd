class_name GraphicsPresets
extends RefCounted
## Quality presets toggling the expensive Forward+ features.

const PRESETS := {
	&"low": {"sdfgi": false, "ssao": false, "ssil": false, "volumetric": false, "glow": true, "dof": false, "shadow": 1024, "msaa": Viewport.MSAA_DISABLED, "npc_cap": 25},
	&"medium": {"sdfgi": false, "ssao": true, "ssil": false, "volumetric": true, "glow": true, "dof": false, "shadow": 2048, "msaa": Viewport.MSAA_2X, "npc_cap": 40},
	&"high": {"sdfgi": true, "ssao": true, "ssil": true, "volumetric": true, "glow": true, "dof": false, "shadow": 4096, "msaa": Viewport.MSAA_2X, "npc_cap": 60},
	&"ultra": {"sdfgi": true, "ssao": true, "ssil": true, "volumetric": true, "glow": true, "dof": true, "shadow": 8192, "msaa": Viewport.MSAA_4X, "npc_cap": 80},
}

static var current: StringName = &"high"
## Per-feature overrides from settings/debug (e.g. {"dof": false}); merged on every apply.
static var user_overrides: Dictionary = {}


static func settings(preset: StringName) -> Dictionary:
	return PRESETS.get(preset, PRESETS[&"high"])


static func apply(preset: StringName, env: Environment, vp: Viewport, overrides: Dictionary = {}) -> void:
	current = preset if PRESETS.has(preset) else &"high"
	var p := settings(current).duplicate()
	p.merge(user_overrides, true)
	p.merge(overrides, true)
	if env != null:
		env.sdfgi_enabled = p.sdfgi
		env.ssao_enabled = p.ssao
		env.ssil_enabled = p.ssil
		env.volumetric_fog_enabled = p.volumetric
		env.glow_enabled = p.glow
	if vp != null:
		vp.msaa_3d = p.msaa
		RenderingServer.directional_shadow_atlas_set_size(p.shadow, true)


static func dof_enabled() -> bool:
	return user_overrides.get("dof", settings(current).dof)


static func npc_cap(preset: StringName = current) -> int:
	return settings(preset).npc_cap
