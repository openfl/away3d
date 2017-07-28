[![Apache 2.0 License](https://img.shields.io/badge/license-Apache-blue.svg?style=flat)](LICENSE.md) [![Haxelib Version](https://img.shields.io/github/tag/openfl/away3d.svg?style=flat&label=haxelib)](http://lib.haxe.org/p/away3d) [![Build Status](https://img.shields.io/circleci/project/github/openfl/away3d/master.svg)](https://circleci.com/gh/openfl/away3d)

Away3D
======

Away3D is an open source platform for developing interactive 3D graphics for video games and applications.


Features
--------

- Cross-platform target support (Flash, HTML5, iOS, Android, Windows, Mac, Linux)
- Texture mapping with mipmapping
- Lighting
- Shadow mapping (in most cases)
- Model loading: 3DS, AWD, MD5, MD2, DAE
- Skeleton animation
- Skinned animation
- 3D particle system
- Line drawing (Segments & SegmentSets)


Installation
------------

You can easily install Away3D with OpenFL:

    openfl install away3d

To add it to an OpenFL project, add this to your project file:

```xml
<haxelib name="away3d" />
```

To list available samples, run:

    openfl create away3d


Development Builds
------------------

Clone the Away3D repository:

    git clone https://github.com/openfl/away3d


Tell haxelib where your development copy of Away3D is installed:

    haxelib dev away3d away3d


To return to release builds:

    haxelib dev away3d

