# Renders the original greatsword (left) next to the Roblox version (right) to compare them by eye.
# Writes two pictures into assets/preview/. Nothing else is changed.
#
# Run from the project folder:
#   blender --background --factory-startup --python tools/render_greatsword_compare.py

import math
import os

import bpy
from mathutils import Matrix, Vector

PROJECT = os.getcwd()
ORIGINAL = os.path.join(PROJECT, "assets", "ember-greatsword.glb")
PREPARED = os.path.join(PROJECT, "assets", "ember-greatsword-roblox.glb")
OUTPUT = os.path.join(PROJECT, "assets", "preview")

SIDE_OFFSET = 1.3  # how far each sword stands from the middle


def import_glb(path):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    return [obj for obj in bpy.data.objects if obj not in before]


def world_bounds(objects):
    low = Vector((1e18, 1e18, 1e18))
    high = Vector((-1e18, -1e18, -1e18))
    for obj in objects:
        if obj.type != "MESH":
            continue
        for vertex in obj.data.vertices:
            point = obj.matrix_world @ vertex.co
            for axis in range(3):
                low[axis] = min(low[axis], point[axis])
                high[axis] = max(high[axis], point[axis])
    return low, high


def move_roots(objects, matrix):
    for obj in objects:
        if obj.parent is None:
            obj.matrix_world = matrix @ obj.matrix_world


def add_label(text, x):
    bpy.ops.object.text_add(location=(x, 0, -1.25), rotation=(math.radians(90), 0, 0))
    label = bpy.context.object
    label.data.body = text
    label.data.align_x = "CENTER"
    label.data.size = 0.3
    material = bpy.data.materials.new("label_" + text)
    material.use_nodes = True
    nodes = material.node_tree.nodes
    nodes.clear()
    emission = nodes.new("ShaderNodeEmission")
    emission.inputs["Strength"].default_value = 2
    output = nodes.new("ShaderNodeOutputMaterial")
    material.node_tree.links.new(emission.outputs["Emission"], output.inputs["Surface"])
    label.data.materials.append(material)


def add_camera(name, location, look_at, orthographic_scale=None, lens=50):
    data = bpy.data.cameras.new(name)
    camera = bpy.data.objects.new(name, data)
    bpy.context.scene.collection.objects.link(camera)
    camera.location = location
    direction = Vector(look_at) - Vector(location)
    camera.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    if orthographic_scale:
        data.type = "ORTHO"
        data.ortho_scale = orthographic_scale
    else:
        data.lens = lens
    return camera


def render(camera, width, height, filename):
    scene = bpy.context.scene
    scene.camera = camera
    scene.render.resolution_x = width
    scene.render.resolution_y = height
    scene.render.filepath = os.path.join(OUTPUT, filename)
    bpy.ops.render.render(write_still=True)
    print("RENDERED", scene.render.filepath)


bpy.ops.wm.read_factory_settings(use_empty=True)
os.makedirs(OUTPUT, exist_ok=True)

# Original: bring it to the same size and origin as the prepared file, so both can be compared.
original = import_glb(ORIGINAL)
bpy.context.view_layer.update()
low, high = world_bounds(original)
factor = 6.0 / max(high - low)
grip = next(obj for obj in original if obj.name == "grip")
grip_low, grip_high = world_bounds([grip])
grip_center = (grip_low + grip_high) / 2
move_roots(
    original,
    Matrix.Translation((-SIDE_OFFSET, 0, 0)) @ Matrix.Scale(factor, 4) @ Matrix.Translation(-grip_center),
)

prepared = import_glb(PREPARED)
move_roots(prepared, Matrix.Translation((SIDE_OFFSET, 0, 0)))

add_label("ORIGINAL", -SIDE_OFFSET)
add_label("ROBLOX", SIDE_OFFSET)

# Light: a sun from the front left and an even grey sky, so the dark metal stays readable.
sun_data = bpy.data.lights.new("sun", "SUN")
sun_data.energy = 4
sun = bpy.data.objects.new("sun", sun_data)
bpy.context.scene.collection.objects.link(sun)
sun.rotation_euler = (math.radians(60), 0, math.radians(-30))

world = bpy.data.worlds.new("world")
world.use_nodes = True
world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.25, 0.27, 0.3, 1)
world.node_tree.nodes["Background"].inputs["Strength"].default_value = 1.0
bpy.context.scene.world = world

scene = bpy.context.scene
scene.render.engine = "CYCLES"
scene.cycles.device = "CPU"
scene.cycles.samples = 64
scene.render.image_settings.file_format = "PNG"

# Picture 1: both swords straight from the front, whole length.
front = add_camera("front", (0, -20, 2.25), (0, 0, 2.25), orthographic_scale=7.6)
render(front, 1200, 1400, "greatsword-compare-front.png")

# Picture 2: close and from the side, onto the blade above the guard, where the ridges and cracks sit.
close = add_camera("close", (0, -3.2, 2.9), (0, 0, 1.25), lens=40)
render(close, 1600, 900, "greatsword-compare-close.png")
