from common import Area

# ---------------- Pallet Town: 32x32 cells at region cells (32, 208) ----------------
p = Area('pallet_town', 32, 208, 32, 32)
p.fill(0, 0, 1, 31, 'T'); p.fill(30, 0, 31, 31, 'T'); p.fill(0, 0, 31, 1, 'T')
p.fill(14, 0, 17, 1, '=')                      # gap north to Route 1
p.fill(0, 26, 31, 31, '~'); p.fill(2, 25, 29, 25, 's')
p.fill(15, 25, 16, 30, '=')                    # pier out over the water
p.fill(15, 2, 16, 25, '='); p.fill(3, 12, 28, 12, '='); p.fill(3, 22, 28, 22, '=')
# farm + orchard (west/north-west)
p.fill(2, 7, 6, 10, 'd'); p.fill(2, 7, 6, 7, 'w'); p.fill(2, 10, 6, 10, 'w')
for c in (3, 5): p.fill(c, 8, c, 8, 'T')
for c in (2, 4, 6): p.fill(c, 9, c, 9, 'T')
p.fill(3, 2, 7, 3, 'f'); p.fill(24, 13, 27, 13, 'f'); p.fill(10, 23, 13, 24, 'f'); p.fill(18, 23, 19, 24, 'f')
# outdoor research pen east of the lab
p.fill(25, 18, 29, 21, '.'); p.fill(25, 18, 29, 18, 'w'); p.fill(25, 21, 29, 21, 'w'); p.fill(25, 18, 25, 21, 'w'); p.fill(29, 18, 29, 21, 'w')
p.fill(27, 21, 27, 21, '.')                    # pen gate
always = {"type": "always"}
p.building('player_house', 'house_small', 7, 8, 9, 10, interior='player_house_int', unlock=always)
p.building('rival_house', 'house_small', 21, 8, 23, 10, interior='rival_house_int', unlock=always)
p.building('oaks_lab', 'lab', 18, 14, 24, 17, height=6.0, interior='oaks_lab_int', unlock=always)
p.building('oak_greenhouse', 'greenhouse', 26, 14, 28, 16, height=4.0, interior='oak_greenhouse_int', unlock={"type": "flag", "flag": "got_pokedex"}, locked="The greenhouse is locked. Professor Oak keeps the key.")
p.building('pallet_cafe', 'shop', 4, 14, 7, 16, interior='pallet_cafe_int', unlock={"type": "time"}, hours=[8, 20], locked="The café hasn't opened yet.")
p.building('pallet_house_1', 'house_small', 3, 3, 5, 5, locked="No one's home.")
p.building('pallet_barn', 'barn', 9, 3, 12, 5, height=5.5, locked="The barn door is barred from inside.")
p.building('pallet_house_2', 'house_small', 24, 3, 26, 5, interior='pallet_house_2_int', unlock=always)
p.building('pallet_house_3', 'house_large', 3, 18, 6, 20, height=5.0, locked="Do not disturb.")
p.building('pallet_house_4', 'house_small', 9, 18, 11, 20, interior='pallet_house_4_int', unlock=always)
p.building('fishing_shack', 'house_small', 21, 23, 23, 24, height=3.5, locked="The shack is padlocked.")
for i, (c, r) in enumerate([(14, 6), (17, 11), (14, 13), (17, 21), (14, 23), (8, 13), (22, 13), (8, 21), (22, 21)]):
    p.prop('pallet_lamp_%d' % i, 'lamp', c, r)
p.prop('pallet_sign', 'sign', 13, 2, footprint=[0.8, 0.2], height=1.4, color='#8a6a45')
p.prop('pier_post_a', 'post', 14, 29, footprint=[0.4, 0.4], height=1.0, color='#6b4a2b')
p.prop('pier_post_b', 'post', 17, 29, footprint=[0.4, 0.4], height=1.0, color='#6b4a2b')
p.prop('pallet_flock_square', 'flock', 19, 11, count=5)
p.prop('pallet_flock_shore', 'flock', 6, 24, count=4)
p.prop('pallet_laundry', 'laundry', 3, 21)
p.prop('pallet_drifters_flowers', 'drifters', 4, 2, count=3)
p.anchor('player_spawn', 8, 11, kind='spawn', dx=2.0, dz=1.5)
p.anchor('pallet_square', 15, 12, kind='spot')
p.anchor('pallet_pier_end', 15, 30, kind='spot')
for k, (c, rr) in {'pallet_farm': (4, 8), 'pallet_pen': (27, 20), 'pallet_shore': (8, 25), 'pallet_flowers': (5, 2),
                   'pallet_cafe_front': (6, 17), 'pallet_lab_front': (21, 18), 'pallet_north_path': (15, 3),
                   'pallet_greenhouse_front': (27, 17), 'pallet_east_lawn': (25, 11), 'pallet_west_lawn': (9, 13)}.items():
    p.anchor(k, c, rr)
p.write()

# ---------------- Route 1: 32x48 cells at region cells (32, 160); north is higher ----------------
r = Area('route_1', 32, 160, 32, 48)
r.level(0, 0, 31, 15, 2); r.level(0, 16, 31, 31, 1)
r.fill(0, 0, 2, 47, 'T'); r.fill(29, 0, 31, 47, 'T')
r.fill(14, 47, 17, 47, '=')                    # meets Pallet's north gap
# ledges (hop south only) with one stair each
r.fill(3, 16, 28, 16, '^'); r.fill(24, 16, 25, 16, 'S')
r.fill(3, 32, 28, 32, '^'); r.fill(6, 32, 7, 32, 'S')
# winding path
r.fill(14, 33, 17, 47, '='); r.fill(6, 33, 17, 34, '='); r.fill(6, 17, 7, 31, '=')
r.fill(6, 18, 25, 19, '='); r.fill(24, 0, 25, 15, '='); r.fill(14, 0, 25, 2, '=')
# tall grass belts
r.fill(4, 4, 12, 10, '"'); r.fill(12, 21, 21, 28, '"'); r.fill(19, 36, 27, 43, '"'); r.fill(10, 6, 13, 13, '"')
r.zone('route1_north_grass', 'route_1', 4, 4, 13, 13)
r.zone('route1_mid_grass', 'route_1', 12, 21, 21, 28)
r.zone('route1_south_grass', 'route_1', 19, 36, 27, 43)
# rest stop with vendor (level 1)
r.fill(24, 22, 28, 25, '#')
r.prop('route1_vendor_stall', 'stall', 25, 23, footprint=[3.5, 2.0], height=2.4, color='#c8743a')
r.prop('route1_bench', 'bench', 27, 24, footprint=[2.0, 0.6], height=0.5, color='#8a6a45')
r.prop('route1_lamp', 'lamp', 24, 22)
# berry farmer's cottage + field (level 0)
r.building('berry_farmer_cottage', 'house_small', 4, 37, 7, 39, locked="A note says: 'Out picking berries.'")
r.fill(3, 41, 10, 44, 'd'); r.fill(3, 45, 10, 45, 'w')
r.fill(18, 30, 22, 31, 'f'); r.fill(4, 25, 5, 28, 'f'); r.fill(20, 8, 22, 12, 'f')
r.prop('route1_sign', 'sign', 13, 45, footprint=[0.8, 0.2], height=1.4, color='#8a6a45')
r.prop('route1_flock_north', 'flock', 18, 5, count=5)
r.prop('route1_flock_south', 'flock', 10, 38, count=4)
r.prop('route1_drifters', 'drifters', 19, 30, count=3)
r.prop('route1_laundry', 'laundry', 8, 38)
r.anchor('route1_vendor', 25, 24, kind='work')
r.anchor('route1_bench_spot', 27, 25, kind='spot')
r.anchor('berry_field', 6, 42, kind='work')
for k, (c, rr) in {'route1_vendor_home': (27, 22), 'route1_north_end': (20, 1), 'route1_south_end': (16, 46),
                   'route1_ledge_view': (12, 15), 'route1_grass_edge': (14, 30), 'route1_cottage_yard': (8, 40)}.items():
    r.anchor(k, c, rr)
r.write()
print('ok')
