// res://shaders/cbl_shader.shader

// Tell Godot this is a 2D canvas (UI+world) shader
shader_type canvas_item;

// In Godot 4 you must explicitly declare the screen sampler
// This gives us access to the already-rendered screen (3D world + UI)
uniform sampler2D SCREEN_TEXTURE;

// A simple integer you drive from GDScript to choose the mode:
// 0 = Off, 1 = Protanopia, 2 = Deuteranopia, 3 = Tritanopia
uniform int mode = 0;

// Precomputed 3×3 color transformation matrices for each deficiency.
// Godot’s mat3 constructor takes three vec3 columns.
//   [ R_out ]   [ m00 m01 m02 ] [ R_in ]
//   [ G_out ] = [ m10 m11 m12 ] [ G_in ]
//   [ B_out ]   [ m20 m21 m22 ] [ B_in ]

// Protanopia (red-weak) matrix:
const mat3 protanopia = mat3(
    vec3(0.567, 0.558, 0.0),   // column 0: {m00, m10, m20}
    vec3(0.433, 0.442, 0.242), // column 1: {m01, m11, m21}
    vec3(0.0,   0.0,   0.758)  // column 2: {m02, m12, m22}
);

// Deuteranopia (green-weak) matrix:
const mat3 deuteranopia = mat3(
    vec3(0.625, 0.700, 0.0),
    vec3(0.375, 0.300, 0.300),
    vec3(0.0,   0.0,   0.700)
);

// Tritanopia (blue-weak) matrix:
const mat3 tritanopia = mat3(
    vec3(0.950, 0.0,   0.0),
    vec3(0.050, 0.433, 0.475),
    vec3(0.0,   0.567, 0.525)
);

// The fragment() function runs for every pixel on-screen.
void fragment() {
    // Sample the already-rendered content at this UV.
    // SCREEN_UV is provided automatically by Godot for canvas shaders.
    vec4 src = texture(SCREEN_TEXTURE, SCREEN_UV);

    // Depending on the selected mode, multiply the RGB by the appropriate matrix.
    if (mode == 1) {
        // Apply protanopia correction
        src.rgb = protanopia * src.rgb;
    } else if (mode == 2) {
        // Apply deuteranopia correction
        src.rgb = deuteranopia * src.rgb;
    } else if (mode == 3) {
        // Apply tritanopia correction
        src.rgb = tritanopia * src.rgb;
    }
    // mode == 0: do nothing, leave src.rgb as-is

    // Output the final color (with alpha preserved)
    COLOR = src;
}
