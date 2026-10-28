extends GutTest


func test_low_preset_disables_sdfgi_and_volumetrics() -> void:
	var env := Environment.new()
	env.sdfgi_enabled = true
	env.volumetric_fog_enabled = true
	GraphicsPresets.apply(&"low", env, null)
	assert_false(env.sdfgi_enabled)
	assert_false(env.volumetric_fog_enabled)
	assert_false(env.ssao_enabled)


func test_high_preset_enables_effects() -> void:
	var env := Environment.new()
	GraphicsPresets.apply(&"high", env, null)
	assert_true(env.sdfgi_enabled)
	assert_true(env.ssao_enabled)
	assert_true(env.ssil_enabled)
	assert_true(env.volumetric_fog_enabled)
	assert_true(env.glow_enabled)


func test_npc_cap_high_is_60() -> void:
	assert_eq(GraphicsPresets.npc_cap(&"high"), 60)
	assert_lt(GraphicsPresets.npc_cap(&"low"), 60)


func test_unknown_preset_falls_back_to_high() -> void:
	var env := Environment.new()
	GraphicsPresets.apply(&"bogus", env, null)
	assert_true(env.sdfgi_enabled)
