# An Intelligent Beginner's Guide to WebGL

When an object is rendered in WebGL, you see *faces*. Faces are triangles and
so they have three vertices. The most basic 3D object is therefore a pyramid.
However, I'm going to draw a cube because it shows how to build up a side with
multiple faces.

### The Cube

Many tutorials start by showing the most basic way to draw an object using only
the vertices. Then they later apply a texture. At the end they show you the
most performant way of doing things. I'm going to jump right into the best way
because it's not that difficult!

I'll use `gl.drawArrays` which supports *interleaved vertex data*. The data
needs vertex coordinates, the *normal* vector, and the texture coordinates.
(The normal is used to determine if a face is facing the camera, which is
important when turning on *back face culling*.) The array itself is flat and
you'll see when we draw it that I'm able to define the specification of the
array in JavaScript but that it's also tied to the shader code. Each vertex
will use eight elements: three for the vertex position, three for the normal
vector of the face created by the vertices, and two for the texture coordinates
(a 2D image).

A cube has eight vertices so the data array for it will have 64 elements. I've
numbered them in this way because of what's referred to as *winding order*. All
the tutorials I read used a counter clockwise winding order (`gl.CCW`) so I've
done the same. I chose the placement of the first vertex because it was easier
for me to visualize. The placement of vertex 5 is the same as 1 if you
visualize going around to the other side (which is how I visualize it).

       5--------6
      /|       /|
     / |      / |
    2--------1  |
    |  |     |  |
    |  8-----|--7
    | /      | /
    |/       |/
    3--------4

I'll initially build the data as a multidimensional array and later flatten it.
Here are the vertices with the center of the cube at the origin.

###### Define Cube Vertices
    let vertex_1 = [1, 1, 1];
    let vertex_2 = [-1, 1, 1];
    let vertex_3 = [-1, -1, 1];
    let vertex_4 = [1, -1, 1];
    let vertex_5 = [-1, 1, -1];
    let vertex_6 = [1, 1, -1];
    let vertex_7 = [1, -1, -1];
    let vertex_8 = [-1, -1, -1];

Each vertex has a normal, but each side of the cube has the same normal. Here
are the normals for the front, back, left, right, top, and down. They are
vectors from the origin.

###### Define Cube Normals
    let normal_front = [0, 0, 1];
    let normal_back = [0, 0, -1];
    let normal_left = [-1, 0, 0];
    let normal_right = [1, 0, 0];
    let normal_top = [0, 1, 0];
    let normal_down = [0, -1, 0];

Each face will have the same texture coordinates because I will just be placing
the image directly on it. If you were to use a sprite that wrapped around
geometry it would be much more complicated. It's a 2D image with the origin at
the top left.  I'll define top left, top right, bottom left, and bottom right.

###### Define Cube Texture
    let texture_tl = [0, 0];
    let texture_tr = [1, 0];
    let texture_bl = [0, 1];
    let texture_br = [1, 1];

Now I can interleave this data and define each side. Each vertex is a part of
three different sides -- each use requires a different normal vector and
texture coordinates. Note that `[].concat.apply([], [...])` is used to flatten
the array.

###### Define cube_geometry
    <<Define Cube Vertices>>
    <<Define Cube Normals>>
    <<Define Cube Texture>>
    let cube_geometry = [].concat.apply([], [
        // Front
        vertex_1, normal_front, texture_tr,
        vertex_2, normal_front, texture_tl,
        vertex_3, normal_front, texture_bl,
        vertex_4, normal_front, texture_br,

        // Back
        vertex_5, normal_back, texture_tr,
        vertex_6, normal_back, texture_tl,
        vertex_7, normal_back, texture_bl,
        vertex_8, normal_back, texture_br,

        // Left
        vertex_2, normal_left, texture_tr,
        vertex_5, normal_left, texture_tl,
        vertex_8, normal_left, texture_bl,
        vertex_3, normal_left, texture_br,

        // Right
        vertex_6, normal_right, texture_tr,
        vertex_1, normal_right, texture_tl,
        vertex_4, normal_right, texture_bl,
        vertex_7, normal_right, texture_br,

        // Top
        vertex_6, normal_top, texture_tr,
        vertex_5, normal_top, texture_tl,
        vertex_2, normal_top, texture_bl,
        vertex_1, normal_top, texture_br,

        // Bottom
        vertex_8, normal_bottom, texture_tr,
        vertex_7, normal_bottom, texture_tl,
        vertex_4, normal_bottom, texture_bl,
        vertex_3, normal_bottom, texture_br,
    ]);

Objects are built of triangular faces and I need to tell WebGL how to draw
them. Each row in the cube geometry above has an index 0 to 23. I need to make
triangles from each side.

###### Define cube_faces
    let cube_faces = [
        // Front
        0, 1, 2,
        0, 2, 3,
        // Back
        4, 5, 6,
        4, 6, 7,
        // Left
        8, 9, 10,
        8, 10, 11,
        // Right
        12, 13, 14,
        12, 14, 15,
        // Top
        16, 17, 18,
        16, 18, 19,
        // Bottom
        20, 21, 22,
        20, 22, 23
    ];

### Shaders

To render my cube I need both a *vertex shader* and a *fragment shader*.

When I was studying 3D animation, we were often shown beautiful, artistic work
done with shaders. Shaders are programs, though, so we never did anything like
that. 🙂 I will therefore use the bare minimum that I cobbled together from
various tutorials.  This is a subject unto itself, so I can't explain much of
it because I don't know anything about it.

The shaders are at two different points in the render pipeline. JavaScript can
hook into them via their *attribute* and *uniform* variables. They can
communicate with each other through their *varying* variables.

    Your code
      |
      v
    attribute(s) and/or uniform(s) ------------------.
                    |                                |
                    v                                v
    (stuff?) ->  vertex shader  -> varying(s) ->  fragment shader  -> (more stuff?)


###### Define vertex_shader_text and fragment_shader_text
    let vertex_shader_text = `
        attribute highp vec3 aVertexNormal;
        attribute highp vec3 aVertexPosition;
        attribute highp vec2 aTextureCoord;

        uniform highp mat4 uNormalMatrix;
        uniform highp mat4 uMVMatrix;
        uniform highp mat4 uPMatrix;

        varying mediump vec2 vTextureCoord;
        varying mediump vec3 vLighting;

        void main(void) {
            gl_Position = uPMatrix * uMVMatrix * vec4(aVertexPosition, 1.0);
            vTextureCoord = aTextureCoord;

            highp vec3 ambientLight = vec3(0.1, 0.1, 0.1);
            highp vec3 directionalLightColor = vec3(0.5, 0.5, 0.75);
            highp vec3 directionalVector = vec3(0.85, 0.8, 0.75);

            highp vec4 transformedNormal =
                uNormalMatrix * vec4(aVertexNormal, 1.0);

            highp float directional = max(dot(transformedNormal.xyz,
                                              directionalVector),
                                          0.0);
            vLighting = ambientLight + (
                directionalLightColor * directional);
        }
    `;

    let fragment_shader_text = `
        varying mediump vec2 vTextureCoord;
        varying mediump vec3 vLighting;

        uniform sampler2D uSampler;

        void main(void) {
            mediump vec4 texelColor = 
                texture2D(uSampler, vec2(vTextureCoord.s, vTextureCoord.t));
            gl_FragColor = vec4(texelColor.rgb * vLighting, texelColor.a);
        }
    `;

The shaders use a language called [OpenGL ES](https://en.wikipedia.org/wiki/OpenGL_ES).





I made a small image that is grey with a red stripe on the top and a green
stripe on the bottom. It's a small gif so I'm able to embed it in the code.

###### Define Image Data
    let image_data = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAAH0lEQVR42mOYk57xHx9mWLFixX98eGgoyJ+X/h8fBgAz27U50NAuZgAAAABJRU5ErkJggg==';





###### WebGL Program
    console.log("Get ready to WebGL!");



# Compiling and Serving

After creating the following files, I'll be able to set up an auto-compiling,
auto-reloading web server that is running this WebGL program.

I wrote a literate programming tool called
[Knot](https://github.com/mqsoh/knot). It's distributed as a Docker image. It
can automatically compile this README into source code. I like to use Docker
Compose to do it.

###### file:docker-compose.yml
    knot:
      image: mqsoh/knot
      volumes:
        - .:/workdir
      command: watch README.md development.md

I'm going to serve this up with Brunch so I need to create a Docker image for
it.

###### file:Dockerfile
    FROM node:6

    RUN npm install -g brunch

    WORKDIR /workdir
    EXPOSE 3333
    EXPOSE 9485

    CMD ["brunch", "watch", "--server"]

I'll also use Docker Compose to serve the files.

###### file:docker-compose.yml
    brunch:
      build: .
      volumes:
        - .:/workdir
      ports:
        - "3333:3333"
        - "9485:9485"

If you look at [the development setup](./development.md), you'll see that I
need to provide a function called `my_code`. Since Brunch automatically
concatenates all JavaScript files into the `app.js`, I'll just dump this into a
file called `app/my_code.js`.

###### file:app/my_code.js
    exports.run = function run() {
        <<WebGL Program>>
    }



[Brunch]: http://brunch.io/
