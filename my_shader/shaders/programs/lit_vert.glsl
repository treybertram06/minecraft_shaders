#version 460

// attributes
in vec2 vaUV0;
in uvec2 vaUV2;
in vec3 vaPosition;
in vec3 vaNormal;
in vec4 at_tangent;
in vec4 vaColor;

uniform vec3 chunkOffset;
uniform vec3 cameraPosition;
uniform mat3 normalMatrix;
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform mat4 gbufferModelViewInverse;

// vertex to fragment outputs
out vec2 texCoord;
out vec2 lightMapCoords;
out vec3 foliageColor;
out vec3 geoNormal;
out vec3 viewSpacePosition;
out vec4 tangent;


void main() {

    tangent = vec4(normalize(normalMatrix * at_tangent.rgb), at_tangent.a);

    geoNormal = normalMatrix * vaNormal;
    texCoord = vaUV0;
    foliageColor = vaColor.rgb;
    lightMapCoords = vec2(vaUV2) * (1.0 / 256.0) + (1.0 / 32.0);

    vec4 viewSpacePositionVec4 = modelViewMatrix * vec4(vaPosition + chunkOffset, 1.0);
    viewSpacePosition = viewSpacePositionVec4.xyz;
    
    //gl_Position = projectionMatrix * modelViewMatrix * vec4(chunkOffset + vaPosition - (0.05 * distanceFromCamera), 1.0);
    gl_Position = projectionMatrix * viewSpacePositionVec4;
}