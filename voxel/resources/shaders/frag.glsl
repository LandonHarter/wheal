#version 330 core

in vec3 vertex_position;

out vec4 outColor;

void main() {
    outColor = vec4(vertex_position + 0.5, 1.0);
}
