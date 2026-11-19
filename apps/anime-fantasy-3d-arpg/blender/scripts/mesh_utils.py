"""Shared Blender helpers for original character construction."""
from __future__ import annotations

import bmesh
import bpy
import math
from mathutils import Matrix, Vector


def clear_scene() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    # Ensure object mode clean
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)


def new_mat(name: str, color=(0.8, 0.8, 0.8, 1.0), roughness=0.45, metallic=0.0, emission=None, emission_strength=0.0) -> bpy.types.Material:
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nt = mat.node_tree
    nodes = nt.nodes
    links = nt.links
    nodes.clear()
    out = nodes.new("ShaderNodeOutputMaterial")
    out.location = (400, 0)
    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.location = (0, 0)
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Roughness"].default_value = roughness
    if "Metallic" in bsdf.inputs:
        bsdf.inputs["Metallic"].default_value = metallic
    # Stylized toon-ish: slightly higher specular / sheen if available
    if "Specular IOR Level" in bsdf.inputs:
        bsdf.inputs["Specular IOR Level"].default_value = 0.35
    if emission is not None:
        if "Emission Color" in bsdf.inputs:
            bsdf.inputs["Emission Color"].default_value = emission
            bsdf.inputs["Emission Strength"].default_value = emission_strength
        elif "Emission" in bsdf.inputs:
            bsdf.inputs["Emission"].default_value = emission
    links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    return mat


def assign_mat(obj: bpy.types.Object, mat: bpy.types.Material) -> None:
    if obj.data.materials:
        obj.data.materials[0] = mat
    else:
        obj.data.materials.append(mat)


def mesh_from_bmesh(name: str, bm: bmesh.types.BMesh, mat: bpy.types.Material | None = None) -> bpy.types.Object:
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    if mat:
        assign_mat(obj, mat)
    return obj


def add_subdiv(obj: bpy.types.Object, levels: int = 2) -> None:
    mod = obj.modifiers.new("Subsurf", "SUBSURF")
    mod.levels = levels
    mod.render_levels = levels
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=mod.name)


def smooth_shade(obj: bpy.types.Object) -> None:
    mesh = obj.data
    for poly in mesh.polygons:
        poly.use_smooth = True


def create_capsule_mesh(name: str, radius: float, depth: float, segments: int = 24) -> bpy.types.Object:
    """Organic capsule via UV sphere ends + cylinder — higher segs, not a Game Engine CapsuleMesh."""
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=segments, v_segments=segments // 2, radius=radius)
    # Stretch into capsule along Z by moving verts
    half = depth * 0.5
    for v in bm.verts:
        if v.co.z > 0:
            v.co.z += half - radius
        elif v.co.z < 0:
            v.co.z -= half - radius
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return mesh_from_bmesh(name, bm)


def create_ellipsoid(name: str, radius: float, scale: Vector, segments: int = 32) -> bpy.types.Object:
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=segments, v_segments=segments // 2, radius=radius)
    for v in bm.verts:
        v.co.x *= scale.x
        v.co.y *= scale.y
        v.co.z *= scale.z
    return mesh_from_bmesh(name, bm)


def create_box(name: str, size: Vector, segments: int = 2) -> bpy.types.Object:
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co.x *= size.x
        v.co.y *= size.y
        v.co.z *= size.z
    if segments > 1:
        bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=segments)
    return mesh_from_bmesh(name, bm)


def create_cylinder(name: str, radius: float, depth: float, segments: int = 24) -> bpy.types.Object:
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=segments, radius1=radius, radius2=radius, depth=depth)
    return mesh_from_bmesh(name, bm)


def join_objects(objects: list[bpy.types.Object], name: str) -> bpy.types.Object:
    bpy.ops.object.select_all(action="DESELECT")
    for o in objects:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    obj.name = name
    return obj


def parent_keep(child: bpy.types.Object, parent: bpy.types.Object) -> None:
    child.parent = parent
    child.matrix_parent_inverse = parent.matrix_world.inverted()


def set_origin_bottom(obj: bpy.types.Object) -> None:
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.origin_set(type="ORIGIN_GEOMETRY", center="BOUNDS")
    # Move so lowest Z is 0
    min_z = min((obj.matrix_world @ Vector(c)).z for c in obj.bound_box)
    obj.location.z -= min_z


def create_armature(name: str = "Armature") -> bpy.types.Object:
    arm_data = bpy.data.armatures.new(name)
    arm_obj = bpy.data.objects.new(name, arm_data)
    bpy.context.collection.objects.link(arm_obj)
    return arm_obj


def edit_bones(arm_obj: bpy.types.Object):
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.mode_set(mode="EDIT")
    return arm_obj.data.edit_bones


def add_bone(ebones, name: str, head: Vector, tail: Vector, parent=None):
    b = ebones.new(name)
    b.head = head
    b.tail = tail
    if parent is not None:
        b.parent = parent
        b.use_connect = False
    return b


def bind_mesh(arm_obj: bpy.types.Object, mesh_obj: bpy.types.Object) -> None:
    mesh_obj.parent = arm_obj
    mod = mesh_obj.modifiers.new("Armature", "ARMATURE")
    mod.object = arm_obj
    # Automatic weights
    bpy.ops.object.select_all(action="DESELECT")
    mesh_obj.select_set(True)
    arm_obj.select_set(True)
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.mode_set(mode="POSE")
    bpy.ops.object.mode_set(mode="OBJECT")
    bpy.ops.object.parent_set(type="ARMATURE_AUTO")


def ensure_object_mode() -> None:
    if bpy.context.object and bpy.context.object.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")


def key_bone(arm_obj: bpy.types.Object, bone_name: str, frame: int, loc=None, rot_euler=None, scale=None) -> None:
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.mode_set(mode="POSE")
    pb = arm_obj.pose.bones.get(bone_name)
    if pb is None:
        bpy.ops.object.mode_set(mode="OBJECT")
        return
    if loc is not None:
        pb.location = loc
        pb.keyframe_insert(data_path="location", frame=frame)
    if rot_euler is not None:
        pb.rotation_mode = "XYZ"
        pb.rotation_euler = rot_euler
        pb.keyframe_insert(data_path="rotation_euler", frame=frame)
    if scale is not None:
        pb.scale = scale
        pb.keyframe_insert(data_path="scale", frame=frame)
    bpy.ops.object.mode_set(mode="OBJECT")


def new_action(arm_obj: bpy.types.Object, name: str) -> bpy.types.Action:
    if arm_obj.animation_data is None:
        arm_obj.animation_data_create()
    action = bpy.data.actions.new(name=name)
    arm_obj.animation_data.action = action
    return action


def export_glb(path: str) -> None:
    bpy.ops.export_scene.gltf(
        filepath=path,
        export_format="GLB",
        export_animations=True,
        export_skins=True,
        export_morph=False,
        export_apply=True,
    )


def setup_render(res=(1280, 720), engine="BLENDER_EEVEE") -> None:
    scene = bpy.context.scene
    scene.render.engine = engine
    scene.render.resolution_x = res[0]
    scene.render.resolution_y = res[1]
    scene.render.film_transparent = False
    scene.render.image_settings.file_format = "PNG"
    # Eevee
    if hasattr(scene, "eevee"):
        scene.eevee.taa_render_samples = 32
    # World
    world = bpy.data.worlds.new("World")
    bpy.context.scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs[0].default_value = (0.45, 0.55, 0.65, 1.0)
    bg.inputs[1].default_value = 0.8


def add_sun(energy: float = 3.0, rot=(0.9, 0.2, 0.4)) -> bpy.types.Object:
    light_data = bpy.data.lights.new(name="Sun", type="SUN")
    light_data.energy = energy
    light = bpy.data.objects.new("Sun", light_data)
    bpy.context.collection.objects.link(light)
    light.rotation_euler = rot
    return light


def add_camera(loc=(3.2, -4.5, 2.2), look_at=(0, 0, 1.0)) -> bpy.types.Object:
    cam_data = bpy.data.cameras.new("Camera")
    cam = bpy.data.objects.new("Camera", cam_data)
    bpy.context.collection.objects.link(cam)
    cam.location = loc
    direction = Vector(look_at) - Vector(loc)
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.camera = cam
    return cam


def render_to(path: str) -> None:
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
