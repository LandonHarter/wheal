#version 330 core

layout(location = 0) in vec3 vertexPosition;
layout(location = 1) in vec2 vertexTextureCoordinate;

out vec2 vertex_textureCoord;

uniform mat4 model;
uniform mat4 projection;

void main() {
    vertex_textureCoord = vertexTextureCoordinate;
    gl_Position = projection * model * vec4(vertexPosition, 1.0f);
}
