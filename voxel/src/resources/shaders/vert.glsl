#version 330 core

layout(location = 0) in vec3 vertexPosition;

out vec3 vertex_position;

uniform mat4 model;

void main() {
    // vertex_position = (model * vec4(vertexPosition, 1.0f)).xyz;
    // gl_Position = model * vec4(vertexPosition, 1.0f);
    gl_Position = vec4(vertexPosition, 1.0f);
}

