
5.0.6
-----
- Improved support for multiple Away3D/Starling layers
- OpenFL 8 and Haxe 4 preview 3 minor fixes

5.0.5
-----
- Fixed parsers to be kept even when using for -dce full
- Fixed shader initialization values

5.0.4
-----
- Fixed range behavior in DepthOfField filter
- Fixed endianness in AWD2Parser

5.0.3
-----
- Minor fix for OpenFL 6

5.0.2
-----
- Updated to only request Stage3D context if one is not available already

5.0.1
-----
- Fixed UV mapping for non-tile6 CubeGeometry texturing
- Various compile and runtime fixes

5.0.0
-----
- Major improvements for use with OpenFL 4
- Added support for anisotropic texture filtering

4.1.6
-----
- Memory optimisations for internal Matrix3D and Vector3D use
- Fix to zIndex calculation on Entities with non-root parent. Closes #659
- Fix for removing effects methods on a multipass material. Closes #671
- Updated context loss handling for views with 3D filters. Closes #669
- Corrected pivot point calculation for scaled meshes. Closes #650
- Fix for background texture renderer when using BlendMode on a Mesh. Closes #569
- Fix for controller using targets with non-root parent. Closes #377
- Compatibility fix for UV animation applied to a multipass material. Closes #553
- Stability update to StereoView3D. Closes #466
- Compatibility fix to calling Merge.apply() to meshes with lit materials. Closes #624
- Compatibility fix for SpriteSheetAnimator applied to materials with shadows enabled. Closes #617
- Enable doublesided meshes to be used with OutlineMethod. Closes #604
- Visual discrepancy fix between single pass and multipass materials when using fog effects method. Closes #596
- Fix to filtered shadow method when using cascading shadows
- Fix to segment set rendering when using 3d filters
- Fix to multipass material when using multiple point lights
- Added useSmoothingGroups option in 3DS parser to allow smoothing on files with no smoothing group data
- Fix for play method on animators to restart stopped animations when playing the same state
- Fix to duration property for non-looping animations
- Updates to AWD and 3DS parser to allow class instance reuse on multiple assets.

4.1.5
-----
- Fix to SegmentSet bounds calculations. Closes #610
- Added support for new ATF format. Closes #615
- Fix to background image when using a scissorRect. Closes #622
- Optimisation to MD2 parser. Closes #631
- Fix to pitch/roll/yaw/rotate for scaled objects. Closes #626
- Fix on filter method for custom filterFunc. Closes #619
- Added support for 4096x4096 textures. Closes #647

4.1.4 (Gold)
------------
- Added baseDependency getter to AssetLoader
- New Wireframe regular polygon primitive
- Added getCenter() method to Bounds
- Updated geometry primitives to use scaleU and scaleV
- Code formatting and cleaning
- ASDoc updates in comments
- Updated Bounds to ignore lights
- Fix to unproject (closes #446)
- Add wrapPanAngle to FirstPersonController
- Fix to Wireframe geometry primitive properties and geometry updates
- Fix for runtime error when removing a lightpicker from a material with a shadow method
- Fix to GradientDiffuseMethod to stop material from disappearing when no lights are applied
- Get rid of compilation warnings in ViewVolume
- Fix for incorrect sorting with blended entities (Closes #605)
- Fix to Loader3D when automatically adding root objects to the scene from an AWD file

4.1.3
-----
- Fix issue with Segment thickness when sciccorRect is set in a view
- Fixed Bounds.getMeshBounds()
- Fixed index setting of ParticleFollowState
- Fix for sharing context collider with overlapping views

4.1.2
-----
- Upgraded AWD parser to version 2.1
- Added SphereMaker Command
- Fix to animation errors and container mismatches on Collada parser (Closes #428 & #445)
- Fix for using second normal on SimpleWaterNormalMethod. Closes #558.
- Fixes to memory leaks around animators (Closes #562)
- Moved interleaveBuffers() method from away3d.utils.GeometryUtil to away3d.tools.utils.GeomUtils and removed away3d.utils.GeometryUtil
- Removed dummy COLLADA_ROOT_ container from Collada parser
- Fix to operation of PerspectiveOffCenterLens
- Fix State reseting when device loss experienced for animations
- Added Basic 3D multitouch support
- Extend LookAtController and HoverController to allow upAxis to be defined
- Update Epsilon value in Shadow Methods to be the equivalent of inverse-distance for both point and directional lights
- Re-worked getContainerBounds method to work with translations and rotations of nested containers and entities.
- Added bounds for Segment Sets
- Fixes to Geometry primitive normals
- Fixes to various AssetLoader issues and parser inconsistencies
- Orthographic lens fixed to work with sharedcontext views
- Various fixes to SegmentSet, added support for multiple buffers
- Picking fixes for sharedcontext views
- Added ParticleRotateToPositionNode in particle animators

4.1.1 (Beta)
------------
- Added mouseEnabled, mouseChildren and extra properties to Mesh.clone(). Closes #414
- Added WireframeTetrahedron geometry primitive (#375)
- Added support for constrained mode
- Added BlendMode.LAYER support for entities.
- Refactor to worldspace calcuations for scene partitions
- Improvements to shadow rendering
- Fixes to normal values for various primitive geometry classes
- Fixes to Merge, Mirror, Explode and GeomUtil tools. Closes #437, #438, #439, #440, #441
- Compiler warnings removed
- Background texture can deactivate mipmapping on creation. Closes #468
- View doesn't dispose of a shared stage3DProxy when has shareContext = true (#475)
- Fixes to DAE parser (#486 & #484)
- Fixed EnvMapMethod using mask. Closes #480
- Fixed shadows for large scene position values. Closes #412
- Various fixes: unpaired mouse over/mouse out events, ObjectContainer3D bounds, missing removeChildAt(), OBJ parser ignores zero-length geometries, check for zero length geometries in CompactSubGeometry, normalise normals & tangents after transform (#472)
- Added OcclusionMaterial
- Added getParticleNodeName() to ParticleNodeNBase (#488)
- Added ParticleInitialColorNode to allow different initial colors for each particle
- Added BitmapData & ATF option for ImageParser (#489, #526)
- Added spritesheet animation to the animators classes
- Optimised ShaderRegisterCache creation/reset (#477)
- Fix incorrect values from uproject() method on view and camera
- Fix SubGeometry faceWeights variable (incorrect uint cast). Closes #511 & #505
- Added fix for steps = 0 in HoverController. Closes #467
- Fixed viewport scaling and offset when using a shared context. Closes #329
- Added PerspectiveOffCenterLens
- Fix to convertToSeparateBuffers in CompactSubGometry. Closes #491
- Fixed FirstPersonController wrap issue on panAngle. Closes #506
- Fix for SingleFileLoader when getting file extensions for urls with query strings. Closes #463
- Fixed 3D mouse events when using OrthographicLens. Closes #469
- Fixed mouse picking with 2 views. Closes #483
- Fixed mouse click event to behave correctly for a mouse click. Closes #399
- Fixed incorrect aspect ratio on a view when using Filter3D API. Closes #501
- Fixed scene partition error for floating cameras. Closes #519
- Added constrained mode option
- Fix to SkyBox clipping when using extreme frustum values. Closes #481
- Fixed materials ignoring invalidation when new effects methods are assigned. Closes #476
- Fixed ShaderPicker memory leak when view is disposed. Closes #461
- Mipmaps explicitly disposed when calling dispose() on TextureMaterial. Closes #459 & #417
- Fix for mesh normals data when using PickingType.SHADER on view.mousePicker. Closes #537
- Fix for incorrect thickness value being get/set on Segment. Closes #392
- Fixed single frame glitch for ambient light on startup of a scene. Closes #410
- Fix to MeshHelper class for correctly handling CompactSubGeometry classes. Closes #444

4.1.0 (Alpha)
-------------
- Merged stereo rendering feature
- Merged particle animation feature
- Merged compact geometry feature
- Merged ATF texture feature
- Merged view volume partitions feature
- Merged multipass materials feature
- Merged realtime reflections feature
- Rebuilt tools package to work with new compact geometry feature
- Removed name arg in animation set interface method addAnimation, name to be set on asset.
- Renamed rootDelta property on AnimatorBase to positionDelta
- Deprecated TripleFilterShadowMethod in favour of SoftShadowMethod
- Added DXF parser
- Fix order of material vs animation code generation. Closes #405
- Increased max shadow map samples for DitheredShadowMapMethod
- Increased max shadow map samples for SoftShadowMethod
- Updated DirectionalLight's scene transform (and as a result the sceneDirection) if dirty when sceneDirection is queried. Closes #391
- Replaced Texture constants not available in older compilers with string literals for backward compatibility
- PlaneGeometry: Fix faulty and missing uv's when doubleSided is true.
- Changed composite shader methods to work by passing in a method rather than subclassing
- Moved responsibility for light picker updates to material passes
- Moved shader compilation classes into own package, extracted dependency counts into class

4.0.11
------
- Doublesided materials considered correctly in triangle picking
- Fixed incorrect mouse events from Sprite3D
- Introduced zOffset parameter on all scenegraph objects to allow manual sorting offsets
- Fixed incorrect picking event from firing when a bounds collision is detected from inside the bounds
- Fixed missing mouse down events when running on tablets
- Added ability to resize the viewport of a View3D object independent of Stage3DProxy when sharing a context
- Updated Adobe's AGALMiniAssembler to the latest from https://github.com/graphicscore/graphicscorelib
- Implemented getSceneCollision on RaycastPicker (#418)

4.0.10
------
- Fixed incorrect z values in project() and x/y/z values in unproject() methods of lensbase
- Fixed incorrect bounds normals returned by mouse event on an object with triangle picking enabled
- Fixed missing delta data on MouseEvent3D.MOUSE_WHEEL events

4.0.9
-----
- Fixed MD5 mesh bug (#364)

4.0.8
-----
- Fixed infinite recursion issue in SkeletonDifferenceNode
- Fix for Gold alpha blending regression

4.0.7
-----
- Fixed crash caused by null alpha mask in shadow depth rendering (#274)
- Fixed bounds calculation for flat geometries (#273)
- Fixed issue related to primitive validation (#257)
- Fixed device loss (#263, #269)
- Fixed issue with removing assets from library (#162)
- Fixed bug related to RTT dimensions (#279)
- Unified and improved sub-mesh splitting (better support for large meshes)
- Improved tool classes
- Optimized Object3D.updateTransform() (#232)
- Fixed crash issue in AIR (#230)
- Fixed lightPicker invalidation bug (#216)
- Fixed bug only appearing in software rendering (#234)
- Fixed issues in 3DS parser (#294, #291)
- Added NearShadowMapMethod
- Implemented support for nested objects in Drag3D (#283)
- Fixes to segment rendering and management
- Implemented visible property on View3D (#155)
- Enabled texture repeating in materials loaded from OBJ files (#5)
- Properly implemented and tested Sound3D (#227, #41)
- Fixed bug in MD5 parser caused by zero-weights (#65)
- Added alpha property for shadow map methods
- Added WebcamTexture
- Improved Stage3DProxy interface
- Added doubleSided property to PlaneGeometry
- Added backbuffer cap to avoid bug caused by too large backbuffers (#285)
- Fixed issue with small OBJ files (#304)
- Fixed wrap issue in HoverController (#299)
- Enabled integration of other Stage3D frameworks (e.g. Starling)
- Fixed Sprite3D clipping bug (#309)
- Lowered texture limit to 1x1 (#308)
- Fixed OBJParser issue related to specular shading (#70, #64)
- Fixed delegation issue in composit AWDParser (#315)
- Fixed issue with texture disposal (#316)
- Implemented Tim Knip's DAEParser
- Slightly refactored loading system internals, renamed some events
- Removed deprecated bitmap/video materials
- Refactored picking system
- Optimizations to scene graph and picking
- Fixed parsing of texture names from AWD2 files (#200)
- Fixed bug in OBJParser concerning escaped line-breaks (#330)
- Fixed pivot point issue (#333)
- Added path data classes
- Refactored animation system
- Refactored object controllers (328, #331)
- Fix MD2 render state for different passes (#340)
- Fixed normal/tangent issues in CylinderGeometry (#209)
- Added default materials for objects (#170)
- Added skeleton and forceCPU properties to SkeletonAnimator
- Fixed bug in UV generation for cube primitives
- Fixed bug in SkeletonAnimator playback with negative playbackSpeed
- Fixed bug in SegmentSet (#198)

4.0.6
-----
- Implemented geometry splitting in AWD2Parser (large meshes) (#136)
- Added support for alpha in video texture (#54)

4.0.5
-----
- Implemented changes related to finalized AWD 2.0 specification
- Improved LookAtController (#217)
- Fixed visual bug in AwayStats (#220)
- Added torus geometry primitive
- Optimized Fresnel specular method
- Added texture support in ambient method

4.0.4
-----
- Fixed issues with geometry validation in primitives

4.0.3
-----
- Added WireframeCylinder primitive
- Added View3D.queueSnapshot() to take screen shots of view

4.0.2
-----
- Fixed cone geometry normals

4.0.1
-----
- Fixes to object controllers
