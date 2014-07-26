#version 120

attribute vec4 position;
attribute vec3 normal;
attribute vec3 worldpos;

uniform mat4 view,proj;

varying vec4 worldNormal;

void main() {
    worldNormal = vec4(normal, 0);
    gl_Position = (position + vec4(worldpos,0)) * view * proj;
}
