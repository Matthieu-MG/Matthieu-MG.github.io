#version 300 es

layout (location = 0) in vec2 aVertexPosition;
layout (location = 1) in vec2 aUV;

out vec2 UV;

void main() {
    gl_Position = vec4(aVertexPosition, 0.0, 1.0);
    UV = aUV;
}