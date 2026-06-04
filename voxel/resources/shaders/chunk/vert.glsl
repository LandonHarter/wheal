#version 330 core

layout(location = 0) in vec3 vertexPosition;
layout(location = 1) in vec2 vertexUv;
layout(location = 2) in vec3 vertexColor;

out vec3 vertex_position;
out vec2 vertex_uv;
out vec3 vertex_color;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main() {
    vertex_position = (model * vec4(vertexPosition, 1.0f)).xyz;
    vertex_uv = vertexUv;
    vertex_color = vertexColor;
    gl_Position = projection * view * model * vec4(vertexPosition, 1.0f);
}

