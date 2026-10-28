import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import Area
A = {"type": "always"}

# ---------------- Viridian City: 64x48 cells at region (16,112), level 2 ----------------
v = Area('viridian_city', 16, 112, 64, 48, level=2)
v.fill(0, 0, 1, 47, 'T'); v.fill(62, 0, 63, 47, 'T'); v.fill(0, 0, 63, 1, 'T'); v.fill(0, 46, 63, 47, 'T')
v.fill(30, 0, 33, 1, '=')            # north exit to Route 2
v.fill(30, 46, 41, 47, '=')          # south entrance from Route 1
v.fill(0, 24, 1, 25, '=')            # west road to Route 22
v.fill(30, 2, 33, 45, '='); v.fill(2, 14, 61, 15, '='); v.fill(2, 32, 61, 33, '='); v.fill(34, 44, 41, 45, '=')
# park (west) with pond and trees
v.fill(3, 18, 18, 29, '.'); v.fill(6, 21, 10, 25, '~'); v.fill(13, 19, 16, 21, 'f'); v.fill(4, 27, 8, 28, 'f')
for c, r in [(3, 18), (17, 18), (3, 29), (17, 29), (12, 25), (15, 27)]: v.fill(c, r, c, r, 'T')
# market square (east of the avenue)
v.fill(36, 18, 50, 28, '#'); v.fill(37, 19, 49, 27, '=')
# buildings
v.building('viridian_center', 'center', 36, 35, 42, 38, height=5.0, interior='viridian_center_int', unlock=A)
v.building('viridian_mart', 'mart', 22, 35, 27, 38, height=4.5, interior='viridian_mart_int', unlock=A, hours=[8, 21], locked="The Mart is closed.")
v.building('viridian_gym', 'gym', 44, 4, 53, 10, height=7.0, interior='viridian_gym_int', unlock={"type": "flag", "flag": "viridian_gym_open"}, locked="The Gym's doors are locked. The Leader is away.")
v.building('trainer_school', 'house_large', 20, 18, 27, 22, height=5.0, interior='trainer_school_int', unlock=A, hours=[8, 18], locked="School's out for the day.")
v.building('old_mans_house', 'house_small', 10, 39, 14, 42, interior='old_mans_house_int', unlock=A)
v.building('viridian_cafe', 'shop', 54, 35, 58, 38, interior='viridian_cafe_int', unlock={"type": "time"}, hours=[7, 22], locked="The café is closed for the night.")
v.building('police_box', 'shop', 35, 40, 38, 42, height=3.5, locked="Officer Jenny is out on patrol.")
v.building('viridian_apartments', 'apartment', 3, 3, 11, 9, height=9.0, locked="Residents only.")
v.building('flower_shop', 'shop', 54, 18, 58, 21, interior='flower_shop_int', unlock={"type": "time"}, hours=[9, 18], locked="Closed. Fresh flowers tomorrow!")
v.building('viridian_workshop', 'shop', 54, 40, 59, 43, locked="A sign reads: 'Gone for parts.'")
houses = [  # id, c0, r0, c1, r1, template, built
    ('viridian_house_1', 14, 3, 17, 6, 'house_small', True), ('viridian_house_2', 20, 3, 23, 6, 'house_small', False),
    ('viridian_house_3', 25, 3, 28, 6, 'house_small', True), ('viridian_house_4', 36, 3, 39, 6, 'house_small', False),
    ('viridian_house_5', 14, 8, 18, 12, 'house_large', True), ('viridian_house_6', 21, 8, 24, 11, 'house_small', False),
    ('viridian_house_7', 36, 8, 40, 12, 'house_large', False), ('viridian_house_8', 56, 3, 59, 6, 'house_small', True),
    ('viridian_house_9', 56, 8, 59, 11, 'house_small', False), ('viridian_house_10', 3, 36, 7, 39, 'house_small', True),
    ('viridian_house_11', 3, 41, 7, 44, 'house_small', False), ('viridian_house_12', 44, 38, 48, 41, 'house_small', True),
    ('viridian_house_13', 49, 38, 52, 41, 'house_small', False), ('viridian_house_14', 44, 22, 48, 25, 'house_small', None),
    ('viridian_house_15', 16, 39, 19, 42, 'house_small', True), ('viridian_house_16', 54, 26, 58, 29, 'house_large', False),
]
locked_lines = ["No one's home.", "Do not disturb.", "The door won't budge.", "A dog barks inside, but no one answers."]
for i, (hid, c0, r0, c1, r1, tpl, built) in enumerate(houses):
    if built is None:
        continue  # (market square occupies this spot)
    if built:
        v.building(hid, tpl, c0, r0, c1, r1, height=5.0 if tpl == 'house_large' else 4.5, interior=hid + '_int', unlock=A)
    else:
        v.building(hid, tpl, c0, r0, c1, r1, height=5.0 if tpl == 'house_large' else 4.5, locked=locked_lines[i % 4])
# market stalls, benches, lamps, bus stop
for i, (c, r) in enumerate([(38, 20), (42, 20), (46, 20), (38, 25), (42, 25), (46, 25)]):
    v.prop('market_stall_%d' % i, 'stall', c, r, footprint=[3.0, 2.0], height=2.4, color=['#c8743a', '#3a8ac8', '#8ac83a', '#c83a6a', '#c8b83a', '#6a3ac8'][i])
v.prop('bus_stop', 'bench', 34, 30, footprint=[2.4, 0.8], height=2.2, color='#4a6a9a')
v.prop('park_bench_a', 'bench', 12, 23, footprint=[2.0, 0.6], height=0.5, color='#8a6a45')
v.prop('park_bench_b', 'bench', 12, 27, footprint=[2.0, 0.6], height=0.5, color='#8a6a45')
for i, (c, r) in enumerate([(29, 4), (34, 10), (29, 16), (34, 22), (29, 28), (34, 34), (29, 40), (20, 13), (44, 13), (20, 31), (44, 31), (54, 31), (8, 31)]):
    v.prop('viridian_lamp_%d' % i, 'lamp', c, r)
v.prop('viridian_sign', 'sign', 29, 44, footprint=[0.8, 0.2], height=1.4, color='#8a6a45')
v.prop('route22_sign', 'sign', 2, 22, footprint=[0.8, 0.2], height=1.4, color='#8a6a45')
v.fill(2, 22, 2, 23, '=')
v.fill(1, 22, 1, 27, 'w')            # Route 22 is fenced off in the slice
v.prop('viridian_flock_park', 'flock', 14, 22, count=6)
v.prop('viridian_flock_market', 'flock', 47, 29, count=4)
v.prop('viridian_laundry_a', 'laundry', 8, 43)
v.prop('viridian_laundry_b', 'laundry', 58, 12)
v.prop('viridian_drifters_park', 'drifters', 10, 20, count=3)
spots = {
 'v_plaza_n': (31, 14), 'v_plaza_s': (31, 32), 'v_avenue_mid': (32, 24), 'v_center_front': (39, 39),
 'v_mart_front': (24, 39), 'v_school_yard': (23, 23), 'v_park_bench': (12, 24), 'v_park_pond': (9, 26),
 'v_market_a': (39, 22), 'v_market_b': (43, 22), 'v_market_c': (47, 22), 'v_market_d': (40, 26), 'v_market_e': (45, 26),
 'v_cafe_tables': (55, 39), 'v_bus_stop': (35, 30), 'v_gym_front': (48, 12), 'v_flower_front': (56, 22),
 'v_workshop_yard': (56, 44), 'v_old_man_porch': (12, 43), 'v_east_street': (52, 14), 'v_west_street': (10, 14),
 'v_south_gate': (35, 45), 'v_north_gate': (31, 2), 'v_apartment_steps': (7, 10), 'v_alley_east': (52, 33),
 'v_route22_fence': (3, 24), 'v_police_post': (36, 43), 'v_night_bench': (14, 27), 'v_lamp_corner': (44, 32),
}
for k, (c, r) in spots.items(): v.anchor(k, c, r)
v.anchor('viridian_center_counter', 39, 39, kind='work')
v.write()

# ---------------- Route 2 (south): 32x48 cells at region (32,64), level 2 ----------------
r2 = Area('route_2_south', 32, 64, 32, 48, level=2)
r2.fill(0, 0, 2, 47, 'T'); r2.fill(29, 0, 31, 47, 'T')
r2.fill(14, 0, 17, 47, '=')
r2.fill(4, 6, 12, 14, '"'); r2.fill(18, 26, 26, 36, '"'); r2.fill(5, 30, 11, 33, '"')
r2.zone('route2_west_grass', 'route_2', 4, 6, 12, 14)
r2.zone('route2_east_grass', 'route_2', 18, 26, 26, 36)
r2.zone('route2_small_grass', 'route_2', 5, 30, 11, 33)
r2.building('forest_gatehouse', 'gatehouse', 19, 1, 25, 5, height=5.0, interior='forest_gatehouse_int', unlock=A)
r2.fill(4, 38, 10, 43, 'd')
r2.prop('camp_tent_a', 'tent', 5, 39, footprint=[2.4, 2.4], height=1.8, color='#d08a3a')
r2.prop('camp_tent_b', 'tent', 8, 41, footprint=[2.4, 2.4], height=1.8, color='#3a8ad0')
r2.prop('campfire', 'lamp', 7, 40)
r2.prop('route2_flock', 'flock', 22, 16, count=5)
r2.prop('route2_drifters', 'drifters', 8, 20, count=3)
r2.prop('route2_sign', 'sign', 13, 44, footprint=[0.8, 0.2], height=1.4, color='#8a6a45')
for k, (c, rr) in {'r2_camp': (6, 42), 'r2_gate_front': (22, 6), 'r2_path_mid': (16, 24), 'r2_bench': (18, 44), 'r2_lookout': (24, 40)}.items():
    r2.anchor(k, c, rr)
r2.write()

# ---------------- Viridian Forest: 48x64 cells at region (16,0), level 2 ----------------
f = Area('viridian_forest', 16, 0, 48, 64, base='T', level=2)
def carve(c0, r0, c1, r1, ch='d'):
    f.fill(min(c0, c1), min(r0, r1), max(c0, c1), max(r0, r1), ch)
# winding maze path (3 cells wide) from the south gate (cols 30-33) to the closed north gate (cols 14-17)
path = [(30, 63, 33, 56), (12, 54, 33, 56), (12, 44, 14, 56), (12, 44, 40, 46), (38, 30, 40, 46), (20, 30, 40, 32),
        (20, 18, 22, 32), (6, 18, 22, 20), (6, 6, 8, 20), (6, 6, 17, 8), (14, 0, 17, 8)]
for p in path: carve(*p)
# dead-end branches with clearings
carve(24, 36, 26, 44); carve(28, 10, 44, 12); carve(42, 12, 44, 24); carve(2, 34, 10, 36); carve(28, 20, 30, 28)
clearings = [('forest_grass_south', 16, 47, 26, 53), ('forest_grass_east', 34, 34, 37, 44), ('forest_grass_mid', 23, 22, 34, 28),
             ('forest_grass_west', 9, 10, 15, 16), ('forest_grass_ne', 36, 14, 44, 22), ('forest_grass_far', 2, 30, 10, 33)]
for zid, c0, r0, c1, r1 in clearings:
    f.fill(c0, r0, c1, r1, '"'); f.zone(zid, 'viridian_forest', c0, r0, c1, r1)
f.fill(36, 57, 43, 61, '.')
f.building('ranger_outpost', 'house_small', 37, 57, 41, 59, interior='ranger_outpost_int', unlock=A)
f.fill(36, 60, 43, 60, 'd')
carve(34, 58, 36, 60)
f.fill(2, 7, 9, 13, '.')
f.building('bug_catcher_hideout', 'house_small', 3, 8, 7, 10, height=3.5, locked="A sign: 'BUG CATCHERS ONLY. Show your best bug!'",
           unlock={"type": "reward", "reward": {"kind": "pokedex_caught", "count": 10}}, interior='bug_catcher_hideout_int')
f.fill(3, 11, 7, 12, 'd'); carve(5, 11, 6, 13)
f.prop('forest_north_sign', 'sign', 13, 1, footprint=[0.8, 0.2], height=1.4, color='#8a6a45')
f.prop('forest_drifters_a', 'drifters', 20, 50, count=4)
f.prop('forest_drifters_b', 'drifters', 40, 18, count=4)
f.prop('forest_flock', 'flock', 10, 45, count=4)
for k, (c, rr) in {'f_ranger_desk': (39, 60), 'f_trail_south': (31, 58), 'f_trail_mid': (30, 31), 'f_trail_west': (7, 14),
                   'f_bug_spot_a': (21, 45), 'f_bug_spot_b': (39, 38), 'f_bug_spot_c': (21, 25), 'f_bug_spot_d': (7, 19),
                   'f_hideout_door': (5, 12), 'f_north_gate': (15, 2)}.items():
    f.anchor(k, c, rr)
f.write()
print('ok')
