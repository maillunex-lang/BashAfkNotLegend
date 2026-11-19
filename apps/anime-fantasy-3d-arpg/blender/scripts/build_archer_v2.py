#!/usr/bin/env python3
"""
Archer v2 — denser original geometry: metaball body, remesh, curve hair,
projected anime face UVs. Still authored entirely in-repo (no downloaded meshes).
"""
from __future__ import annotations

import math
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Euler, Matrix, Vector

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
import mesh_utils as MU

# Reuse animations from v1 by importing functions after we redefine build
import build_archer as V1

OUT_BLEND = ROOT / "blender" / "archer_original.blend"
OUT_GLB = ROOT / "assets" / "models" / "archer.glb"
OUT_RENDERS = ROOT / "assets" / "renders" / "archer"
OUT_TEX = ROOT / "assets" / "textures"


def metaball_body() -> bpy.types.Object:
    """Organic torso/limbs via metaballs → mesh → voxel remesh."""
    bpy.ops.object.metaball_add(type="BALL", location=(0, 0, 1.2))
    mb = bpy.context.object
    mb.name = "MetaBody"
    mb.data.resolution = 0.12
    mb.data.render_resolution = 0.08
    # Elements
    elements = [
        ("BALL", (0, 0, 1.2), 1.15),   # torso
        ("BALL", (0, 0, 1.45), 0.85),  # chest
        ("BALL", (0, 0.05, 0.95), 0.9),  # pelvis
        ("BALL", (-0.28, 0, 1.35), 0.55),  # shoulder L
        ("BALL", (0.28, 0, 1.35), 0.55),
        ("CAPSULE", (-0.32, 0, 1.15), 0.7),
        ("CAPSULE", (0.32, 0, 1.15), 0.7),
        ("CAPSULE", (-0.35, -0.02, 0.95), 0.6),
        ("CAPSULE", (0.35, -0.02, 0.95), 0.6),
        ("BALL", (-0.38, -0.04, 0.82), 0.4),
        ("BALL", (0.38, -0.04, 0.82), 0.4),
        ("CAPSULE", (-0.12, 0, 0.65), 0.85),
        ("CAPSULE", (0.12, 0, 0.65), 0.85),
        ("CAPSULE", (-0.12, 0.01, 0.35), 0.75),
        ("CAPSULE", (0.12, 0.01, 0.35), 0.75),
        ("BALL", (-0.12, -0.05, 0.1), 0.5),
        ("BALL", (0.12, -0.05, 0.1), 0.5),
    ]
    # First element already exists
    mb.data.elements[0].size_x = 0.22
    mb.data.elements[0].size_y = 0.16
    mb.data.elements[0].size_z = 0.28
    for typ, loc, scale in elements[1:]:
        el = mb.data.elements.new()
        el.type = typ
        el.co = loc
        el.radius = 1.0
        el.size_x = 0.15 * scale
        el.size_y = 0.12 * scale
        el.size_z = 0.18 * scale
        if typ == "CAPSULE":
            el.size_z = 0.22 * scale

    # Convert metaball to mesh
    bpy.ops.object.convert(target="MESH")
    body = bpy.context.object
    body.name = "ArcherBody"
    # Voxel remesh for cleaner topology
    mod = body.modifiers.new("Remesh", "REMESH")
    mod.mode = "VOXEL"
    mod.voxel_size = 0.025
    bpy.ops.object.modifier_apply(modifier=mod.name)
    # Smooth
    mod2 = body.modifiers.new("Smooth", "SMOOTH")
    mod2.factor = 0.5
    mod2.iterations = 8
    bpy.ops.object.modifier_apply(modifier=mod2.name)
    MU.smooth_shade(body)
    return body


def build_head_dense(skin_mat, face_mat) -> bpy.types.Object:
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=48, v_segments=32, radius=0.14)
    # Anime proportions: flatten back, enlarge forehead, taper chin
    for v in bm.verts:
        # chin taper
        if v.co.z < -0.02:
            v.co.x *= 0.85 + 0.15 * ((v.co.z + 0.14) / 0.12)
            v.co.y *= 0.9
        # forehead
        if v.co.z > 0.05:
            v.co.z *= 1.08
        # flatten sides slightly for anime
        v.co.x *= 0.92
        # push face forward a bit
        if v.co.y < 0:
            v.co.y *= 1.08
    # Eye sockets (indent)
    for sx in (-0.055, 0.055):
        for v in bm.verts:
            d = (v.co - Vector((sx, -0.1, 0.02))).length
            if d < 0.055:
                v.co += Vector((0, 0.025 * (1 - d / 0.055), -0.01))
    obj = MU.mesh_from_bmesh("Head", bm, face_mat)
    obj.location = (0, -0.02, 1.62)
    MU.add_subdiv(obj, 2)
    MU.smooth_shade(obj)
    # UV smart project + assign face image
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=66, island_margin=0.02)
    bpy.ops.object.mode_set(mode="OBJECT")
    return obj


def build_hair_curves(hair_mat) -> bpy.types.Object:
    """Many tapered curve strands → mesh."""
    curves = []
    specs = []
    # bangs
    for i, x in enumerate([-0.08, -0.04, 0, 0.04, 0.08]):
        specs.append(((x, -0.12, 1.74), (x * 0.5, -0.18, 1.52), 0.035))
    # sides
    for i, x in enumerate([-0.14, -0.16, 0.14, 0.16]):
        specs.append(((x * 0.7, -0.02, 1.72), (x, 0.02, 1.35), 0.04))
    # top / back volume
    for i in range(18):
        a = i / 18 * math.tau
        specs.append((
            (math.cos(a) * 0.04, math.sin(a) * 0.04, 1.78),
            (math.cos(a) * 0.12, 0.15 + math.sin(a) * 0.08, 1.4),
            0.045,
        ))
    for i, (h, t, r) in enumerate(specs):
        curve_data = bpy.data.curves.new(f"HairCurve_{i}", type="CURVE")
        curve_data.dimensions = "3D"
        curve_data.bevel_depth = r
        curve_data.bevel_resolution = 3
        curve_data.use_fill_caps = True
        spline = curve_data.splines.new("BEZIER")
        spline.bezier_points.add(1)
        p0, p1 = spline.bezier_points[0], spline.bezier_points[1]
        p0.co = Vector(h)
        p1.co = Vector(t)
        p0.handle_right_type = p0.handle_left_type = "AUTO"
        p1.handle_right_type = p1.handle_left_type = "AUTO"
        # taper
        curve_data.bevel_depth = r
        obj = bpy.data.objects.new(f"HairStrand_{i}", curve_data)
        bpy.context.collection.objects.link(obj)
        curves.append(obj)

    # Convert all curves to mesh and join
    meshes = []
    for c in curves:
        bpy.ops.object.select_all(action="DESELECT")
        c.select_set(True)
        bpy.context.view_layer.objects.active = c
        bpy.ops.object.convert(target="MESH")
        meshes.append(bpy.context.object)
        MU.assign_mat(bpy.context.object, hair_mat)
    hair = MU.join_objects(meshes, "Hair")
    MU.smooth_shade(hair)
    return hair


def build_armor_plates(armor_mat, gold_mat, leather_mat) -> list[bpy.types.Object]:
    parts = []
    # Beveled chest plate
    chest = MU.create_box("ChestPlate", Vector((0.38, 0.12, 0.42)), segments=3)
    bpy.context.view_layer.objects.active = chest
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.bevel(offset=0.02, segments=3)
    bpy.ops.object.mode_set(mode="OBJECT")
    chest.location = (0, -0.12, 1.25)
    MU.assign_mat(chest, armor_mat)
    MU.add_subdiv(chest, 1)
    parts.append(chest)

    # Pauldrons
    for side, x in (("L", -0.3), ("R", 0.3)):
        p = MU.create_ellipsoid(f"Pauldron_{side}", 0.1, Vector((1.1, 0.85, 0.7)), segments=28)
        p.location = (x, 0, 1.42)
        MU.assign_mat(p, gold_mat)
        MU.add_subdiv(p, 2)
        MU.smooth_shade(p)
        parts.append(p)

    # Cloak as subdivided plane draped
    bm = bmesh.new()
    bmesh.ops.create_grid(bm, x_segments=10, y_segments=14, size=0.55)
    for v in bm.verts:
        # drape
        v.co.y = 0.18 + abs(v.co.x) * 0.05
        v.co.z = v.co.y * 0  # will place
        # rename: grid is XY, map to cloak
    cloak = MU.mesh_from_bmesh("Cloak", bm, leather_mat)
    # reshape
    for v in cloak.data.vertices:
        x, y = v.co.x, v.co.y
        v.co = Vector((x * 0.7, 0.15 + abs(x) * 0.08 + y * 0.05, 1.45 - (y + 0.55) * 0.9))
    cloak.data.update()
    MU.add_subdiv(cloak, 2)
    MU.smooth_shade(cloak)
    parts.append(cloak)

    belt = MU.create_cylinder("Belt", 0.2, 0.05, segments=32)
    belt.location = (0, 0, 0.98)
    MU.assign_mat(belt, gold_mat)
    parts.append(belt)
    return parts


def build_bow_v2(wood_mat, rune_mat, string_mat):
    # Curve bow limbs
    def limb(name, zsign):
        cd = bpy.data.curves.new(name, "CURVE")
        cd.dimensions = "3D"
        cd.bevel_depth = 0.028
        cd.bevel_resolution = 4
        cd.use_fill_caps = True
        sp = cd.splines.new("BEZIER")
        sp.bezier_points.add(2)
        pts = [
            (0.0, 0, 0),
            (-0.05, 0, 0.45 * zsign),
            (-0.12, 0, 0.95 * zsign),
        ]
        for bp, co in zip(sp.bezier_points, pts):
            bp.co = Vector(co)
            bp.handle_left_type = bp.handle_right_type = "AUTO"
            bp.radius = 1.0 if co[2] == 0 else 0.55
        obj = bpy.data.objects.new(name, cd)
        bpy.context.collection.objects.link(obj)
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.convert(target="MESH")
        m = bpy.context.object
        MU.assign_mat(m, wood_mat)
        MU.smooth_shade(m)
        return m

    upper = limb("BowUpper", 1)
    lower = limb("BowLower", -1)
    grip = MU.create_cylinder("Grip", 0.035, 0.16, 24)
    MU.assign_mat(grip, rune_mat)
    gems = []
    for i, z in enumerate((-0.35, 0, 0.35)):
        g = MU.create_ellipsoid(f"Gem_{i}", 0.028, Vector((0.8, 0.5, 1.1)), 14)
        g.location = (0.04, 0, z)
        MU.assign_mat(g, rune_mat)
        gems.append(g)
    bow = MU.join_objects([upper, lower, grip] + gems, "Bow")
    bow.location = (0.45, -0.08, 1.15)
    bow.rotation_euler = (0, 0, -0.25)
    string = MU.create_cylinder("BowString", 0.006, 1.85, 12)
    string.location = (0.58, -0.08, 1.15)
    MU.assign_mat(string, string_mat)
    return bow, string


def build_quiver(leather_mat, wood_mat, feather_mat):
    parts = []
    q = MU.create_cylinder("Quiver", 0.065, 0.48, 28)
    q.location = (-0.26, 0.14, 1.28)
    q.rotation_euler = (0.45, 0, 0.55)
    MU.assign_mat(q, leather_mat)
    MU.add_subdiv(q, 1)
    parts.append(q)
    for i in range(6):
        shaft = MU.create_cylinder(f"Arr_{i}", 0.01, 0.55, 10)
        shaft.location = (-0.26 + i * 0.012, 0.12, 1.48)
        shaft.rotation_euler = (0.4, 0, 0.55)
        MU.assign_mat(shaft, wood_mat)
        parts.append(shaft)
        tip = MU.create_ellipsoid(f"Tip_{i}", 0.015, Vector((0.6, 0.6, 1.4)), 10)
        tip.location = (-0.26 + i * 0.012, 0.05, 1.72)
        MU.assign_mat(tip, feather_mat)
        parts.append(tip)
    return MU.join_objects(parts, "Quiver")


def main():
    MU.clear_scene()
    OUT_TEX.mkdir(parents=True, exist_ok=True)
    face_tex = V1.make_face_texture(OUT_TEX / "archer_face.png")
    armor_tex = V1.make_armor_texture(OUT_TEX / "archer_armor.png")

    skin = MU.new_mat("Skin", (0.93, 0.8, 0.7, 1), 0.5)
    face = V1.mat_with_image("Face", face_tex, 0.45)
    armor = V1.mat_with_image("Armor", armor_tex, 0.38, 0.2)
    leather = MU.new_mat("Leather", (0.1, 0.09, 0.1, 1), 0.7)
    gold = MU.new_mat("Gold", (0.9, 0.72, 0.28, 1), 0.22, 0.9)
    hair = MU.new_mat("Hair", (0.1, 0.38, 0.22, 1), 0.3)
    wood = MU.new_mat("Wood", (0.4, 0.25, 0.12, 1), 0.5)
    rune = MU.new_mat("Rune", (0.25, 0.95, 0.5, 1), 0.25, 0.0, (0.2, 1.0, 0.45, 1), 2.0)
    string_m = MU.new_mat("String", (0.95, 0.92, 0.85, 1), 0.35)
    feather = MU.new_mat("Feather", (0.8, 0.2, 0.15, 1), 0.45)

    body = metaball_body()
    MU.assign_mat(body, armor)
    head = build_head_dense(skin, face)
    # ears / nose
    for side, x in (("L", -0.11), ("R", 0.11)):
        ear = MU.create_ellipsoid(f"Ear_{side}", 0.035, Vector((0.45, 0.35, 1.15)), 20)
        ear.location = (x, 0.0, 1.62)
        ear.rotation_euler = (0.15, 0.4 * (1 if x > 0 else -1), 0)
        MU.assign_mat(ear, skin)
        MU.add_subdiv(ear, 1)
    nose = MU.create_ellipsoid("Nose", 0.022, Vector((0.55, 1.3, 0.85)), 18)
    nose.location = (0, -0.13, 1.57)
    MU.assign_mat(nose, skin)

    hair_obj = build_hair_curves(hair)
    plates = build_armor_plates(armor, gold, leather)
    bow, string = build_bow_v2(wood, rune, string_m)
    quiver = build_quiver(leather, wood, feather)

    # Join skinned pieces
    join_list = [body, head, hair_obj, quiver] + plates
    # also ears nose
    for o in list(bpy.data.objects):
        if o.name.startswith("Ear_") or o.name == "Nose":
            join_list.append(o)
    body_j = MU.join_objects(join_list, "ArcherBody")
    MU.smooth_shade(body_j)

    arm = V1.build_rig()
    MU.bind_mesh(arm, body_j)
    bow.parent = arm
    bow.parent_type = "BONE"
    bow.parent_bone = "Bow"
    bow.location = (0, 0, 0)
    string.parent = arm
    string.parent_type = "BONE"
    string.parent_bone = "String"
    string.location = (0, 0, 0)

    V1.animate_archer(arm)

    OUT_BLEND.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT_BLEND))
    V1.render_turnaround()
    OUT_GLB.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    MU.export_glb(str(OUT_GLB))
    print("EXPORTED v2", OUT_GLB, OUT_GLB.stat().st_size)


if __name__ == "__main__":
    main()
