#!/usr/bin/env python3
"""Re-export archer2 with only Archery_Shot + JPEG textures + bow on LeftHand."""
from __future__ import annotations

import math
import sys
from pathlib import Path

import bpy
from mathutils import Euler, Vector

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
import mesh_utils as MU
from attach_bow_to_user_archer import build_bow

SRC = ROOT / "assets" / "models" / "incoming" / "archer2_user.glb"
OUT = ROOT / "assets" / "models" / "archer2_with_bow.glb"


def main() -> None:
    MU.clear_scene()
    bpy.ops.import_scene.gltf(filepath=str(SRC))
    for o in list(bpy.data.objects):
        if o.type == "MESH" and "ico" in o.name.lower():
            bpy.data.objects.remove(o, do_unlink=True)

    arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    for a in list(bpy.data.actions):
        if "Archery" not in a.name:
            bpy.data.actions.remove(a)
    print("kept", [a.name for a in bpy.data.actions])
    if arm.animation_data is None:
        arm.animation_data_create()
    if bpy.data.actions:
        arm.animation_data.action = bpy.data.actions[0]

    lh = next(b for b in arm.data.bones if b.name.endswith("LeftHand"))
    bow, string = build_bow(scale=1.12)
    for obj, loc in (
        (bow, Vector((0.0, 0.12, 0.0))),
        (string, Vector((0.0, 0.12, 0.14))),
    ):
        obj.parent = arm
        obj.parent_type = "BONE"
        obj.parent_bone = lh.name
        obj.location = loc
        obj.rotation_euler = Euler((math.radians(90), 0, math.radians(-90)))
        obj.scale = Vector((1.12, 1.12, 1.12))

    for name, loc in (("Socket_Muzzle", Vector((0.0, 0.34, 0.1))), ("Socket_Hand_L", Vector((0, 0, 0)))):
        emp = bpy.data.objects.new(name, None)
        bpy.context.collection.objects.link(emp)
        emp.parent = arm
        emp.parent_type = "BONE"
        emp.parent_bone = lh.name
        emp.location = loc

    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(
        filepath=str(OUT),
        export_format="GLB",
        use_selection=True,
        export_animations=True,
        export_force_sampling=True,
        export_apply=False,
        export_image_format="JPEG",
        export_jpeg_quality=75,
    )
    print("SLIM", OUT, OUT.stat().st_size)


if __name__ == "__main__":
    main()
