#version 330 core

layout(location = 0) in vec3 vertexPosition;
layout(location = 1) in vec2 vertexUv;

out vec3 vertex_position;
out vec2 vertex_uv;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main() {
    vertex_position = (model * vec4(vertexPosition, 1.0f)).xyz;
    vertex_uv = vertexUv;
    gl_Position = projection * view * model * vec4(vertexPosition, 1.0f);
}

