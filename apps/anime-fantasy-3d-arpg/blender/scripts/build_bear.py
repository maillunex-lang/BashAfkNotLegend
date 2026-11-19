#!/usr/bin/env python3
"""
ORIGINAL fantasy bear — geometry authored in Blender Python.
No third-party creature meshes.
"""
from __future__ import annotations

import math
import sys
from pathlib import Path

import bpy
from mathutils import Euler, Vector

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
import mesh_utils as MU  # noqa: E402

OUT_BLEND = ROOT / "blender" / "bear_original.blend"
OUT_GLB = ROOT / "assets" / "models" / "bear.glb"
OUT_RENDERS = ROOT / "assets" / "renders" / "bear"
OUT_TEX = ROOT / "assets" / "textures"


def make_fur_texture(path: Path, size: int = 512) -> Path:
    from PIL import Image, ImageDraw
    import random

    path.parent.mkdir(parents=True, exist_ok=True)
    rnd = random.Random(42)
    im = Image.new("RGBA", (size, size), (70, 48, 32, 255))
    d = ImageDraw.Draw(im)
    for _ in range(4000):
        x, y = rnd.randint(0, size - 1), rnd.randint(0, size - 1)
        c = 50 + rnd.randint(0, 40)
        d.line([(x, y), (x + rnd.randint(-3, 3), y + rnd.randint(4, 12))], fill=(c, int(c * 0.7), int(c * 0.45), 255), width=1)
    # Magical cyan marks
    for cx, cy in [(120, 180), (380, 200), (250, 360), (180, 400)]:
        d.ellipse([cx - 18, cy - 10, cx + 18, cy + 10], outline=(80, 220, 255, 220), width=3)
        d.ellipse([cx - 8, cy - 8, cx + 8, cy + 8], fill=(60, 180, 255, 100))
    im.save(path)
    return path


def mat_with_image(name: str, img_path: Path, roughness=0.65, metallic=0.0, emission=None, em_str=0.0):
    mat = MU.new_mat(name, (1, 1, 1, 1), roughness=roughness, metallic=metallic, emission=emission, emission_strength=em_str)
    nt = mat.node_tree
    nodes, links = nt.nodes, nt.links
    bsdf = nodes.get("Principled BSDF")
    tex = nodes.new("ShaderNodeTexImage")
    tex.location = (-300, 0)
    tex.image = bpy.data.images.load(str(img_path))
    links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    return mat


def build_bear_meshes(fur_mat, armor_mat, claw_mat, glow_mat) -> bpy.types.Object:
    parts = []
    # Massive body
    body = MU.create_ellipsoid("BearBody", 0.55, Vector((1.15, 1.6, 0.95)), segments=40)
    body.location = (0, 0.1, 0.85)
    MU.assign_mat(body, fur_mat)
    MU.add_subdiv(body, 2)
    MU.smooth_shade(body)
    parts.append(body)

    # Shoulder hump
    hump = MU.create_ellipsoid("Hump", 0.35, Vector((1.0, 0.9, 0.7)), segments=28)
    hump.location = (0, -0.15, 1.25)
    MU.assign_mat(hump, fur_mat)
    MU.add_subdiv(hump, 1)
    MU.smooth_shade(hump)
    parts.append(hump)

    # Head
    head = MU.create_ellipsoid("BearHead", 0.32, Vector((1.0, 1.15, 0.95)), segments=36)
    head.location = (0, -0.75, 1.15)
    MU.assign_mat(head, fur_mat)
    MU.add_subdiv(head, 2)
    MU.smooth_shade(head)
    parts.append(head)

    # Snout
    snout = MU.create_ellipsoid("Snout", 0.16, Vector((0.85, 1.4, 0.7)), segments=24)
    snout.location = (0, -1.05, 1.0)
    MU.assign_mat(snout, fur_mat)
    MU.smooth_shade(snout)
    parts.append(snout)

    nose = MU.create_ellipsoid("Nose", 0.07, Vector((1.0, 0.8, 0.7)), segments=16)
    nose.location = (0, -1.22, 1.02)
    MU.assign_mat(nose, claw_mat)
    parts.append(nose)

    # Ears
    for side, x in (("L", -0.22), ("R", 0.22)):
        ear = MU.create_ellipsoid(f"Ear_{side}", 0.1, Vector((0.7, 0.5, 1.0)), segments=16)
        ear.location = (x, -0.65, 1.4)
        MU.assign_mat(ear, fur_mat)
        MU.smooth_shade(ear)
        parts.append(ear)

    # Eyes glow
    for side, x in (("L", -0.12), ("R", 0.12)):
        eye = MU.create_ellipsoid(f"Eye_{side}", 0.045, Vector((1, 0.7, 1)), segments=12)
        eye.location = (x, -0.95, 1.2)
        MU.assign_mat(eye, glow_mat)
        parts.append(eye)

    # Legs
    for name, loc in (
        ("FL", (-0.28, -0.35, 0.4)),
        ("FR", (0.28, -0.35, 0.4)),
        ("BL", (-0.32, 0.45, 0.42)),
        ("BR", (0.32, 0.45, 0.42)),
    ):
        leg = MU.create_capsule_mesh(f"Leg_{name}", 0.12, 0.55, segments=20)
        leg.location = loc
        MU.assign_mat(leg, fur_mat)
        MU.add_subdiv(leg, 1)
        MU.smooth_shade(leg)
        parts.append(leg)
        paw = MU.create_ellipsoid(f"Paw_{name}", 0.14, Vector((1.1, 1.3, 0.45)), segments=16)
        paw.location = (loc[0], loc[1] - 0.05, 0.08)
        MU.assign_mat(paw, fur_mat)
        parts.append(paw)
        for ci, ox in enumerate((-0.06, 0.0, 0.06)):
            claw = MU.create_ellipsoid(f"Claw_{name}_{ci}", 0.03, Vector((0.5, 1.4, 0.4)), segments=10)
            claw.location = (loc[0] + ox, loc[1] - 0.16, 0.06)
            MU.assign_mat(claw, claw_mat)
            parts.append(claw)

    # Fantasy armor plates
    for i, (loc, scale) in enumerate([
        ((0, -0.2, 1.05), (1.3, 0.4, 0.9)),
        ((-0.45, 0.0, 1.0), (0.5, 0.7, 0.8)),
        ((0.45, 0.0, 1.0), (0.5, 0.7, 0.8)),
    ]):
        plate = MU.create_ellipsoid(f"Armor_{i}", 0.25, Vector(scale), segments=20)
        plate.location = loc
        MU.assign_mat(plate, armor_mat)
        MU.add_subdiv(plate, 1)
        MU.smooth_shade(plate)
        parts.append(plate)

    # Magic rune stones on shoulders
    for side, x in (("L", -0.4), ("R", 0.4)):
        rune = MU.create_ellipsoid(f"MagicRune_{side}", 0.08, Vector((1, 0.6, 1)), segments=12)
        rune.location = (x, -0.15, 1.35)
        MU.assign_mat(rune, glow_mat)
        parts.append(rune)

    # Tail
    tail = MU.create_ellipsoid("Tail", 0.1, Vector((0.8, 1.2, 0.7)), segments=16)
    tail.location = (0, 0.85, 0.85)
    MU.assign_mat(tail, fur_mat)
    parts.append(tail)

    body = MU.join_objects(parts, "BearBody")
    MU.smooth_shade(body)
    return body


def build_rig() -> bpy.types.Object:
    arm = MU.create_armature("BearArmature")
    eb = MU.edit_bones(arm)
    root = MU.add_bone(eb, "Root", Vector((0, 0, 0)), Vector((0, 0, 0.1)))
    hips = MU.add_bone(eb, "Hips", Vector((0, 0.2, 0.75)), Vector((0, 0.05, 0.9)), root)
    spine = MU.add_bone(eb, "Spine", Vector((0, 0.05, 0.9)), Vector((0, -0.2, 1.05)), hips)
    chest = MU.add_bone(eb, "Chest", Vector((0, -0.2, 1.05)), Vector((0, -0.45, 1.15)), spine)
    neck = MU.add_bone(eb, "Neck", Vector((0, -0.45, 1.15)), Vector((0, -0.65, 1.2)), chest)
    head = MU.add_bone(eb, "Head", Vector((0, -0.65, 1.2)), Vector((0, -0.95, 1.15)), neck)
    MU.add_bone(eb, "Jaw", Vector((0, -0.95, 1.05)), Vector((0, -1.15, 0.95)), head)

    for side, x in (("L", -1), ("R", 1)):
        # Front
        f1 = MU.add_bone(eb, f"FrontUpper_{side}", Vector((0.28 * x, -0.35, 0.7)), Vector((0.28 * x, -0.35, 0.4)), chest)
        f2 = MU.add_bone(eb, f"FrontLower_{side}", Vector((0.28 * x, -0.35, 0.4)), Vector((0.28 * x, -0.4, 0.1)), f1)
        MU.add_bone(eb, f"FrontPaw_{side}", Vector((0.28 * x, -0.4, 0.1)), Vector((0.28 * x, -0.55, 0.05)), f2)
        # Back
        b1 = MU.add_bone(eb, f"BackUpper_{side}", Vector((0.32 * x, 0.45, 0.75)), Vector((0.32 * x, 0.45, 0.42)), hips)
        b2 = MU.add_bone(eb, f"BackLower_{side}", Vector((0.32 * x, 0.45, 0.42)), Vector((0.32 * x, 0.5, 0.1)), b1)
        MU.add_bone(eb, f"BackPaw_{side}", Vector((0.32 * x, 0.5, 0.1)), Vector((0.32 * x, 0.65, 0.05)), b2)

    MU.add_bone(eb, "Tail", Vector((0, 0.75, 0.85)), Vector((0, 1.0, 0.75)), hips)
    bpy.ops.object.mode_set(mode="OBJECT")
    return arm


def animate_bear(arm: bpy.types.Object) -> None:
    clips = {
        "Idle": _idle,
        "Walk": _walk,
        "Run": _run,
        "Roar": _roar,
        "Attack": _attack,
        "Hit": _hit,
        "FireHit": _fire_hit,
        "IceHit": _ice_hit,
        "Stagger": _stagger,
        "Death": _death,
    }
    for name, fn in clips.items():
        MU.new_action(arm, name)
        fn(arm)
        track = arm.animation_data.nla_tracks.new()
        track.name = name
        track.strips.new(name, 1, arm.animation_data.action)


def _idle(arm):
    for f in (1, 30, 60):
        z = 0.02 if f == 30 else 0.0
        MU.key_bone(arm, "Chest", f, loc=Vector((0, 0, z)))
        MU.key_bone(arm, "Head", f, rot_euler=Euler((z * 3, 0, 0)))


def _walk(arm):
    for f, p in ((1, 0), (15, 1), (30, 0), (45, -1), (60, 0)):
        a = p * 0.5
        MU.key_bone(arm, "FrontUpper_L", f, rot_euler=Euler((a, 0, 0)))
        MU.key_bone(arm, "FrontUpper_R", f, rot_euler=Euler((-a, 0, 0)))
        MU.key_bone(arm, "BackUpper_L", f, rot_euler=Euler((-a, 0, 0)))
        MU.key_bone(arm, "BackUpper_R", f, rot_euler=Euler((a, 0, 0)))
        MU.key_bone(arm, "Hips", f, loc=Vector((0, 0, abs(a) * 0.03)))


def _run(arm):
    for f, p in ((1, 0), (10, 1), (20, 0), (30, -1), (40, 0)):
        a = p * 0.85
        MU.key_bone(arm, "FrontUpper_L", f, rot_euler=Euler((a, 0, 0)))
        MU.key_bone(arm, "FrontUpper_R", f, rot_euler=Euler((-a, 0, 0)))
        MU.key_bone(arm, "BackUpper_L", f, rot_euler=Euler((-a, 0, 0)))
        MU.key_bone(arm, "BackUpper_R", f, rot_euler=Euler((a, 0, 0)))
        MU.key_bone(arm, "Spine", f, rot_euler=Euler((0.2, 0, 0)))


def _roar(arm):
    MU.key_bone(arm, "Head", 1, rot_euler=Euler((0, 0, 0)))
    MU.key_bone(arm, "Jaw", 1, rot_euler=Euler((0, 0, 0)))
    MU.key_bone(arm, "Head", 15, rot_euler=Euler((-0.5, 0, 0)))
    MU.key_bone(arm, "Jaw", 15, rot_euler=Euler((0.7, 0, 0)))
    MU.key_bone(arm, "Chest", 15, loc=Vector((0, 0, 0.05)))
    MU.key_bone(arm, "Head", 35, rot_euler=Euler((-0.3, 0, 0)))
    MU.key_bone(arm, "Jaw", 35, rot_euler=Euler((0.4, 0, 0)))
    MU.key_bone(arm, "Head", 50, rot_euler=Euler((0, 0, 0)))
    MU.key_bone(arm, "Jaw", 50, rot_euler=Euler((0, 0, 0)))


def _attack(arm):
    MU.key_bone(arm, "FrontUpper_R", 1, rot_euler=Euler((0, 0, 0)))
    MU.key_bone(arm, "FrontUpper_R", 12, rot_euler=Euler((-1.2, 0.3, 0.4)))
    MU.key_bone(arm, "FrontLower_R", 12, rot_euler=Euler((-0.4, 0, 0)))
    MU.key_bone(arm, "Chest", 12, rot_euler=Euler((0, 0, -0.3)))
    MU.key_bone(arm, "FrontUpper_R", 22, rot_euler=Euler((0.9, -0.2, -0.2)))
    MU.key_bone(arm, "FrontUpper_R", 35, rot_euler=Euler((0, 0, 0)))
    MU.key_bone(arm, "Chest", 35, rot_euler=Euler((0, 0, 0)))


def _hit(arm):
    MU.key_bone(arm, "Spine", 1, rot_euler=Euler((0, 0, 0)))
    MU.key_bone(arm, "Spine", 8, rot_euler=Euler((-0.25, 0.15, 0.1)))
    MU.key_bone(arm, "Head", 8, rot_euler=Euler((-0.2, 0.1, 0)))
    MU.key_bone(arm, "Spine", 24, rot_euler=Euler((0, 0, 0)))


def _fire_hit(arm):
    _hit(arm)
    MU.key_bone(arm, "Head", 10, rot_euler=Euler((-0.35, 0.2, 0.15)))


def _ice_hit(arm):
    _hit(arm)
    MU.key_bone(arm, "Hips", 10, loc=Vector((0, 0.05, 0)))
    MU.key_bone(arm, "Hips", 30, loc=Vector((0, 0, 0)))


def _stagger(arm):
    MU.key_bone(arm, "Hips", 1, loc=Vector((0, 0, 0)), rot_euler=Euler((0, 0, 0)))
    MU.key_bone(arm, "Hips", 15, loc=Vector((0.15, 0.1, -0.05)), rot_euler=Euler((0.2, 0, 0.25)))
    MU.key_bone(arm, "Hips", 35, loc=Vector((-0.1, 0.05, 0)), rot_euler=Euler((0.1, 0, -0.2)))
    MU.key_bone(arm, "Hips", 50, loc=Vector((0, 0, 0)), rot_euler=Euler((0, 0, 0)))


def _death(arm):
    MU.key_bone(arm, "Hips", 1, loc=Vector((0, 0, 0)), rot_euler=Euler((0, 0, 0)))
    MU.key_bone(arm, "Spine", 1, rot_euler=Euler((0, 0, 0)))
    MU.key_bone(arm, "Hips", 20, loc=Vector((0, 0.2, -0.15)), rot_euler=Euler((0.6, 0.3, 0.8)))
    MU.key_bone(arm, "Spine", 20, rot_euler=Euler((0.4, 0, 0.3)))
    MU.key_bone(arm, "Head", 20, rot_euler=Euler((0.5, 0, 0.2)))
    MU.key_bone(arm, "Hips", 45, loc=Vector((0, 0.35, -0.45)), rot_euler=Euler((1.2, 0.4, 1.4)))
    MU.key_bone(arm, "FrontUpper_L", 45, rot_euler=Euler((0.5, 0, 0)))
    MU.key_bone(arm, "FrontUpper_R", 45, rot_euler=Euler((0.5, 0, 0)))


def render_turnaround() -> None:
    OUT_RENDERS.mkdir(parents=True, exist_ok=True)
    MU.setup_render()
    MU.add_sun(3.2, (1.0, 0.25, 0.4))
    fill = bpy.data.lights.new("Fill", type="AREA")
    fill.energy = 50
    fo = bpy.data.objects.new("Fill", fill)
    bpy.context.collection.objects.link(fo)
    fo.location = (-3, -2, 3)
    angles = {
        "front": (0, -5.5, 1.6),
        "three_quarter": (4.0, -4.5, 2.0),
        "side": (5.5, 0.2, 1.7),
        "back": (0.5, 5.5, 1.8),
    }
    for name, loc in angles.items():
        MU.add_camera(loc, look_at=(0, 0, 0.9))
        MU.render_to(str(OUT_RENDERS / f"bear_{name}.png"))
        print("RENDER", name)


def main() -> None:
    MU.clear_scene()
    OUT_TEX.mkdir(parents=True, exist_ok=True)
    fur_tex = make_fur_texture(OUT_TEX / "bear_fur.png")
    fur = mat_with_image("Fur", fur_tex, roughness=0.75)
    armor = MU.new_mat("BearArmor", (0.25, 0.28, 0.32, 1), roughness=0.35, metallic=0.7)
    claw = MU.new_mat("Claw", (0.15, 0.12, 0.1, 1), roughness=0.4)
    glow = MU.new_mat("MagicGlow", (0.3, 0.85, 1.0, 1), roughness=0.25, emission=(0.3, 0.9, 1.0, 1), emission_strength=3.0)

    body = build_bear_meshes(fur, armor, claw, glow)
    arm = build_rig()
    MU.bind_mesh(arm, body)
    animate_bear(arm)

    OUT_BLEND.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT_BLEND))
    print("SAVED", OUT_BLEND)

    render_turnaround()

    OUT_GLB.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    MU.export_glb(str(OUT_GLB))
    print("EXPORTED", OUT_GLB, OUT_GLB.stat().st_size)


if __name__ == "__main__":
    main()
