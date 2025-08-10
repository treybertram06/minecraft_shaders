
uniform sampler2D gtexture;   // base color (sRGB)

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 outColor0;

// Varyings
in vec2 texCoord;
in vec3 foliageColor;

void main()
{
    vec4 tex = texture(gtexture, texCoord);
    vec3 albedo = tex.rgb * foliageColor;
    float alpha = tex.a;
    if (alpha < 0.1) discard;

    outColor0 = vec4(albedo, alpha);
}
