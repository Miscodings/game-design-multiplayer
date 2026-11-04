"""Helpers to write GameMaker sprite resources (and register them in the .yyp) from PIL images."""
import json, os, re, uuid
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
YYP = os.path.join(ROOT, "GameDesignMultiplayer.yyp")


def _g():
    return str(uuid.uuid4())


def write_sprite(name, frames, xorigin, yorigin, mask=None, collision_kind=1):
    """frames: list of RGBA PIL images, all the same size.
    mask: optional (left, top, right, bottom) inclusive collision box, else full image."""
    w, h = frames[0].size
    d = os.path.join(ROOT, "sprites", name)
    if os.path.isdir(d):
        # remove old frame files so re-runs don't pile up GUID folders
        for root, dirs, files in os.walk(d, topdown=False):
            for f in files:
                os.remove(os.path.join(root, f))
            for x in dirs:
                os.rmdir(os.path.join(root, x))
    os.makedirs(d, exist_ok=True)
    layer = _g()
    fids = [_g() for _ in frames]
    for fid, im in zip(fids, frames):
        im.convert("RGBA").save(os.path.join(d, fid + ".png"))
        ld = os.path.join(d, "layers", fid)
        os.makedirs(ld, exist_ok=True)
        im.convert("RGBA").save(os.path.join(ld, layer + ".png"))
    if mask:
        bl, bt, br, bb = mask
        bbox_mode = 2
    else:
        bl, bt, br, bb = 0, 0, w - 1, h - 1
        bbox_mode = 0
    n = len(frames)
    frame_json = ",\n".join(
        '    {"$GMSpriteFrame":"v1","%Name":"' + f + '","name":"' + f + '","resourceType":"GMSpriteFrame","resourceVersion":"2.0",}'
        for f in fids)
    keys = ",\n".join(
        '            {"$Keyframe<SpriteFrameKeyframe>":"","Channels":{\n'
        '                "0":{"$SpriteFrameKeyframe":"","Id":{"name":"' + f + '","path":"sprites/' + name + '/' + name + '.yy",},"resourceType":"SpriteFrameKeyframe","resourceVersion":"2.0",},\n'
        '              },"Disabled":false,"id":"' + _g() + '","IsCreationKey":false,"Key":' + str(float(i)) + ',"Length":1.0,"resourceType":"Keyframe<SpriteFrameKeyframe>","resourceVersion":"2.0","Stretch":false,}'
        for i, f in enumerate(fids))
    yy = f'''{{
  "$GMSprite":"v2",
  "%Name":"{name}",
  "bboxMode":{bbox_mode},
  "bbox_bottom":{bb},
  "bbox_left":{bl},
  "bbox_right":{br},
  "bbox_top":{bt},
  "collisionKind":{collision_kind},
  "collisionTolerance":0,
  "DynamicTexturePage":false,
  "edgeFiltering":false,
  "For3D":false,
  "frames":[
{frame_json},
  ],
  "gridX":0,
  "gridY":0,
  "height":{h},
  "HTile":false,
  "layers":[
    {{"$GMImageLayer":"","%Name":"{layer}","blendMode":0,"displayName":"default","isLocked":false,"name":"{layer}","opacity":100.0,"resourceType":"GMImageLayer","resourceVersion":"2.0","visible":true,}},
  ],
  "name":"{name}",
  "nineSlice":null,
  "origin":9,
  "parent":{{
    "name":"sprites",
    "path":"folders/sprites.yy",
  }},
  "preMultiplyAlpha":false,
  "resourceType":"GMSprite",
  "resourceVersion":"2.0",
  "sequence":{{
    "$GMSequence":"v1",
    "%Name":"{name}",
    "autoRecord":true,
    "backdropHeight":768,
    "backdropImageOpacity":0.5,
    "backdropImagePath":"",
    "backdropWidth":1366,
    "backdropXOffset":0.0,
    "backdropYOffset":0.0,
    "events":{{
      "$KeyframeStore<MessageEventKeyframe>":"",
      "Keyframes":[],
      "resourceType":"KeyframeStore<MessageEventKeyframe>",
      "resourceVersion":"2.0",
    }},
    "eventStubScript":null,
    "eventToFunction":{{}},
    "length":{float(n)},
    "lockOrigin":false,
    "moments":{{
      "$KeyframeStore<MomentsEventKeyframe>":"",
      "Keyframes":[],
      "resourceType":"KeyframeStore<MomentsEventKeyframe>",
      "resourceVersion":"2.0",
    }},
    "name":"{name}",
    "playback":1,
    "playbackSpeed":30.0,
    "playbackSpeedType":0,
    "resourceType":"GMSequence",
    "resourceVersion":"2.0",
    "showBackdrop":true,
    "showBackdropImage":false,
    "timeUnits":1,
    "tracks":[
      {{"$GMSpriteFramesTrack":"","builtinName":0,"events":[],"inheritsTrackColour":true,"interpolation":1,"isCreationTrack":false,"keyframes":{{"$KeyframeStore<SpriteFrameKeyframe>":"","Keyframes":[
{keys},
          ],"resourceType":"KeyframeStore<SpriteFrameKeyframe>","resourceVersion":"2.0",}},"modifiers":[],"name":"frames","resourceType":"GMSpriteFramesTrack","resourceVersion":"2.0","spriteId":null,"trackColour":0,"tracks":[],"traits":0,}},
    ],
    "visibleRange":null,
    "volume":1.0,
    "xorigin":{int(xorigin)},
    "yorigin":{int(yorigin)},
  }},
  "swatchColours":null,
  "swfPrecision":0.5,
  "textureGroupId":{{
    "name":"Default",
    "path":"texturegroups/Default",
  }},
  "type":0,
  "VTile":false,
  "width":{w},
}}'''
    with open(os.path.join(d, name + ".yy"), "w", encoding="utf8", newline="\n") as f:
        f.write(yy)
    register("sprites", name)


def register(kind, name, room_order=False):
    """Add a resource to the .yyp Resources list (kind: sprites/objects/scripts/rooms/fonts)."""
    s = open(YYP, encoding="utf8").read()
    path = f"{kind}/{name}/{name}.yy"
    line = '    {"id":{"name":"%s","path":"%s",},},\n' % (name, path)
    if line.strip() not in s:
        # insert at end of Resources array: it ends right before '  ],\n  "resourceType":"GMProject"'
        marker = '  ],\n  "resourceType":"GMProject",'
        assert marker in s, "yyp layout changed"
        s = s.replace(marker, line + marker, 1)
    if room_order:
        node = '    {"roomId":{"name":"%s","path":"%s",},},\n' % (name, path)
        if node.strip() not in s:
            marker = '  ],\n  "templateType":"game",'
            assert marker in s
            s = s.replace(marker, node + marker, 1)
    open(YYP, "w", encoding="utf8", newline="\n").write(s)
