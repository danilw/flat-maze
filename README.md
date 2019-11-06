# e-ani

**what is it** game-demo to [particle collision logic](https://github.com/danilw/godot-utils-and-other/tree/master/particle_self_collision/mini_example) that use more complex collision rules.

**Building:**

To make it work you need rebuild(recompile) godot with adding GL_RGBA32F support, edit source code files (lines base on godot-3.1.1-stable source version)

1. file `drivers/gles3/rasterizer_storage_gles3.cpp` line 6856
```
else from this if (rt->flags[RENDER_TARGET_NO_3D_EFFECTS] && !rt->flags[RENDER_TARGET_TRANSPARENT])....
```

**change to this** (replacing GL_RGBA16F etc)
```
else {
		color_internal_format = GL_RGBA32F;
		color_format = GL_RGBA;
		color_type = GL_FLOAT;
		image_format = Image::FORMAT_RGBAF;
	}
```
2. file `drivers/gles3/shaders/canvas.glsl`
**everything(lowp and meduim) to highp**

Full game logic on GPU. More info about gameplay on itch.io links below     

### Graphic from opengameart.org, [list of all used assets](https://github.com/danilw/flat-maze/blob/master/SOURCE_OF_GRAPHIC.md)

**Web version(live):** [danilw.itch.io/flat-maze-web](https://danilw.itch.io/flat-maze-web)

**Playable version(binary):** [danilw.itch.io/flat-maze](https://danilw.itch.io/flat-maze)


### Contact: [**Join discord server**](https://discord.gg/JKyqWgt)

### Video:

[![flat_maze](https://danilw.github.io/godot-utils-and-other/flat_maze_yt.png)](https://youtu.be/HawWnuMn1mc)
