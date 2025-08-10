#version 460

// attributes
in vec2 vaUV0;
in vec3 vaPosition;
in vec4 vaColor;

uniform vec3 chunkOffset;
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;

// vertex to fragment outputs
out vec2 texCoord;
out vec3 foliageColor;

void main() {


    texCoord = vaUV0;
    foliageColor = vaColor.rgb;

    vec4 viewSpacePositionVec4 = modelViewMatrix * vec4(vaPosition + chunkOffset, 1.0);
    
    //gl_Position = projectionMatrix * modelViewMatrix * vec4(chunkOffset + vaPosition - (0.05 * distanceFromCamera), 1.0);
    gl_Position = projectionMatrix * viewSpacePositionVec4;
}