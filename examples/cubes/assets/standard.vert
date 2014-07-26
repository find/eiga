#version 120

attribute vec4 position;
attribute vec3 normal;

uniform mat4 world,view,proj;

varying vec4 worldNormal;

void main() {
    worldNormal = vec4(normal, 0) * world;
    gl_Position = position * world * view * proj;
}
