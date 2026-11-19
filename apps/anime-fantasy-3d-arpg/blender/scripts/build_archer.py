#!/usr/bin/env python3
"""
ORIGINAL Anime-Fantasy archer — geometry authored in Blender Python.
No third-party character meshes.
"""
from __future__ import annotations

import math
import os
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Euler, Vector

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
import mesh_utils as MU  # noqa: E402

OUT_BLEND = ROOT / "blender" / "archer_original.blend"
OUT_GLB = ROOT / "assets" / "models" / "archer.glb"
OUT_RENDERS = ROOT / "assets" / "renders" / "archer"
OUT_TEX = ROOT / "assets" / "textures"


def make_face_texture(path: Path, size: int = 512) -> Path:
    """Stylized anime face atlas generated procedurally (own art)."""
    from PIL import Image, ImageDraw

    path.parent.mkdir(parents=True, exist_ok=True)
    im = Image.new("RGBA", (size, size), (240, 210, 190, 255))
    d = ImageDraw.Draw(im)
    # Soft blush
    for r in range(40, 0, -1):
        a = int(18 * (1 - r / 40))
        d.ellipse([120 - r, 300 - r // 2, 120 + r, 300 + r // 2], fill=(255, 140, 150, a))
        d.ellipse([390 - r, 300 - r // 2, 390 + r, 300 + r // 2], fill=(255, 140, 150, a))
    # Eyes (large anime)
    def eye(cx, cy, flip=False):
        d.ellipse([cx - 55, cy - 35, cx + 55, cy + 40], fill=(250, 250, 255, 255))
        iris_col = (40, 160, 90, 255)
        d.ellipse([cx - 28, cy - 18, cx + 28, cy + 32], fill=iris_col)
        d.ellipse([cx - 12, cy - 5, cx + 12, cy + 22], fill=(15, 25, 20, 255))
        d.ellipse([cx - 18, cy - 22, cx - 4, cy - 8], fill=(255, 255, 255, 230))
        # Lash line
        d.arc([cx - 58, cy - 38, cx + 58, cy + 10], 200, 340, fill=(30, 20, 20, 255), width=4)

    eye(170, 230)
    eye(340, 230)
    # Brows
    d.arc([110, 160, 230, 210], 200, 340, fill=(30, 25, 20, 255), width=6)
    d.arc([280, 160, 400, 210], 200, 340, fill=(30, 25, 20, 255), width=6)
    # Nose hint
    d.line([(255, 280), (248, 310), (262, 310)], fill=(200, 150, 140, 255), width=2)
    # Mouth
    d.arc([220, 330, 290, 370], 20, 160, fill=(180, 80, 90, 255), width=3)
    im.save(path)
    return path


def make_armor_texture(path: Path, size: int = 512) -> Path:
    from PIL import Image, ImageDraw

    path.parent.mkdir(parents=True, exist_ok=True)
    im = Image.new("RGBA", (size, size), (25, 55, 35, 255))
    d = ImageDraw.Draw(im)
    # Leather panels
    for y in range(0, size, 64):
        for x in range(0, size, 64):
            d.rectangle([x + 4, y + 4, x + 60, y + 60], outline=(10, 20, 12, 255), width=2)
    # Gold trim
    for i in range(0, size, 32):
        d.line([(0, i), (size, i)], fill=(210, 170, 60, 180), width=2)
        d.line([(i, 0), (i, size)], fill=(210, 170, 60, 100), width=1)
    # Black straps
    d.rectangle([0, 200, size, 230], fill=(15, 15, 18, 255))
    d.rectangle([0, 360, size, 385], fill=(15, 15, 18, 255))
    im.save(path)
    return path


def mat_with_image(name: str, img_path: Path, roughness=0.5, metallic=0.0) -> bpy.types.Material:
    mat = MU.new_mat(name, (1, 1, 1, 1), roughness=roughness, metallic=metallic)
    nt = mat.node_tree
    nodes, links = nt.nodes, nt.links
    bsdf = nodes.get("Principled BSDF")
    tex = nodes.new("ShaderNodeTexImage")
    tex.location = (-300, 0)
    img = bpy.data.images.load(str(img_path))
    tex.image = img
    links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    return mat


def build_head(skin_mat, face_mat) -> bpy.types.Object:
    # Anime head: larger cranium, softer jaw via ellipsoid + sculpt displace
    head = MU.create_ellipsoid("Head", 0.13, Vector((0.92, 1.0, 1.12)), segments=40)
    head.location = (0, 0, 1.62)
    MU.assign_mat(head, face_mat)
    MU.add_subdiv(head, 1)
    MU.smooth_shade(head)

    # Nose bridge bump as small ellipsoid
    nose = MU.create_ellipsoid("Nose", 0.025, Vector((0.6, 1.2, 0.9)), segments=16)
    nose.location = (0, -0.12, 1.58)
    MU.assign_mat(nose, skin_mat)
    MU.smooth_shade(nose)

    # Ears
    for side, x in (("L", -0.12), ("R", 0.12)):
        ear = MU.create_ellipsoid(f"Ear_{side}", 0.04, Vector((0.45, 0.35, 1.1)), segments=16)
        ear.location = (x, 0.02, 1.62)
        ear.rotation_euler = (0.2, 0.35 * (1 if x > 0 else -1), 0)
        MU.assign_mat(ear, skin_mat)
        MU.smooth_shade(ear)

    return head


def build_hair(hair_mat) -> list[bpy.types.Object]:
    hairs = []
    # Layered anime hair clumps as tapered ellipsoids / cards
    clumps = [
        # bangs
        ((0.0, -0.12, 1.72), (0.7, 0.35, 0.55), 0.09, (0.4, 0, 0)),
        ((-0.06, -0.11, 1.70), (0.55, 0.3, 0.5), 0.07, (0.3, 0.2, 0.2)),
        ((0.06, -0.11, 1.70), (0.55, 0.3, 0.5), 0.07, (0.3, -0.2, -0.2)),
        # top volume
        ((0.0, 0.02, 1.78), (1.1, 1.0, 0.7), 0.12, (0.1, 0, 0)),
        ((-0.08, 0.05, 1.74), (0.8, 0.9, 0.8), 0.09, (0.2, 0.3, 0.1)),
        ((0.08, 0.05, 1.74), (0.8, 0.9, 0.8), 0.09, (0.2, -0.3, -0.1)),
        # side locks
        ((-0.13, -0.02, 1.55), (0.45, 0.4, 1.4), 0.055, (0.15, 0.4, 0)),
        ((0.13, -0.02, 1.55), (0.45, 0.4, 1.4), 0.055, (0.15, -0.4, 0)),
        # back hair
        ((0.0, 0.12, 1.55), (1.0, 0.7, 1.5), 0.1, (-0.25, 0, 0)),
        ((-0.07, 0.14, 1.48), (0.6, 0.5, 1.3), 0.07, (-0.3, 0.2, 0)),
        ((0.07, 0.14, 1.48), (0.6, 0.5, 1.3), 0.07, (-0.3, -0.2, 0)),
    ]
    for i, (loc, scale, rad, rot) in enumerate(clumps):
        h = MU.create_ellipsoid(f"Hair_{i}", rad, Vector(scale), segments=20)
        h.location = loc
        h.rotation_euler = rot
        MU.assign_mat(h, hair_mat)
        MU.add_subdiv(h, 1)
        MU.smooth_shade(h)
        hairs.append(h)
    return hairs


def build_body(skin_mat, armor_mat, leather_mat, gold_mat) -> list[bpy.types.Object]:
    parts = []
    # Torso (organic)
    torso = MU.create_ellipsoid("Torso", 0.18, Vector((1.05, 0.7, 1.35)), segments=36)
    torso.location = (0, 0, 1.15)
    MU.assign_mat(torso, armor_mat)
    MU.add_subdiv(torso, 2)
    MU.smooth_shade(torso)
    parts.append(torso)

    # Chest plate overlay
    plate = MU.create_ellipsoid("ChestPlate", 0.17, Vector((1.1, 0.55, 0.9)), segments=28)
    plate.location = (0, -0.04, 1.22)
    MU.assign_mat(plate, armor_mat)
    MU.add_subdiv(plate, 1)
    MU.smooth_shade(plate)
    parts.append(plate)

    # Gold trim belt
    belt = MU.create_cylinder("Belt", 0.2, 0.06, segments=28)
    belt.location = (0, 0, 0.95)
    MU.assign_mat(belt, gold_mat)
    MU.smooth_shade(belt)
    parts.append(belt)

    # Cloak
    cloak = MU.create_ellipsoid("Cloak", 0.22, Vector((1.2, 0.35, 1.6)), segments=28)
    cloak.location = (0, 0.12, 1.05)
    cloak.rotation_euler = (-0.15, 0, 0)
    MU.assign_mat(cloak, leather_mat)
    MU.add_subdiv(cloak, 2)
    MU.smooth_shade(cloak)
    parts.append(cloak)

    # Arms
    for side, x in (("L", -0.28), ("R", 0.28)):
        upper = MU.create_capsule_mesh(f"UpperArm_{side}", 0.055, 0.28, segments=20)
        upper.location = (x, 0, 1.28)
        upper.rotation_euler = (0, 0, 0.15 * (1 if x > 0 else -1))
        MU.assign_mat(upper, armor_mat)
        MU.add_subdiv(upper, 1)
        MU.smooth_shade(upper)
        parts.append(upper)

        lower = MU.create_capsule_mesh(f"LowerArm_{side}", 0.045, 0.26, segments=20)
        lower.location = (x * 1.15, -0.02, 1.02)
        MU.assign_mat(lower, leather_mat)
        MU.add_subdiv(lower, 1)
        MU.smooth_shade(lower)
        parts.append(lower)

        hand = MU.create_ellipsoid(f"Hand_{side}", 0.045, Vector((0.7, 1.1, 0.5)), segments=16)
        hand.location = (x * 1.25, -0.04, 0.86)
        MU.assign_mat(hand, skin_mat)
        MU.smooth_shade(hand)
        parts.append(hand)

        # Shoulder pauldron
        pad = MU.create_ellipsoid(f"Pauldron_{side}", 0.08, Vector((1.0, 0.8, 0.7)), segments=20)
        pad.location = (x * 1.05, 0, 1.42)
        MU.assign_mat(pad, gold_mat)
        MU.add_subdiv(pad, 1)
        MU.smooth_shade(pad)
        parts.append(pad)

    # Legs
    for side, x in (("L", -0.1), ("R", 0.1)):
        thigh = MU.create_capsule_mesh(f"Thigh_{side}", 0.07, 0.36, segments=20)
        thigh.location = (x, 0, 0.72)
        MU.assign_mat(thigh, leather_mat)
        MU.add_subdiv(thigh, 1)
        MU.smooth_shade(thigh)
        parts.append(thigh)

        shin = MU.create_capsule_mesh(f"Shin_{side}", 0.055, 0.34, segments=20)
        shin.location = (x, 0.01, 0.38)
        MU.assign_mat(shin, armor_mat)
        MU.add_subdiv(shin, 1)
        MU.smooth_shade(shin)
        parts.append(shin)

        boot = MU.create_ellipsoid(f"Boot_{side}", 0.07, Vector((0.85, 1.4, 0.55)), segments=18)
        boot.location = (x, -0.04, 0.1)
        MU.assign_mat(boot, leather_mat)
        MU.smooth_shade(boot)
        parts.append(boot)

    # Decorative straps
    for i, z in enumerate((1.35, 1.08, 0.88)):
        strap = MU.create_cylinder(f"Strap_{i}", 0.185, 0.025, segments=24)
        strap.location = (0, 0, z)
        MU.assign_mat(strap, leather_mat)
        parts.append(strap)

    return parts


def build_bow(wood_mat, rune_mat, string_mat) -> tuple[bpy.types.Object, bpy.types.Object]:
    """Detailed fantasy longbow as joined mesh + separate string."""
    parts = []
    # Upper / lower limbs via bent capsules approximated by rotated ellipsoids
    for i, (z, rot) in enumerate([((0.55), 0.55), ((-0.55), -0.55)]):
        limb = MU.create_ellipsoid(f"BowLimb_{i}", 0.035, Vector((0.35, 0.35, 3.2)), segments=24)
        limb.location = (-0.02, 0, z * 0.5)
        limb.rotation_euler = (0, 0, rot * 0.35)
        # Bend tip inward
        MU.assign_mat(limb, wood_mat)
        MU.add_subdiv(limb, 1)
        MU.smooth_shade(limb)
        parts.append(limb)

    grip = MU.create_cylinder("BowGrip", 0.04, 0.18, segments=20)
    MU.assign_mat(grip, rune_mat)
    MU.smooth_shade(grip)
    parts.append(grip)

    # Rune gems
    for i, z in enumerate((-0.35, 0.0, 0.35)):
        gem = MU.create_ellipsoid(f"Rune_{i}", 0.03, Vector((0.8, 0.5, 1.0)), segments=12)
        gem.location = (0.03, 0, z)
        MU.assign_mat(gem, rune_mat)
        parts.append(gem)

    tips = []
    for i, z in enumerate((-0.95, 0.95)):
        tip = MU.create_ellipsoid(f"BowTip_{i}", 0.04, Vector((0.7, 0.7, 1.2)), segments=12)
        tip.location = (-0.08, 0, z)
        MU.assign_mat(tip, rune_mat)
        tips.append(tip)
        parts.append(tip)

    bow = MU.join_objects(parts, "Bow")
    bow.location = (0.42, -0.05, 1.15)
    bow.rotation_euler = (0, 0, -0.2)

    string = MU.create_cylinder("BowString", 0.008, 1.85, segments=10)
    string.location = (0.55, -0.05, 1.15)
    MU.assign_mat(string, string_mat)
    return bow, string


def build_quiver(leather_mat, wood_mat) -> bpy.types.Object:
    parts = []
    q = MU.create_cylinder("QuiverBody", 0.07, 0.45, segments=20)
    q.location = (-0.28, 0.12, 1.25)
    q.rotation_euler = (0.4, 0, 0.5)
    MU.assign_mat(q, leather_mat)
    parts.append(q)
    for i in range(5):
        arrow = MU.create_cylinder(f"QuiverArrow_{i}", 0.012, 0.5, segments=8)
        arrow.location = (-0.28 + i * 0.015, 0.1, 1.45)
        arrow.rotation_euler = (0.35, 0, 0.5)
        MU.assign_mat(arrow, wood_mat)
        parts.append(arrow)
    return MU.join_objects(parts, "Quiver")


def build_rig() -> bpy.types.Object:
    arm = MU.create_armature("ArcherArmature")
    eb = MU.edit_bones(arm)
    root = MU.add_bone(eb, "Root", Vector((0, 0, 0)), Vector((0, 0, 0.1)))
    hips = MU.add_bone(eb, "Hips", Vector((0, 0, 0.95)), Vector((0, 0, 1.05)), root)
    spine = MU.add_bone(eb, "Spine", Vector((0, 0, 1.05)), Vector((0, 0, 1.25)), hips)
    chest = MU.add_bone(eb, "Chest", Vector((0, 0, 1.25)), Vector((0, 0, 1.45)), spine)
    neck = MU.add_bone(eb, "Neck", Vector((0, 0, 1.45)), Vector((0, 0, 1.55)), chest)
    head = MU.add_bone(eb, "Head", Vector((0, 0, 1.55)), Vector((0, 0, 1.75)), neck)

    for side, x in (("L", -1), ("R", 1)):
        sh = MU.add_bone(eb, f"Shoulder_{side}", Vector((0.12 * x, 0, 1.42)), Vector((0.25 * x, 0, 1.40)), chest)
        ua = MU.add_bone(eb, f"UpperArm_{side}", Vector((0.25 * x, 0, 1.40)), Vector((0.32 * x, -0.02, 1.15)), sh)
        la = MU.add_bone(eb, f"LowerArm_{side}", Vector((0.32 * x, -0.02, 1.15)), Vector((0.38 * x, -0.04, 0.9)), ua)
        MU.add_bone(eb, f"Hand_{side}", Vector((0.38 * x, -0.04, 0.9)), Vector((0.42 * x, -0.05, 0.82)), la)
        th = MU.add_bone(eb, f"Thigh_{side}", Vector((0.1 * x, 0, 0.95)), Vector((0.1 * x, 0, 0.55)), hips)
        shn = MU.add_bone(eb, f"Shin_{side}", Vector((0.1 * x, 0, 0.55)), Vector((0.1 * x, 0.02, 0.18)), th)
        MU.add_bone(eb, f"Foot_{side}", Vector((0.1 * x, 0.02, 0.18)), Vector((0.1 * x, -0.08, 0.05)), shn)

    bow_b = MU.add_bone(eb, "Bow", Vector((0.42, -0.05, 1.15)), Vector((0.42, -0.05, 1.35)), chest)
    MU.add_bone(eb, "String", Vector((0.55, -0.05, 1.15)), Vector((0.65, -0.05, 1.15)), bow_b)

    bpy.ops.object.mode_set(mode="OBJECT")
    return arm


def animate_archer(arm: bpy.types.Object) -> None:
    """Keyframe skeletal clips used by Godot AnimationPlayer."""
    clips = {
        "Idle": _anim_idle,
        "CombatIdle": _anim_combat_idle,
        "Walk": _anim_walk,
        "Run": _anim_run,
        "DrawBow": _anim_draw,
        "FireArrow": _anim_fire,
        "FireSkill": _anim_fire_skill,
        "IceSkill": _anim_ice_skill,
        "Hit": _anim_hit,
        "Dodge": _anim_dodge,
        "Victory": _anim_victory,
    }
    for name, fn in clips.items():
        MU.new_action(arm, name)
        fn(arm)
        # Push to NLA so all export
        track = arm.animation_data.nla_tracks.new()
        track.name = name
        track.strips.new(name, 1, arm.animation_data.action)


def _breath(arm, frames, amp=0.02):
    for f in frames:
        t = (f - frames[0]) / max(1, frames[-1] - frames[0])
        z = math.sin(t * math.pi * 2) * amp
        MU.key_bone(arm, "Chest", f, loc=Vector((0, 0, z)))
        MU.key_bone(arm, "Head", f, rot_euler=Euler((z * 2, 0, 0)))


def _anim_idle(arm):
    _breath(arm, [1, 20, 40, 60], 0.015)
    for f in (1, 60):
        MU.key_bone(arm, "UpperArm_L", f, rot_euler=Euler((0.1, 0, 0.15)))
        MU.key_bone(arm, "UpperArm_R", f, rot_euler=Euler((0.1, 0, -0.15)))


def _anim_combat_idle(arm):
    for f in (1, 30, 60):
        MU.key_bone(arm, "Hips", f, rot_euler=Euler((0, 0, -0.15)))
        MU.key_bone(arm, "UpperArm_L", f, rot_euler=Euler((0.4, 0.2, 0.5)))
        MU.key_bone(arm, "UpperArm_R", f, rot_euler=Euler((0.6, -0.3, -0.8)))
        MU.key_bone(arm, "LowerArm_R", f, rot_euler=Euler((0.8, 0, 0)))
        MU.key_bone(arm, "Bow", f, rot_euler=Euler((0, 0.2, -0.4)))
    _breath(arm, [1, 30, 60], 0.01)


def _anim_walk(arm):
    for f, phase in ((1, 0), (15, 1), (30, 0), (45, -1), (60, 0)):
        a = phase * 0.55
        MU.key_bone(arm, "Thigh_L", f, rot_euler=Euler((a, 0, 0)))
        MU.key_bone(arm, "Thigh_R", f, rot_euler=Euler((-a, 0, 0)))
        MU.key_bone(arm, "Shin_L", f, rot_euler=Euler((-abs(a) * 0.6, 0, 0)))
        MU.key_bone(arm, "Shin_R", f, rot_euler=Euler((-abs(a) * 0.6, 0, 0)))
        MU.key_bone(arm, "UpperArm_L", f, rot_euler=Euler((-a * 0.5, 0, 0.2)))
        MU.key_bone(arm, "UpperArm_R", f, rot_euler=Euler((a * 0.5, 0, -0.2)))
        MU.key_bone(arm, "Hips", f, loc=Vector((0, 0, abs(a) * 0.02)))


def _anim_run(arm):
    for f, phase in ((1, 0), (10, 1), (20, 0), (30, -1), (40, 0)):
        a = phase * 0.9
        MU.key_bone(arm, "Thigh_L", f, rot_euler=Euler((a, 0, 0)))
        MU.key_bone(arm, "Thigh_R", f, rot_euler=Euler((-a, 0, 0)))
        MU.key_bone(arm, "Shin_L", f, rot_euler=Euler((-abs(a) * 0.9, 0, 0)))
        MU.key_bone(arm, "Shin_R", f, rot_euler=Euler((-abs(a) * 0.9, 0, 0)))
        MU.key_bone(arm, "Spine", f, rot_euler=Euler((0.25, 0, 0)))
        MU.key_bone(arm, "UpperArm_L", f, rot_euler=Euler((-a * 0.8, 0, 0.3)))
        MU.key_bone(arm, "UpperArm_R", f, rot_euler=Euler((a * 0.8, 0, -0.3)))


def _anim_draw(arm):
    # Draw bow: right arm pulls string back, left holds bow
    MU.key_bone(arm, "UpperArm_L", 1, rot_euler=Euler((0.5, 0.3, 0.9)))
    MU.key_bone(arm, "LowerArm_L", 1, rot_euler=Euler((0.2, 0, 0)))
    MU.key_bone(arm, "UpperArm_R", 1, rot_euler=Euler((0.3, -0.2, -0.4)))
    MU.key_bone(arm, "LowerArm_R", 1, rot_euler=Euler((0.3, 0, 0)))
    MU.key_bone(arm, "String", 1, loc=Vector((0, 0, 0)))
    MU.key_bone(arm, "Chest", 1, rot_euler=Euler((0, 0, -0.1)))

    MU.key_bone(arm, "UpperArm_R", 20, rot_euler=Euler((0.9, -0.5, -1.2)))
    MU.key_bone(arm, "LowerArm_R", 20, rot_euler=Euler((1.2, 0.2, 0)))
    MU.key_bone(arm, "Hand_R", 20, rot_euler=Euler((0, 0.3, 0)))
    MU.key_bone(arm, "String", 20, loc=Vector((0.18, 0.05, 0)))
    MU.key_bone(arm, "Chest", 20, rot_euler=Euler((0, 0.05, -0.2)))
    MU.key_bone(arm, "Head", 20, rot_euler=Euler((0, -0.1, 0.15)))


def _anim_fire(arm):
    _anim_draw(arm)
    # Release
    MU.key_bone(arm, "UpperArm_R", 28, rot_euler=Euler((0.5, -0.2, -0.5)))
    MU.key_bone(arm, "LowerArm_R", 28, rot_euler=Euler((0.2, 0, 0)))
    MU.key_bone(arm, "String", 28, loc=Vector((0, 0, 0)))
    MU.key_bone(arm, "Chest", 28, rot_euler=Euler((0.05, 0, -0.05)))
    MU.key_bone(arm, "UpperArm_R", 40, rot_euler=Euler((0.4, -0.2, -0.5)))


def _anim_fire_skill(arm):
    _anim_draw(arm)
    MU.key_bone(arm, "Chest", 22, rot_euler=Euler((-0.1, 0.1, -0.25)))
    MU.key_bone(arm, "String", 22, loc=Vector((0.22, 0.08, 0)))
    MU.key_bone(arm, "UpperArm_R", 30, rot_euler=Euler((0.35, -0.1, -0.3)))
    MU.key_bone(arm, "String", 30, loc=Vector((0, 0, 0)))
    MU.key_bone(arm, "Spine", 35, rot_euler=Euler((0.15, 0, 0)))


def _anim_ice_skill(arm):
    _anim_fire_skill(arm)
    MU.key_bone(arm, "Head", 24, rot_euler=Euler((0.1, 0, 0.2)))


def _anim_hit(arm):
    MU.key_bone(arm, "Spine", 1, rot_euler=Euler((0, 0, 0)))
    MU.key_bone(arm, "Spine", 8, rot_euler=Euler((-0.35, 0.2, 0.15)))
    MU.key_bone(arm, "Head", 8, rot_euler=Euler((-0.2, 0.1, 0)))
    MU.key_bone(arm, "Spine", 24, rot_euler=Euler((0, 0, 0)))
    MU.key_bone(arm, "Head", 24, rot_euler=Euler((0, 0, 0)))


def _anim_dodge(arm):
    MU.key_bone(arm, "Hips", 1, loc=Vector((0, 0, 0)), rot_euler=Euler((0, 0, 0)))
    MU.key_bone(arm, "Hips", 10, loc=Vector((-0.4, -0.3, 0.15)), rot_euler=Euler((0.4, 0, 1.2)))
    MU.key_bone(arm, "Hips", 20, loc=Vector((-0.7, 0.1, 0.05)), rot_euler=Euler((0.1, 0, 2.5)))
    MU.key_bone(arm, "Hips", 30, loc=Vector((0, 0.2, 0)), rot_euler=Euler((0, 0, 3.14)))
    MU.key_bone(arm, "Hips", 40, loc=Vector((0, 0, 0)), rot_euler=Euler((0, 0, 0)))


def _anim_victory(arm):
    for f, raise_amt in ((1, 0.0), (20, 1.2), (40, 1.0), (60, 1.15)):
        MU.key_bone(arm, "UpperArm_R", f, rot_euler=Euler((-raise_amt, 0, -0.3)))
        MU.key_bone(arm, "UpperArm_L", f, rot_euler=Euler((-raise_amt * 0.4, 0, 0.3)))
        MU.key_bone(arm, "Head", f, rot_euler=Euler((-0.15, 0, 0)))
        MU.key_bone(arm, "Chest", f, rot_euler=Euler((-0.1, 0, 0)))


def render_turnaround(arm_root_z=0.0) -> None:
    OUT_RENDERS.mkdir(parents=True, exist_ok=True)
    MU.setup_render()
    MU.add_sun(3.5, (0.95, 0.3, 0.55))
    # Fill light
    fill = bpy.data.lights.new("Fill", type="AREA")
    fill.energy = 40
    fill_obj = bpy.data.objects.new("Fill", fill)
    bpy.context.collection.objects.link(fill_obj)
    fill_obj.location = (-2.5, -1.5, 2.5)

    angles = {
        "front": (0, -4.2, 1.5),
        "three_quarter": (3.0, -3.5, 1.7),
        "side": (4.5, 0.0, 1.5),
        "back": (0.5, 4.2, 1.6),
    }
    for name, loc in angles.items():
        MU.add_camera(loc, look_at=(0, 0, 1.15))
        MU.render_to(str(OUT_RENDERS / f"archer_{name}.png"))
        print("RENDER", name)


def main() -> None:
    MU.clear_scene()
    OUT_TEX.mkdir(parents=True, exist_ok=True)
    face_tex = make_face_texture(OUT_TEX / "archer_face.png")
    armor_tex = make_armor_texture(OUT_TEX / "archer_armor.png")

    skin = MU.new_mat("Skin", (0.92, 0.78, 0.68, 1), roughness=0.55)
    face = mat_with_image("Face", face_tex, roughness=0.5)
    armor = mat_with_image("Armor", armor_tex, roughness=0.4, metallic=0.15)
    leather = MU.new_mat("Leather", (0.12, 0.1, 0.1, 1), roughness=0.7)
    gold = MU.new_mat("Gold", (0.85, 0.68, 0.25, 1), roughness=0.25, metallic=0.85)
    hair = MU.new_mat("Hair", (0.12, 0.35, 0.22, 1), roughness=0.35)
    wood = MU.new_mat("Wood", (0.35, 0.22, 0.12, 1), roughness=0.55)
    rune = MU.new_mat("Rune", (0.2, 0.85, 0.45, 1), roughness=0.3, emission=(0.2, 1.0, 0.5, 1), emission_strength=1.5)
    string_m = MU.new_mat("String", (0.9, 0.88, 0.8, 1), roughness=0.4)

    body_parts = build_body(skin, armor, leather, gold)
    head = build_head(skin, face)
    hairs = build_hair(hair)
    bow, string = build_bow(wood, rune, string_m)
    quiver = build_quiver(leather, wood)

    # Join body+head+hair into one skinned mesh for cleaner weights
    body_join = MU.join_objects(body_parts + [head] + hairs + [quiver], "ArcherBody")
    MU.smooth_shade(body_join)

    arm = build_rig()
    # Bind body
    MU.bind_mesh(arm, body_join)
    # Parent bow/string to bones manually
    bow.parent = arm
    bow.parent_type = "BONE"
    bow.parent_bone = "Bow"
    bow.location = (0, 0, 0)
    string.parent = arm
    string.parent_type = "BONE"
    string.parent_bone = "String"
    string.location = (0, 0, 0)

    animate_archer(arm)

    # Save blend
    OUT_BLEND.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT_BLEND))
    print("SAVED", OUT_BLEND)

    # Renders before export (with materials)
    render_turnaround()

    # Export GLB
    OUT_GLB.parent.mkdir(parents=True, exist_ok=True)
    # Select archer-related
    bpy.ops.object.select_all(action="DESELECT")
    for o in bpy.data.objects:
        o.select_set(True)
    MU.export_glb(str(OUT_GLB))
    print("EXPORTED", OUT_GLB, "size", OUT_GLB.stat().st_size)


if __name__ == "__main__":
    main()
