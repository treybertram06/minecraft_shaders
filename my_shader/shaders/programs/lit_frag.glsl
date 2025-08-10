#version 460

uniform sampler2D gtexture; 
uniform sampler2D lightmap;  
uniform sampler2D normals;    
uniform sampler2D specular;  
uniform sampler2D shadowcolor0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowtex0;

uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

uniform vec3 shadowLightPosition; 
uniform vec3 cameraPosition;   

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 outColor0;

// in from vertex shader
in vec2 texCoord;
in vec3 foliageColor;
in vec2 lightMapCoords;
in vec3 geoNormal;         
in vec3 viewSpacePosition; 
in vec4 tangent;          

#include "functions.glsl"

void main()
{
    // base color
    vec4 tex = texture(gtexture, texCoord);
    vec3 albedo = toLinear(tex.rgb) * toLinear(foliageColor);
    float alpha = tex.a;
    if (alpha < 0.1) discard;

    //lighting
    vec3 colorLin = lightingCalc(
        albedo,
        texCoord, lightMapCoords,
        geoNormal, viewSpacePosition, tangent,
        gtexture, lightmap, normals, specular,
        gbufferModelViewInverse, shadowLightPosition, cameraPosition,
        shadowcolor0, shadowProjection, shadowModelView
    );

    outColor0 = vec4(colorLin, alpha);
}
