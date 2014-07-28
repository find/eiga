#version 120

attribute vec4 position;
attribute vec3 normal;
attribute mat4 world;

uniform mat4 view,proj;

varying vec4 worldNormal;

void main() {
    worldNormal = vec4(normal, 0) * world;
    // gl_Position = (position + vec4(world[3].xyz, 0)) * view * proj;
    gl_Position = position * world * view * proj;
}
