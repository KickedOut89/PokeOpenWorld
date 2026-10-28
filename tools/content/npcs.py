import json, os, hashlib
REPO = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), 'data')
os.makedirs(REPO + '/dialogue', exist_ok=True)

# Shared context pools (barks). Each NPC gets one line per context, chosen by a stable hash.
POOLS = {
 'morning': ["Morning! Best part of the day.", "Up with the Pidgey, as always.", "Fresh air, fresh start.",
             "Coffee first, then everything else.", "The dew's still on the grass."],
 'evening': ["Sun's going down. Time to head home soon.", "Look at that sky — all orange.", "Long day. Good day, though.",
             "Lamps are coming on.", "Evenings are my favorite here."],
 'night': ["Shouldn't you be in bed?", "Quiet tonight... too quiet.", "The Hoothoot are out.", "Watch your step in the dark.",
           "Can't sleep either, huh?"],
 'rain': ["Ugh, I'm soaked!", "The berries will love this rain.", "Rain again? Figures.", "At least the dust settles.",
          "Puddles everywhere!"],
 'storm': ["Thunder! Get inside!", "Pikachu love this weather. I don't.", "Hold on to your hat!"],
 'fog': ["Can't see a thing in this fog.", "Stay on the path in fog like this."],
 'starter': ["Oh! You've got a Pokémon now!", "Is that your partner? It looks strong!", "Take good care of your partner."],
 'pokedex': ["A Pokédex! Professor Oak must trust you.", "Filling that Pokédex? Good luck!"],
}

def pick(pool, key):
    h = int(hashlib.md5(key.encode()).hexdigest(), 16)
    return POOLS[pool][h % len(POOLS[pool])]

npcs, schedules = {}, {}
SERVICES = {"nurse_joy": {"service": "heal", "center": "viridian_center"},
            "mom": {"service": "heal", "center": "pallet_home"},
            "mart_clerk": {"service": "mart"}}

def npc(nid, name, role, home, blocks, talk, bark, area_kind='town', companion=None, weather=None, night_owl=False, sprite='default', extra_talk=None, branches=None, umbrella=None):
    rec = {"id": nid, "name": name, "role": role, "home": home, "schedule": nid + "_day", "dialogue": nid, "sprite": sprite}
    if companion: rec["companion"] = companion
    if weather: rec["weather_behavior"] = weather
    if night_owl: rec["night_owl"] = True
    if umbrella: rec["umbrella_color"] = umbrella
    rec.update(SERVICES.get(nid, {}))
    npcs[nid] = rec
    schedules[nid + "_day"] = {"id": nid + "_day", "blocks": [{"from": b[0], "to": b[1], "at": b[2], "activity": b[3]} for b in blocks]}
    barks = [{"text": bark}]
    if night_owl:
        barks += [{"text": pick('night', nid), "when": {"periods": ["night"]}}, {"text": pick('fog', nid), "when": {"weather": ["fog"]}}]
    else:
        barks += [{"text": pick('morning', nid), "when": {"periods": ["morning"]}}, {"text": pick('evening', nid), "when": {"periods": ["evening"]}}]
    barks += [{"text": pick('rain', nid), "when": {"weather": ["rain"]}}, {"text": pick('storm', nid), "when": {"weather": ["thunderstorm"]}}]
    talks = [{"text": talk}, {"text": pick('starter', nid) + " " + talk, "when": {"flag": "got_starter"}},
             {"text": pick('pokedex', nid), "when": {"flag": "got_pokedex"}}]
    for t in (extra_talk or []): talks.append(t)
    d = {"id": nid, "barks": barks, "talk": talks}
    if branches: d["branches"] = branches
    json.dump(d, open(REPO + '/dialogue/%s.json' % nid, 'w'), indent=1)

U = {"rain": "umbrella"}; IN = {"rain": "indoors"}; AW = {"rain": "awning"}

# ---------------- Pallet Town (13) ----------------
npc('mom', 'Mom', 'resident', 'player_house_door', [(9, 11, 'pallet_flowers', 'garden'), (15, 16, 'pallet_cafe_front', 'shopping')],
    "Off on an adventure? Remember to come home for dinner!", "Don't forget your hat, dear!", weather=IN)
npc('daisy', 'Daisy', 'resident', 'rival_house_door', [(10, 12, 'pallet_east_lawn', 'reading'), (16, 18, 'pallet_shore', 'walk')],
    "My brother left already. He's so competitive — just like Grandpa was.", "Grandpa's lab is always so busy.", companion='meowth', weather=U, umbrella='#d07ab0')
npc('professor_oak', 'Professor Oak', 'resident', 'oaks_lab_door', [(6, 8, 'pallet_greenhouse_front', 'research')],
    "Ah, there you are! The world of Pokémon awaits. Come to my lab when you're ready.", "Hmm... fascinating behavior.",
    extra_talk=[{"text": "Have you delivered my parcel yet? The Mart in Viridian is holding it.", "when": {"flag": "got_starter", "not_flag": "got_pokedex"}}])
npc('lab_aide_ken', 'Lab Aide Ken', 'resident', 'pallet_house_2_door', [(7, 9, 'pallet_pen', 'feeding'), (13, 15, 'pallet_pen', 'observing'), (19, 20, 'pallet_square', 'walk')],
    "The Pokémon in the pen are research partners. Don't startle them!", "Twelve Rattata counted. Or was it thirteen?", companion='pidgey', weather=U)
npc('cafe_owner_mae', 'Mae', 'resident', 'pallet_cafe_door', [(7, 8, 'pallet_cafe_front', 'sweeping'), (20, 21, 'pallet_square', 'walk')],
    "My café opens at eight. Try the Oran berry scones!", "Scones are fresh!", weather=AW)
npc('farmer_joe', 'Farmer Joe', 'resident', 'pallet_barn_door', [(5, 12, 'pallet_farm', 'farming'), (14, 18, 'pallet_farm', 'farming')],
    "Wild Rattata keep nibbling my crops. A strong Pokémon would scare 'em off.", "These berries won't pick themselves.", companion='growlithe', weather=U)
npc('farmer_kid_tess', 'Tess', 'resident', 'pallet_barn_door', [(9, 12, 'pallet_west_lawn', 'playing'), (14, 17, 'pallet_farm', 'chores')],
    "When I'm older I'm going to catch a Pikachu in Viridian Forest!", "Bet I can run faster than you!", weather=IN)
npc('fisherman_hal', 'Hal', 'resident', 'fishing_shack_door', [(5, 11, 'pallet_pier_end', 'fishing'), (16, 19, 'pallet_pier_end', 'fishing')],
    "Nothing bites in this water without a rod. Someday I'll get you one.", "Shh. You'll scare the fish.", weather={"rain": "umbrella", "thunderstorm": "indoors"})
npc('granny_ruth', 'Granny Ruth', 'resident', 'pallet_house_3_door', [(8, 10, 'pallet_square', 'walk'), (14, 16, 'pallet_west_lawn', 'resting')],
    "I watched Professor Oak grow up. He was a troublemaker, you know.", "My knees know when rain is coming.", companion='sentret', weather=IN)
npc('jogger_lin', 'Lin', 'resident', 'pallet_house_1_door', [(6, 8, 'pallet_north_path', 'jogging'), (18, 19, 'pallet_shore', 'jogging')],
    "I jog up Route 1 every morning. The ledges make a great workout.", "Keep moving!", companion='pidgey', weather=IN)
npc('painter_sol', 'Sol', 'resident', 'pallet_house_4_door', [(10, 16, 'pallet_shore', 'painting')],
    "I'm painting the sea. It changes color every hour — I never finish.", "The light is perfect right now.", weather=IN)
npc('boy_milo', 'Milo', 'resident', 'pallet_house_1_door', [(10, 12, 'pallet_lab_front', 'watching'), (15, 17, 'pallet_square', 'playing')],
    "I peek into Oak's lab every day. One day he'll give ME a Pokémon.", "Have you seen the lab Pokémon?", weather=IN)
npc('gardener_bea', 'Bea', 'resident', 'oak_greenhouse_door', [(8, 12, 'pallet_greenhouse_front', 'gardening'), (14, 17, 'pallet_flowers', 'gardening')],
    "Oddish only come out at night in the forest. In here they're happy all day.", "Mind the seedlings.", weather=AW)

# ---------------- Route 1 (7) ----------------
npc('vendor_gus', 'Gus', 'resident', 'route1_vendor_home', [(8, 18, 'route1_vendor', 'vending')],
    "Potions, snacks, gossip — I sell it all. Well, mostly gossip until my stock arrives.", "Get your snacks here!", weather=AW)
npc('berry_farmer_ida', 'Ida', 'resident', 'berry_farmer_cottage_door', [(6, 11, 'berry_field', 'harvesting'), (14, 17, 'berry_field', 'harvesting')],
    "Pecha, Oran, Cheri... the soil on Route 1 grows them all.", "Ripe ones are the softest.", weather=U)
npc('berry_farmer_ned', 'Ned', 'resident', 'berry_farmer_cottage_door', [(9, 12, 'route1_cottage_yard', 'fixing'), (15, 18, 'berry_field', 'harvesting')],
    "Wild Pidgey love our berries. We don't mind sharing a few.", "Fence needs mending again.", weather=IN)
npc('traveler_rosa', 'Rosa', 'resident', 'route1_north_end', [(9, 12, 'route1_ledge_view', 'resting'), (12, 15, 'route1_south_end', 'travelling')],
    "I'm walking all of Kanto, one route at a time. This is route one... of many.", "Nice view from the ledge.", weather=U, umbrella='#e0a030')
npc('traveler_kurt', 'Kurt', 'resident', 'route1_south_end', [(10, 13, 'route1_grass_edge', 'travelling'), (13, 16, 'route1_north_end', 'travelling')],
    "Hopping down ledges is easy. Getting back up is the trick — find the stairs.", "Long way to Viridian.", weather=U)
npc('youngster_joey', 'Joey', 'resident', 'route1_south_end', [(9, 17, 'route1_grass_edge', 'training')],
    "My Rattata is in the top percentage of Rattata. Easily.", "Check out my Rattata!", companion='rattata', weather=IN)
npc('birdwatcher_ana', 'Ana', 'resident', 'route1_vendor_home', [(5, 9, 'route1_ledge_view', 'watching'), (16, 19, 'route1_grass_edge', 'watching')],
    "Pidgey in the morning, Hoothoot at night. Sentret only come out while the sun's up.", "Shh — a Pidgey flock.", weather=U)

# ---------------- Viridian City (40) ----------------
V = []
def vn(nid, name, home, blocks, talk, bark, **kw):
    V.append(nid); npc(nid, name, kw.pop('role', 'resident'), home, blocks, talk, bark, **kw)
vn('nurse_joy', 'Nurse Joy', 'viridian_center_door', [], "Welcome to the Pokémon Center! We heal Pokémon free of charge.", "Have a healthy day!")
vn('mart_clerk', 'Mart Clerk', 'viridian_mart_door', [], "Welcome! ...Oh, are you from Pallet Town? I have a parcel for Professor Oak.", "Welcome!",
   extra_talk=[{"text": "Thanks again for taking Oak's parcel to him.", "when": {"flag": "got_parcel"}}])
vn('teacher_ines', 'Ms. Ines', 'trainer_school_door', [(8, 9, 'v_school_yard', 'greeting')], "Type matchups matter even in real-time battles. Water beats Fire, every time.", "Class starts at nine!", weather=IN)
for i, (nm, comp) in enumerate([('Pip', None), ('Rina', 'pidgey'), ('Theo', None), ('Junie', 'caterpie')]):
    vn('student_%d' % i, nm, 'viridian_house_%d_door' % [1, 3, 5, 8][i], [(7, 8, 'v_bus_stop', 'waiting'), (15, 17, 'v_park_bench' if i % 2 else 'v_park_pond', 'playing')],
       ["Dodge-rolling makes you invincible for a split second. Timing is everything!", "A Pokémon asleep can't fight back — perfect time to throw a ball.",
        "Status moves don't miss, but you still have to aim them.", "Bug Pokémon are easiest to catch in the forest at dusk."][i],
       ["School's boring. Battles aren't!", "I'm late! I'm late!", "Wanna see my notes?", "Bugs are the best."][i], companion=comp, weather=IN)
stalls = [('vendor_olga', 'Olga', 'v_market_a', "Fresh Oran berries from Route 1!"), ('vendor_benny', 'Benny', 'v_market_b', "Handmade Poké Ball cases! ...They're just cases."),
          ('vendor_suki', 'Suki', 'v_market_c', "Sweet potatoes, warm from the stove!"), ('vendor_hector', 'Hector', 'v_market_d', "Maps of Kanto — slightly out of date."),
          ('vendor_lena', 'Lena', 'v_market_e', "Flowers from the forest edge, picked this morning.")]
homes_cycle = ['viridian_house_%d_door' % h for h in [2, 4, 6, 7, 9, 11, 13, 16]] + ['viridian_apartments_door']
for i, (nid, nm, spot, talk) in enumerate(stalls):
    vn(nid, nm, homes_cycle[i], [(7, 8, 'v_plaza_n', 'setting up'), (8, 17, spot, 'vending'), (17, 18, 'v_plaza_s', 'packing up')], talk,
       ["Step right up!", "Bargains today!", "Get 'em while they're hot!", "Maps! Maps!", "Flowers for someone special?"][i],
       companion=['meowth', None, 'rattata', None, 'oddish'][i], weather=AW)
vn('barista_tomo', 'Tomo', 'viridian_cafe_door', [(6, 7, 'v_cafe_tables', 'opening')], "The café's open till ten. Night owls are our best customers.", "One latte, coming up.", weather=AW)
vn('florist_pia', 'Pia', 'flower_shop_door', [(8, 9, 'v_flower_front', 'watering'), (17, 18, 'v_flower_front', 'watering')], "Oddish pollen makes the best fertilizer. Don't tell anyone.", "Smell these!", companion='oddish', weather=AW)
vn('officer_jenny', 'Officer Jenny', 'police_box_door', [(8, 20, 'v_police_post', 'patrolling')], "Route 22 is closed past the fence. Stick to Route 2 if you're heading north.", "Move along, please.", companion='growlithe', weather=U, umbrella='#2a3a8a')
vn('mechanic_dov', 'Dov', 'viridian_workshop_door', [(9, 17, 'v_workshop_yard', 'repairing')], "Bikes, carts, Poké Ball latches — if it's broken, I fix it. Eventually.", "Pass me that wrench.", weather=AW)
vn('old_man_ezra', 'Old Man Ezra', 'old_mans_house_door', [(7, 11, 'v_old_man_porch', 'sitting'), (15, 18, 'v_old_man_porch', 'sitting')],
   "Ahh, I've had my coffee now and I feel great! ...Wait, did you want something?", "Not before my coffee!", weather=IN,
   branches={"ezra_catch": {"text": "Want to know how to catch a Pokémon?", "choices": [{"text": "Yes, please!", "reply": "Weaken it first, then aim and throw. Asleep is even better. Easy!", "set_flag": "heard_catch_tip"}, {"text": "No thanks.", "reply": "Hmph. Kids these days."}]}},
   extra_talk=[{"text": "You look like a new Trainer.", "branch": "ezra_catch", "when": {"flag": "got_starter", "not_flag": "heard_catch_tip"}}])
vn('granddaughter_lu', 'Lu', 'old_mans_house_door', [(9, 12, 'v_park_pond', 'playing'), (14, 16, 'v_old_man_porch', 'helping')], "Grandpa gets grumpy until he has his coffee. Every. Single. Day.", "Grandpa! Coffee time!", companion='sentret', weather=IN)
for i, (nm, comp) in enumerate([('Paolo', None), ('Greta', 'pidgey'), ('Fumi', None)]):
    vn('commuter_%d' % i, nm, homes_cycle[5 + i], [(7, 9, 'v_bus_stop', 'waiting'), (17, 19, ['v_east_street', 'v_west_street', 'v_alley_east'][i], 'walking home')],
       ["The bus to Pewter is always late. Always.", "I work in Pewter. The commute is brutal without a Flying-type.", "Viridian's quiet. I like it that way."][i],
       ["Is the bus here yet?", "Morning, morning.", "Excuse me, coming through."][i], companion=comp, weather=U)
for i, (nm, comp) in enumerate([('Kai', 'growlithe'), ('Mira', None)]):
    vn('jogger_%d' % i, nm, homes_cycle[i + 2], [(6, 8, ['v_avenue_mid', 'v_south_gate'][i], 'jogging'), (18, 20, ['v_north_gate', 'v_west_street'][i], 'jogging')],
       ["Twice around the city before breakfast!", "Route 2 makes a great run if you dodge the Weedle."][i], ["On your left!", "Can't stop!"][i], companion=comp, weather=IN)
for i, nm in enumerate(['Elder Bo', 'Elder Wen']):
    vn('park_elder_%d' % i, nm, homes_cycle[i + 4], [(9, 12, 'v_park_bench', 'chatting'), (14, 17, 'v_park_pond', 'feeding birds')],
       ["We used to battle at the Gym, back when it was open every day.", "The Gym Leader is never around anymore. Strange fellow."][i], ["Back in my day...", "Lovely weather for the ducks."][i], weather=IN)
for i, (nm, comp) in enumerate([('Tobi', 'caterpie'), ('Nell', None), ('Rex', 'rattata')]):
    vn('kid_%d' % i, nm, homes_cycle[i + 1], [(10, 12, ['v_park_pond', 'v_plaza_s', 'v_school_yard'][i], 'playing'), (15, 18, ['v_plaza_n', 'v_park_bench', 'v_park_pond'][i], 'playing')],
       ["I caught a Caterpie in the forest! Well, my brother did.", "Tag! You're it!", "My Rattata can beat your Pokémon!"][i], ["Catch me!", "Wheee!", "Battle me!"][i], companion=comp, weather=IN)
for i, (nm, comp) in enumerate([('Hana', 'meowth'), ('Dmitri', None), ('Yuki', None), ('Sam', 'pidgey')]):
    vn('apartment_%d' % i, nm, 'viridian_apartments_door', [(8 + i, 10 + i, ['v_apartment_steps', 'v_plaza_n', 'v_mart_front', 'v_center_front'][i], 'errands'), (16, 18, ['v_cafe_tables', 'v_bus_stop', 'v_park_bench', 'v_market_c'][i], 'relaxing')],
       ["The apartment walls are thin. My neighbor's Meowth sings all night.", "Moved here from Saffron. It's so calm!", "Rent's cheap and the Mart is close. What more do you need?", "I take my Pidgey to the park every afternoon."][i],
       ["Evening, neighbor.", "Hm? Oh, hello.", "Nice day.", "Pidgey, come back!"][i], companion=comp, weather=U)
for i, (nm, spot) in enumerate([('Vera', 'v_night_bench'), ('Moss', 'v_lamp_corner'), ('Quill', 'v_plaza_s')]):
    vn('night_owl_%d' % i, nm, homes_cycle[(i + 6) % len(homes_cycle)], [(21, 3, spot, 'night walk')],
       ["I only come out after dark. The city feels like mine.", "Hoothoot hoot at the same time every night. You can set your clock by them.", "The lamps hum at night. Did you ever notice?"][i],
       ["Lovely night.", "Can't sleep.", "Shh, listen."][i], night_owl=True, weather=IN)
vn('couple_ana_li', 'Ana & Li', 'viridian_house_10_door', [(11, 13, 'v_cafe_tables', 'date'), (18, 20, 'v_park_pond', 'stroll')], "We had our first date at that café. Ten years ago!", "Isn't this nice?", companion='pidgey', weather=U, umbrella='#c04060')
vn('delivery_bo', 'Bo', 'viridian_house_12_door', [(7, 12, 'v_mart_front', 'delivering'), (13, 17, 'v_east_street', 'delivering')], "I deliver for the Mart. Parcels, potions, the occasional confused Rattata.", "Delivery!", weather=U)
vn('musician_cal', 'Cal', 'viridian_house_15_door', [(12, 20, 'v_plaza_n', 'busking')], "This song is about a Hoothoot who forgot what time it was.", "♪ La la la ♪", weather=AW)
vn('painter_ivy', 'Ivy', 'viridian_house_3_door', [(9, 16, 'v_gym_front', 'painting')], "Painting the Gym. It's the only building in town that never changes.", "Hold still, building.", weather=IN)
vn('dogwalker_finn', 'Finn', 'viridian_house_1_door', [(7, 9, 'v_west_street', 'walking'), (17, 19, 'v_route22_fence', 'walking')], "Growlithe needs two walks a day or it chews the furniture.", "Heel, Growlithe!", companion='growlithe', weather=U)
vn('gym_fan_rudy', 'Rudy', 'viridian_house_8_door', [(10, 18, 'v_gym_front', 'waiting')], "I've waited at this Gym for three weeks. The Leader WILL show up.", "Any day now...", weather=U)

# ---------------- Route 2 + Viridian Forest (12, incl. 4 Bug Catchers) ----------------
npc('gate_guard_ray', 'Ray', 'resident', 'forest_gatehouse_door', [(8, 18, 'r2_gate_front', 'guarding')], "Viridian Forest is a maze. Stay on the path and you'll reach the ranger outpost.", "Mind the forest.", weather=IN, area_kind='route')
npc('ranger_maple', 'Ranger Maple', 'resident', 'ranger_outpost_door', [(7, 12, 'f_trail_south', 'patrolling'), (13, 18, 'f_ranger_desk', 'logging')], "Pikachu show up more during thunderstorms. Nobody knows why. My theory: they like the company.", "Keep the forest clean.", weather={"rain": "umbrella", "thunderstorm": "umbrella"}, area_kind='route')
npc('ranger_cedar', 'Ranger Cedar', 'resident', 'ranger_outpost_door', [(9, 17, 'f_trail_mid', 'patrolling')], "If the fog rolls in, follow the trail markers. People get lost every year.", "Stay on the trail.", weather={"rain": "umbrella"}, area_kind='route')
npc('camper_jon', 'Jon', 'resident', 'r2_camp', [(7, 21, 'r2_camp', 'camping')], "We're camping out to see the glowing Volbeat at night. Worth the bug bites.", "Marshmallow?", companion='rattata', weather={"rain": "awning"}, area_kind='route')
npc('camper_sia', 'Sia', 'resident', 'r2_camp', [(9, 12, 'r2_lookout', 'sketching'), (17, 22, 'r2_camp', 'camping')], "At night the forest edge glows. Volbeat and Illumise dancing.", "Look up!", weather={"rain": "awning"}, area_kind='route')
npc('hiker_gord', 'Gord', 'resident', 'r2_bench', [(8, 16, 'r2_path_mid', 'hiking')], "Pewter's past the forest. Rock-hard place, rock-hard people.", "One foot, then the other.", weather=U, area_kind='route')
npc('lass_poppy', 'Poppy', 'resident', 'r2_bench', [(11, 15, 'r2_lookout', 'picnic')], "A picnic by the forest! ...Until the Weedle showed up.", "Want a sandwich?", weather=IN, area_kind='route')
npc('birdwatcher_tal', 'Tal', 'resident', 'f_north_gate', [(5, 10, 'f_trail_west', 'watching'), (18, 21, 'f_trail_mid', 'watching')], "Hoothoot at dusk, right here. Bring patience.", "Shhh...", weather=U, area_kind='route')
for i, (nm, spot) in enumerate([('Rick', 'f_bug_spot_a'), ('Doug', 'f_bug_spot_b'), ('Anthony', 'f_bug_spot_c'), ('Charlie', 'f_bug_spot_d')]):
    npc('bug_catcher_%d' % i, 'Bug Catcher %s' % nm, 'trainer', spot, [(0, 24, spot, 'searching')],
        ["Hey! You have Pokémon! Come on, let's battle 'em!", "Yo! You can't jam out if you're a Pokémon Trainer!", "Wait up! What's the hurry?", "Hey, wait up! Let's battle!"][i],
        ["Bugs are cool!", "Shh, a Caterpie!", "Look at this one!", "My net's ready!"][i], weather={"rain": "umbrella", "thunderstorm": "umbrella"}, area_kind='route')

json.dump(npcs, open(REPO + '/npcs.json', 'w'), indent=1)
json.dump(schedules, open(REPO + '/schedules.json', 'w'), indent=1)
print(len(npcs), 'npcs; viridian', len(V))
