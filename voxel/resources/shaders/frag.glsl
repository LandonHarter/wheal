#version 330 core

in vec3 vertex_position;
in vec2 vertex_uv;

out vec4 outColor;

uniform sampler2D atlas;

void main() {
    outColor = texture(atlas, vertex_uv);
}
