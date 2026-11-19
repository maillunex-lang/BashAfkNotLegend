#!/usr/bin/env python3
"""Attach an original fantasy bow to user-provided archer GLBs.

Archer 1: static high-poly mesh — decimate + left-hand heuristic (bow hand).
Archer 2: Mixamo-rigged with Archery_Shot — parent bow to LeftHand bone.
"""
from __future__ import annotations

import math
import sys
from pathlib import Path

import bpy
from mathutils import Euler, Vector

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
import mesh_utils as MU

SRC1 = ROOT / "assets" / "models" / "incoming" / "archer_user.glb"
SRC2 = ROOT / "assets" / "models" / "incoming" / "archer2_user.glb"
OUT1 = ROOT / "assets" / "models" / "archer_with_bow.glb"
OUT2 = ROOT / "assets" / "models" / "archer2_with_bow.glb"
OUT_BLEND = ROOT / "blender" / "archer_user_with_bow.blend"
OUT_RENDERS = ROOT / "assets" / "renders" / "archer_user"


def build_bow(scale: float = 1.0) -> tuple[bpy.types.Object, bpy.types.Object]:
    """Teal/gold recurve fantasy bow — readable silhouette."""
    wood = MU.new_mat("BowWood", (0.1, 0.42, 0.48, 1), roughness=0.35, metallic=0.2)
    gold = MU.new_mat(
        "BowGold",
        (0.9, 0.7, 0.25, 1),
        roughness=0.25,
        metallic=0.9,
        emission=(0.6, 0.45, 0.12, 1),
        emission_strength=0.5,
    )
    rune = MU.new_mat(
        "BowRune",
        (0.4, 0.95, 1.0, 1),
        roughness=0.18,
        emission=(0.35, 0.9, 1.0, 1),
        emission_strength=4.0,
    )
    leather = MU.new_mat("BowGrip", (0.14, 0.09, 0.06, 1), roughness=0.75)
    string_m = MU.new_mat(
        "BowString",
        (0.85, 0.97, 1.0, 1),
        roughness=0.25,
        emission=(0.45, 0.9, 1.0, 1),
        emission_strength=1.8,
    )

    def make_limb(name: str, zsign: float) -> bpy.types.Object:
        cd = bpy.data.curves.new(name + "Curve", "CURVE")
        cd.dimensions = "3D"
        cd.bevel_depth = 0.022 * scale
        cd.bevel_resolution = 7
        cd.use_fill_caps = True
        sp = cd.splines.new("BEZIER")
        sp.bezier_points.add(3)
        # Strong recurve silhouette in XY plane (visible from front)
        coords = [
            Vector((0.0, 0.0, 0.0)),
            Vector((-0.05, 0.02, 0.32 * zsign)),
            Vector((-0.14, 0.04, 0.62 * zsign)),
            Vector((-0.22, 0.0, 0.82 * zsign)),
        ]
        for bp, co in zip(sp.bezier_points, coords):
            bp.co = co
            bp.handle_left_type = "AUTO"
            bp.handle_right_type = "AUTO"
            bp.radius = 1.35 if abs(co.z) < 0.02 else 0.55
        obj = bpy.data.objects.new(name, cd)
        bpy.context.collection.objects.link(obj)
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.convert(target="MESH")
        m = bpy.context.object
        MU.assign_mat(m, wood)
        MU.smooth_shade(m)
        return m

    upper = make_limb("BowLimbUpper", 1.0)
    lower = make_limb("BowLimbLower", -1.0)
    grip = MU.create_cylinder("BowGripMesh", 0.026 * scale, 0.13 * scale, segments=22)
    MU.assign_mat(grip, leather)

    parts = [upper, lower, grip]
    for i, z in enumerate((-0.2, 0.2)):
        r = MU.create_cylinder(f"BowRing_{i}", 0.034 * scale, 0.022 * scale, segments=18)
        r.location = (0.0, 0.0, z * scale)
        MU.assign_mat(r, gold)
        parts.append(r)
    for i, z in enumerate((-0.42, 0.0, 0.42)):
        g = MU.create_ellipsoid(f"BowGem_{i}", 0.02 * scale, Vector((0.95, 0.55, 1.25)), segments=14)
        g.location = (0.03 * scale, 0.01 * scale, z * scale)
        MU.assign_mat(g, rune)
        parts.append(g)
    for i, z in enumerate((-0.82, 0.82)):
        t = MU.create_ellipsoid(f"BowTip_{i}", 0.026 * scale, Vector((0.7, 0.7, 1.2)), segments=12)
        t.location = (-0.2 * scale, 0.0, z * scale)
        MU.assign_mat(t, gold)
        parts.append(t)

    bow = MU.join_objects(parts, "FantasyBow")
    # String spans tip-to-tip along Z, offset toward belly
    string = MU.create_cylinder("FantasyBowString", 0.004 * scale, 1.55 * scale, segments=10)
    MU.assign_mat(string, string_m)
    string.location = (0.12 * scale, 0.0, 0.0)
    return bow, string


def find_bow_hand_anchor(obj: bpy.types.Object) -> Vector:
    """Bow hand = character LEFT when facing -Y → +X in Blender."""
    mat = obj.matrix_world
    pts = [mat @ v.co for v in obj.data.vertices]
    zs = [p.z for p in pts]
    zmin, zmax = min(zs), max(zs)
    height = zmax - zmin
    z_lo = zmin + height * 0.42
    z_hi = zmin + height * 0.58
    band = [p for p in pts if p.x > 0.15 and z_lo <= p.z <= z_hi]
    if not band:
        band = [p for p in pts if p.x > 0.25]
    band.sort(key=lambda p: p.x, reverse=True)
    top = band[: max(40, len(band) // 20)]
    avg = sum(top, Vector()) / len(top)
    avg.x -= 0.05  # toward palm
    avg.y -= 0.02
    return avg


def ground_object(obj: bpy.types.Object) -> None:
    bbox = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
    min_z = min(v.z for v in bbox)
    obj.location.z -= min_z
    bpy.context.view_layer.update()


def process_static_archer() -> None:
    MU.clear_scene()
    assert SRC1.exists(), f"Missing {SRC1}"
    bpy.ops.import_scene.gltf(filepath=str(SRC1))
    archer = next(o for o in bpy.data.objects if o.type == "MESH")
    archer.name = "ArcherMesh"

    mod = archer.modifiers.new("Decimate", "DECIMATE")
    mod.ratio = 0.06
    bpy.context.view_layer.objects.active = archer
    bpy.ops.object.modifier_apply(modifier=mod.name)
    print("A1 DECIMATED polys", len(archer.data.polygons))
    MU.smooth_shade(archer)
    ground_object(archer)

    hand = find_bow_hand_anchor(archer)
    print("A1 HAND_ANCHOR", tuple(round(x, 3) for x in hand))

    bow, string = build_bow(scale=1.15)
    bow.location = hand
    bow.rotation_euler = Euler((math.radians(5), math.radians(-8), math.radians(-18)))
    string.location = bow.location + Vector((0.12, 0.0, 0.0))
    string.rotation_euler = bow.rotation_euler
    string.scale = bow.scale

    hand_sock = bpy.data.objects.new("Socket_Hand_L", None)
    bpy.context.collection.objects.link(hand_sock)
    hand_sock.empty_display_type = "SPHERE"
    hand_sock.empty_display_size = 0.04
    hand_sock.location = hand

    muzzle = bpy.data.objects.new("Socket_Muzzle", None)
    bpy.context.collection.objects.link(muzzle)
    muzzle.empty_display_type = "PLAIN_AXES"
    muzzle.empty_display_size = 0.06
    muzzle.location = hand + Vector((0.0, -0.4, 0.1))

    root = bpy.data.objects.new("ArcherRoot", None)
    bpy.context.collection.objects.link(root)
    for o in (archer, bow, string, hand_sock, muzzle):
        o.parent = root

    OUT_BLEND.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT_BLEND))

    OUT_RENDERS.mkdir(parents=True, exist_ok=True)
    MU.setup_render((1280, 720))
    MU.add_sun(3.5, (0.95, 0.25, 0.5))
    fill = bpy.data.lights.new("Fill", type="AREA")
    fill.energy = 55
    fo = bpy.data.objects.new("Fill", fill)
    bpy.context.collection.objects.link(fo)
    fo.location = (-2.2, -1.8, 2.4)
    look = Vector((0.15, 0, 1.0))
    for name, loc in {
        "front": (0.15, -3.0, 1.15),
        "three_quarter": (2.2, -2.4, 1.25),
        "bow_close": (hand.x + 0.7, hand.y - 1.05, hand.z + 0.12),
    }.items():
        target = look if name != "bow_close" else hand + Vector((0, 0, 0.05))
        MU.add_camera(loc, look_at=tuple(target))
        MU.render_to(str(OUT_RENDERS / f"user_archer_{name}.png"))
        print("A1 RENDER", name)

    OUT1.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    MU.export_glb(str(OUT1))
    print("A1 EXPORTED", OUT1, OUT1.stat().st_size)


def _find_bone(arm, *suffixes: str):
    for b in arm.data.bones:
        for s in suffixes:
            if b.name.endswith(s) or b.name == s:
                return b
    return None


def process_rigged_archer() -> None:
    MU.clear_scene()
    assert SRC2.exists(), f"Missing {SRC2}"
    bpy.ops.import_scene.gltf(filepath=str(SRC2))

    for o in list(bpy.data.objects):
        if o.type == "MESH" and "ico" in o.name.lower():
            bpy.data.objects.remove(o, do_unlink=True)

    arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    mesh = next(o for o in bpy.data.objects if o.type == "MESH")
    mesh.name = "Archer2Mesh"
    print("A2 armature", arm.name, "bones", len(arm.data.bones))
    print("A2 actions", [a.name for a in bpy.data.actions])

    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="POSE")
    bpy.ops.pose.select_all(action="SELECT")
    bpy.ops.pose.transforms_clear()
    bpy.ops.object.mode_set(mode="OBJECT")

    # Bow held in LEFT hand; right hand draws string (Mixamo Archery_Shot)
    lh = _find_bone(arm, "LeftHand")
    assert lh is not None, "LeftHand bone missing"
    arm.data.pose_position = "REST"
    bpy.context.view_layer.update()
    hand_world = arm.matrix_world @ lh.head_local
    print("A2 BOW_HAND", tuple(round(x, 3) for x in hand_world), "bone", lh.name)

    bow, string = build_bow(scale=1.05)
    for obj, loc in (
        (bow, Vector((0.0, 0.1, 0.0))),
        (string, Vector((0.0, 0.1, 0.12))),
    ):
        obj.parent = arm
        obj.parent_type = "BONE"
        obj.parent_bone = lh.name
        # Mixamo: bone +Y toward fingers; rotate bow upright in bone space
        obj.location = loc
        obj.rotation_euler = Euler((math.radians(90), math.radians(0), math.radians(-90)))
        obj.scale = Vector((1.05, 1.05, 1.05))

    muzzle = bpy.data.objects.new("Socket_Muzzle", None)
    bpy.context.collection.objects.link(muzzle)
    muzzle.empty_display_type = "PLAIN_AXES"
    muzzle.empty_display_size = 0.05
    muzzle.parent = arm
    muzzle.parent_type = "BONE"
    muzzle.parent_bone = lh.name
    # Slightly ahead of grip along bone forward
    muzzle.location = Vector((0.0, 0.28, 0.08))

    hand_sock = bpy.data.objects.new("Socket_Hand_L", None)
    bpy.context.collection.objects.link(hand_sock)
    hand_sock.empty_display_type = "SPHERE"
    hand_sock.empty_display_size = 0.04
    hand_sock.parent = arm
    hand_sock.parent_type = "BONE"
    hand_sock.parent_bone = lh.name
    hand_sock.location = Vector((0, 0, 0))

    arm.data.pose_position = "POSE"
    bpy.context.view_layer.update()

    if arm.animation_data is None:
        arm.animation_data_create()
    for act in list(bpy.data.actions):
        if "Archery" in act.name or "archery" in act.name.lower():
            arm.animation_data.action = act
            print("A2 active action", act.name)
            break

    # Sample mid-draw frame for render
    bpy.context.scene.frame_set(20)

    OUT_RENDERS.mkdir(parents=True, exist_ok=True)
    MU.setup_render((1280, 720))
    MU.add_sun(3.5, (0.95, 0.25, 0.5))
    look = Vector((0, 0, 1.0))
    MU.add_camera((2.0, -2.8, 1.35), look_at=tuple(look))
    MU.render_to(str(OUT_RENDERS / "user_archer2_three_quarter.png"))
    print("A2 RENDER three_quarter")
    MU.add_camera((hand_world.x - 0.9, hand_world.y - 1.1, hand_world.z + 0.15), look_at=tuple(hand_world))
    MU.render_to(str(OUT_RENDERS / "user_archer2_bow_close.png"))
    print("A2 RENDER bow_close")

    bpy.ops.object.select_all(action="SELECT")
    OUT2.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=str(OUT2),
        export_format="GLB",
        use_selection=True,
        export_animations=True,
        export_nla_strips=True,
        export_force_sampling=True,
        export_apply=False,
    )
    print("A2 EXPORTED", OUT2, OUT2.stat().st_size)


def main() -> None:
    process_static_archer()
    process_rigged_archer()
    print("ALL DONE")


if __name__ == "__main__":
    main()
