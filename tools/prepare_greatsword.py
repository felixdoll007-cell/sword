# Prepares assets/ember-greatsword.glb for Roblox and writes assets/ember-greatsword-roblox.glb.
# The original file is only read, never changed.
#
# Run from the project folder:
#   blender --background --factory-startup --python tools/prepare_greatsword.py
#
# What it does:
#   1. Joins the 19 parts into 5 meshes, one per material, named after the material.
#   2. Lifts the top faces of the blade ridges and ember cracks off the blade surface, in two
#      clear steps, so nothing flickers in Roblox. Their undersides stay inside the blade, so no gap shows.
#   3. Moves the origin to the middle of the grip.
#   4. Scales so that 1 unit = 1 stud and the sword is LENGTH_STUDS long.
#   5. Removes the undersides of the ember cracks, but only if they are hidden inside the blade
#      (then they can never be seen and the shape does not change).

import os
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree

PROJECT = os.getcwd()
SOURCE = os.path.join(PROJECT, "assets", "ember-greatsword.glb")
TARGET = os.path.join(PROJECT, "assets", "ember-greatsword-roblox.glb")

LENGTH_STUDS = 6.0
# Height of the top faces above the flat blade surface, in studs.
# In the original the crack tops lie only 0.0007 studs above the ridge tops and 0.009 studs above
# the blade; that would flicker. One step of 0.015 studs is about ten times what Roblox needs at
# 50 studs distance; further away these details are smaller than a pixel anyway. Higher steps would
# make the cracks stand off the blade like small fins when seen from close up.
RIDGE_ABOVE_BLADE = 0.015
CRACK_ABOVE_BLADE = 0.03

RIDGES = ["blade_ridge_front", "blade_ridge_back"]
CRACKS = ["ember_crack_front", "ember_crack_back"]
ROOT_NAME = "ember_greatsword"


def fail(message):
    print("ERROR: " + message)
    sys.exit(1)


def triangle_count(obj):
    obj.data.calc_loop_triangles()
    return len(obj.data.loop_triangles)


def bounds(objects):
    low = Vector((1e18, 1e18, 1e18))
    high = Vector((-1e18, -1e18, -1e18))
    for obj in objects:
        for vertex in obj.data.vertices:
            for axis in range(3):
                low[axis] = min(low[axis], vertex.co[axis])
                high[axis] = max(high[axis], vertex.co[axis])
    return low, high


# --- Load -----------------------------------------------------------------------------------
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SOURCE)

meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
if len(meshes) != 19:
    fail(f"expected 19 parts in the original, found {len(meshes)}")
by_name = {obj.name: obj for obj in meshes}
triangles_before = sum(triangle_count(obj) for obj in meshes)

# Some parts share the same mesh data (the file has 19 parts but 18 meshes). Give every part
# its own copy, otherwise changing one would change the other as well.
for obj in meshes:
    if obj.data.users > 1:
        obj.data = obj.data.copy()

# Bake every part's position, rotation and scale into its vertices, so all parts share one space.
for obj in meshes:
    world = obj.matrix_world.copy()
    obj.parent = None
    obj.data.transform(world)
    obj.matrix_world = Matrix.Identity(4)
for obj in list(bpy.context.scene.objects):
    if obj.type != "MESH":
        bpy.data.objects.remove(obj)

# --- 4. Scale: 1 unit = 1 stud ----------------------------------------------------------------
low, high = bounds(meshes)
size = high - low
length_axis = max(range(3), key=lambda axis: size[axis])
thickness_axis = min(range(3), key=lambda axis: size[axis])
scale = LENGTH_STUDS / size[length_axis]
for obj in meshes:
    obj.data.transform(Matrix.Scale(scale, 4))

# --- 3. Origin in the middle of the grip ------------------------------------------------------
grip_low, grip_high = bounds([by_name["grip"]])
grip_center = (grip_low + grip_high) / 2
for obj in meshes:
    obj.data.transform(Matrix.Translation(-grip_center))

# --- 2. Lift ridges and cracks off the blade surface ------------------------------------------
blade = by_name["blade"]
blade_surface = max(abs(vertex.co[thickness_axis]) for vertex in blade.data.vertices)


def lift_top_faces(names, above_blade):
    target = blade_surface + above_blade
    for name in names:
        moved = 0
        for vertex in by_name[name].data.vertices:
            height = vertex.co[thickness_axis]
            # Only the outer layer moves. The inner layer stays inside the blade: no gap.
            if abs(height) > blade_surface:
                vertex.co[thickness_axis] = target if height > 0 else -target
                moved += 1
            elif abs(height) < blade_surface - 0.05:
                fail(f"{name}: unexpected vertex far inside the blade")
        if moved == 0:
            fail(f"{name}: no top face found above the blade surface")


lift_top_faces(RIDGES, RIDGE_ABOVE_BLADE)
lift_top_faces(CRACKS, CRACK_ABOVE_BLADE)

# --- 5. Remove crack undersides that are hidden inside the blade ------------------------------
blade_tree = BVHTree.FromPolygons(
    [vertex.co.copy() for vertex in blade.data.vertices],
    [tuple(polygon.vertices) for polygon in blade.data.polygons],
)


def hidden_inside_blade(point, side):
    # Looks from far outside straight down onto the blade. The underside is hidden if the blade
    # surface there is at least as high as the point.
    direction = Vector((0, 0, 0))
    direction[thickness_axis] = -side
    start = point.copy()
    start[thickness_axis] = side * 10
    hit, _normal, _index, _distance = blade_tree.ray_cast(start, direction)
    return hit is not None and hit[thickness_axis] * side >= point[thickness_axis] * side - 1e-5


cracks_removed = 0
crack_notes = []
for name in CRACKS:
    obj = by_name[name]
    side = 1 if sum(vertex.co[thickness_axis] for vertex in obj.data.vertices) > 0 else -1
    mesh = bmesh.new()
    mesh.from_mesh(obj.data)
    undersides = [face for face in mesh.faces if face.normal[thickness_axis] * side < -0.7]
    all_hidden = all(hidden_inside_blade(vertex.co, side) for face in undersides for vertex in face.verts)
    if all_hidden:
        cracks_removed += sum(len(face.verts) - 2 for face in undersides)
        bmesh.ops.delete(mesh, geom=undersides, context="FACES")
        mesh.to_mesh(obj.data)
        crack_notes.append(f"{name}: all {len(undersides)} underside faces hidden inside the blade, removed")
    else:
        crack_notes.append(f"{name}: some underside faces are NOT hidden, kept all of them")
    mesh.free()

# --- 1. Join by material ----------------------------------------------------------------------
groups = {}
for obj in meshes:
    materials = [slot.material.name for slot in obj.material_slots if slot.material]
    if len(materials) != 1:
        fail(f"{obj.name}: expected exactly one material, found {materials}")
    groups.setdefault(materials[0], []).append(obj)

root = bpy.data.objects.new(ROOT_NAME, None)
bpy.context.scene.collection.objects.link(root)

joined = []
for material_name, objects in groups.items():
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    if len(objects) > 1:
        bpy.ops.object.join()
    result = bpy.context.view_layer.objects.active
    result.name = material_name
    result.data.name = material_name
    result.parent = root
    joined.append(result)

# --- Report -----------------------------------------------------------------------------------
low, high = bounds(joined)
size = high - low
print("RESULT scale factor:", round(scale, 4))
print("RESULT blade surface height (studs):", round(blade_surface, 4))
for note in crack_notes:
    print("RESULT", note)
print("RESULT triangles before:", triangles_before, "after:", sum(triangle_count(obj) for obj in joined))
for obj in joined:
    print(f"RESULT part {obj.name}: triangles={triangle_count(obj)} vertices={len(obj.data.vertices)}")
print("RESULT size (Blender x, y, z):", [round(value, 3) for value in size])
print("RESULT lowest point:", [round(value, 3) for value in low], "highest point:", [round(value, 3) for value in high])

# --- Save -------------------------------------------------------------------------------------
bpy.ops.object.select_all(action="DESELECT")
root.select_set(True)
for obj in joined:
    obj.select_set(True)
bpy.ops.export_scene.gltf(
    filepath=TARGET,
    export_format="GLB",
    use_selection=True,
    export_yup=True,
    export_apply=True,
    export_materials="EXPORT",
    export_animations=False,
    export_cameras=False,
    export_lights=False,
)
print("RESULT written:", TARGET)
