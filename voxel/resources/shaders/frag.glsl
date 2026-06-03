#version 330 core

in vec3 vertex_position;
in vec2 vertex_uv;
in vec3 vertex_color;

out vec4 outColor;

uniform sampler2D atlas;

void main() {
     vec4 texCol = texture(atlas, vertex_uv);
     outColor = vec4(texCol.rgb * vertex_color, texCol.a);
}
