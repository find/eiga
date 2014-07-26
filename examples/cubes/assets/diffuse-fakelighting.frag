#version 120

uniform vec4 diffuse;
uniform mat4 view;

varying vec4 worldNormal;

void main()
{
    vec4 worldLight = vec4(-0.2, 0.4, 0.8, 0);
    gl_FragColor.rgb = clamp(0,dot(worldLight.xyz, worldNormal.xyz),1) * diffuse.xyz + vec3(0.1,0.1,0.1);
    gl_FragColor.a   = 1.0;
}

