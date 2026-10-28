import json, os
REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BLOCK = os.path.join(REPO, 'data/regions/kanto/blockout')
PLACE = os.path.join(REPO, 'data/regions/kanto/placements')
os.makedirs(BLOCK, exist_ok=True); os.makedirs(PLACE, exist_ok=True)

class Area:
    def __init__(self, name, ox, oy, w, h, base='.', level=0):
        self.name, self.ox, self.oy, self.w, self.h = name, ox, oy, w, h
        self.g = [[base]*w for _ in range(h)]
        self.lv = [[level]*w for _ in range(h)]
        self.props, self.doors, self.zones, self.anchors = [], [], [], []
    def fill(self, c0, r0, c1, r1, ch):
        for r in range(r0, r1+1):
            for c in range(c0, c1+1):
                if 0 <= r < self.h and 0 <= c < self.w: self.g[r][c] = ch
    def level(self, c0, r0, c1, r1, lv):
        for r in range(r0, r1+1):
            for c in range(c0, c1+1): self.lv[r][c] = lv
    def m(self, col, row):  # region metres of a cell's top-left corner
        return (self.ox + col) * 4.0, (self.oy + row) * 4.0
    def building(self, bid, template, c0, r0, c1, r1, height=4.5, interior=None, unlock=None, locked="It's locked.", hours=None):
        for r in range(r0, r1+1):
            for c in range(c0, c1+1):
                if self.g[r][c] == '#': raise SystemExit('%s overlaps another building at %d,%d' % (bid, c, r))
        if r1 + 1 < self.h and self.g[r1+1][(c0+c1)//2] in 'T~w#r':
            raise SystemExit('%s door is blocked (%s)' % (bid, self.g[r1+1][(c0+c1)//2]))
        self.fill(c0, r0, c1, r1, '#')
        x0, z0 = self.m(c0, r0); x1, z1 = self.m(c1+1, r1+1)
        w, d = x1-x0-1.0, z1-z0-1.0
        cx, cz = (x0+x1)/2, (z0+z1)/2
        y = float(self.lv[r0][c0])
        self.props.append({"id": bid, "kind": "building", "template": template, "pos": [cx, y, cz], "rot": 0, "footprint": [w, d], "height": height})
        door = {"id": bid + "_door", "building": bid, "interior": interior or (bid + "_int"),
                "pos": [cx, y, cz + d/2 + 0.7], "unlock": unlock or {"type": "pending"}, "locked_text": locked}
        if hours: door["hours"] = hours
        self.doors.append(door)
        # keep the cell row in front of the door walkable pavement
        return door
    def prop(self, pid, kind, col, row, **kw):
        x, z = self.m(col, row)
        d = {"id": pid, "kind": kind, "pos": [x+2.0, float(self.lv[row][col]), z+2.0], "rot": 0}
        d.update(kw); self.props.append(d); return d
    def zone(self, zid, table, c0, r0, c1, r1):
        x0, z0 = self.m(c0, r0); x1, z1 = self.m(c1+1, r1+1)
        self.zones.append({"id": zid, "table": table, "rect": [x0, z0, x1-x0, z1-z0]})
    def anchor(self, aid, col, row, kind="spot", dx=2.0, dz=2.0):
        x, z = self.m(col, row)
        self.anchors.append({"id": aid, "pos": [x+dx, float(self.lv[row][col]), z+dz], "kind": kind})
    def write(self):
        with open(os.path.join(BLOCK, self.name + '.txt'), 'w') as f:
            f.write('@origin %d %d\n' % (self.ox, self.oy))
            f.write('\n'.join(''.join(r) for r in self.g) + '\n')
        with open(os.path.join(BLOCK, self.name + '.height.txt'), 'w') as f:
            f.write('\n'.join(''.join(str(v) for v in r) for r in self.lv) + '\n')
        json.dump({"props": self.props, "doors": self.doors, "spawn_zones": self.zones, "npc_anchors": self.anchors},
                  open(os.path.join(PLACE, self.name + '.json'), 'w'), indent=1)
