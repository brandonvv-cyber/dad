# 5 kew ave Steamroom - builds the outdoor glass steamroom in SketchUp (units: mm)
#
# Run:  Extensions > Developer > Ruby Console, then
#       load "C:/path/to/5_kew_ave_steamroom.rb"
#
# Axes: X to the right, Y from the front (door side, Y = 0) to the back (Y = 1500), Z up.
# The room sits with its front-left floor corner at the origin. After it builds, move the
# top group "5 kew ave Steamroom" onto the red floor patch in the point cloud.
#
# Not yet tested inside SketchUp. Tag names are our own: rename to the house tags if needed.

module HWXSteamroom
  PROJECT       = '5 kew ave Steamroom'
  INCLUDE_WALL  = false   # true adds the assumed existing wall (400 from the glass) for reference
  DOOR_OPEN_DEG = 0       # 90 opens the door outward

  def self.pt(x, y, z)
    Geom::Point3d.new(x.mm, y.mm, z.mm)
  end

  def self.tag(model, name)
    model.layers[name] || model.layers.add(name)
  end

  def self.mat(model, name, rgb, alpha = 1.0)
    m = model.materials[name] || model.materials.add(name)
    m.color = Sketchup::Color.new(*rgb)
    m.alpha = alpha
    m
  end

  # Box between two corners (mm) in a new named group.
  def self.box(parent, name, x1, y1, z1, x2, y2, z2, material, layer)
    g = parent.add_group
    g.name = name
    f = g.entities.add_face(pt(x1, y1, z1), pt(x2, y1, z1), pt(x2, y2, z1), pt(x1, y2, z1))
    f.reverse! if f.normal.z < 0
    f.pushpull((z2 - z1).mm)
    g.material = material
    g.layer = layer
    g
  end

  # Cylinder of radius r and length len (mm) along axis, starting at (cx, cy, cz).
  def self.cyl(parent, name, cx, cy, cz, axis, r, len, material, layer)
    g = parent.add_group
    g.name = name
    n = Geom::Vector3d.new(*axis)
    circle = g.entities.add_circle(pt(cx, cy, cz), n, r.mm, 24)
    f = g.entities.add_face(circle)
    f.reverse! if f.normal.dot(n) < 0
    f.pushpull(len.mm)
    g.material = material
    g.layer = layer
    g
  end

  # Tile joints on a flat top face, every 300 mm.
  def self.joints_top(group, x1, y1, x2, y2, z, step = 300)
    x = x1 + step
    while x < x2
      group.entities.add_line(pt(x, y1, z), pt(x, y2, z))
      x += step
    end
    y = y1 + step
    while y < y2
      group.entities.add_line(pt(x1, y, z), pt(x2, y, z))
      y += step
    end
  end

  def self.build
    model = Sketchup.active_model
    model.start_operation('Build 5 kew ave Steamroom', true)

    glass_m = mat(model, 'HWX Glass',      [143, 211, 223], 0.25)
    tile_m  = mat(model, 'HWX Tile',       [217, 209, 195])
    conc_m  = mat(model, 'HWX Concrete',   [157, 159, 155])
    steel_m = mat(model, 'HWX Stainless',  [198, 204, 209])
    gen_m   = mat(model, 'HWX Generator',  [47, 158, 79])
    pad_m   = mat(model, 'HWX Touchpad',   [240, 180, 0])
    wall_m  = mat(model, 'HWX Wall ref',   [205, 185, 154])

    t_glass = tag(model, 'Steamroom - Glass')
    t_door  = tag(model, 'Steamroom - Door')
    t_roof  = tag(model, 'Steamroom - Roof')
    t_seat  = tag(model, 'Steamroom - Seat')
    t_floor = tag(model, 'Steamroom - Floor')
    t_shwr  = tag(model, 'Steamroom - Shower')
    t_equip = tag(model, 'Steamroom - Equipment')

    top = model.entities.add_group
    top.name = PROJECT
    te = top.entities

    # Base and floor: concrete base 50 proud of the glass, tiled floor top at Z = 0
    box(te, 'Concrete base', -50, -50, -130, 1550, 1550, -10, conc_m, t_floor)
    floor = box(te, 'Floor tiles', 10, 10, -10, 1490, 1490, 0, tile_m, t_floor)
    joints_top(floor, 10, 10, 1490, 1490, 0)
    box(te, 'Floor drain', 700, 350, 0, 800, 450, 3, steel_m, t_floor)

    # Seat: full width of the back wall, 450 high x 450 deep
    seat = box(te, 'Seat', 10, 1040, 0, 1490, 1490, 450, tile_m, t_seat)
    joints_top(seat, 10, 1040, 1490, 1490, 450)
    x = 310
    while x < 1490
      seat.entities.add_line(pt(x, 1040, 0), pt(x, 1040, 450))
      x += 300
    end
    seat.entities.add_line(pt(10, 1040, 300), pt(1490, 1040, 300))

    # Frameless glass, 10 thick: back, left, right, fixed front panel, door transom, roof
    box(te, 'Glass - back',          10, 1490,    0, 1490, 1500, 2090, glass_m, t_glass)
    box(te, 'Glass - left',           0,    0,    0,   10, 1500, 2090, glass_m, t_glass)
    box(te, 'Glass - right',       1490,    0,    0, 1500, 1500, 2090, glass_m, t_glass)
    box(te, 'Glass - front fixed',    0,    0,    0,  796,   10, 2090, glass_m, t_glass)
    box(te, 'Glass - door transom', 800,    0, 2000, 1500,   10, 2090, glass_m, t_glass)
    box(te, 'Glass - roof',           0,    0, 2090, 1500, 1500, 2100, glass_m, t_roof)

    # Door: 700 x 2000, hinged on the right (X = 1500), opens outward (toward -Y)
    door = te.add_group
    door.name = 'Door'
    box(door.entities, 'Door glass', 800, 0, 0, 1500, 10, 2000, glass_m, t_door)
    cyl(door.entities, 'Handle outside', 880, -40, 800, [0, 0, 1], 12.5, 400, steel_m, t_door)
    cyl(door.entities, 'Handle inside',  880,  50, 800, [0, 0, 1], 12.5, 400, steel_m, t_door)
    [850, 1150].each do |z|
      cyl(door.entities, 'Standoff outside', 880, -40, z, [0, 1, 0], 8, 40, steel_m, t_door)
      cyl(door.entities, 'Standoff inside',  880,  10, z, [0, 1, 0], 8, 40, steel_m, t_door)
    end
    [150, 1650].each do |z|
      box(door.entities, 'Hinge', 1470, -15, z, 1500, 25, z + 100, steel_m, t_door)
    end
    door.layer = t_door
    if DOOR_OPEN_DEG != 0
      door.transform!(Geom::Transformation.rotation(pt(1500, 0, 0), Geom::Vector3d.new(0, 0, 1), DOOR_OPEN_DEG.degrees))
    end

    # Wall-mounted shower rose on the left glass: 750 from the front, 1950 up, tilted 25 degrees
    shower = te.add_group
    shower.name = 'Shower rose'
    cyl(shower.entities, 'Rose flange', 10, 750, 1950, [1, 0, 0], 40, 12, steel_m, t_shwr)
    cyl(shower.entities, 'Rose arm', 22, 750, 1950, [1, 0, 0], 10, 240, steel_m, t_shwr)
    head = cyl(shower.entities, 'Rose head', 290, 750, 1921, [0, 0, 1], 90, 18, steel_m, t_shwr)
    head.transform!(Geom::Transformation.rotation(pt(290, 750, 1930), Geom::Vector3d.new(0, 1, 0), -25.degrees))
    shower.layer = t_shwr

    # Outside equipment (move onto the real wall in the scan): generator, touchpad, steam line
    equip = te.add_group
    equip.name = 'Outside equipment'
    box(equip.entities, 'Steam generator', 1630, 75, 0, 1880, 525, 500, gen_m, t_equip)
    box(equip.entities, 'Touchpad', 1878, 240, 1340, 1900, 360, 1460, pad_m, t_equip)
    cyl(equip.entities, 'Steam line', 1400, 300, 300, [1, 0, 0], 15, 230, steel_m, t_equip)
    cyl(equip.entities, 'Steam outlet', 1385, 300, 300, [1, 0, 0], 35, 20, steel_m, t_equip)
    equip.layer = t_equip

    if INCLUDE_WALL
      box(te, 'Existing wall (assumed)', 1900, -150, 0, 2100, 1650, 2600, wall_m, t_equip)
    end

    model.commit_operation
    model.selection.clear
    model.selection.add(top)
    model.active_view.zoom_extents
    puts "#{PROJECT}: built. Move the group onto the red floor patch, then save the model as #{PROJECT}.skp"
  rescue => e
    model.abort_operation
    puts "Steamroom script failed: #{e.class}: #{e.message}"
    puts e.backtrace.first(5)
  end
end

HWXSteamroom.build
