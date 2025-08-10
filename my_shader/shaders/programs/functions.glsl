
vec3 toLinear(vec3 c) { return pow(c, vec3(2.2)); }
vec3 toSRGB  (vec3 c) { return pow(c, vec3(1.0 / 2.2)); }

vec3 brdf_ggx(vec3 N, vec3 V, vec3 L, vec3 albedo, float roughness, float metallic, vec3 F0)
{
    vec3 H = normalize(V + L);

    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    float NdotH = max(dot(N, H), 0.0);
    float VdotH = max(dot(V, H), 0.0);

    float a  = max(roughness * roughness, 1e-4);
    float a2 = a * a;

    float denom = (NdotH * NdotH) * (a2 - 1.0) + 1.0;
    float D = a2 / (3.141592653589793 * denom * denom);

    float k = (roughness + 1.0);
    k = (k * k) / 8.0;
    float Gv = NdotV / (NdotV * (1.0 - k) + k);
    float Gl = NdotL / (NdotL * (1.0 - k) + k);
    float G  = Gv * Gl;

    vec3 F = F0 + (1.0 - F0) * pow(1.0 - VdotH, 5.0);

    vec3 kD = (1.0 - F) * (1.0 - metallic);
    vec3 diffuse = kD * albedo / 3.141592653589793;

    vec3 spec = (D * G) * F / max(4.0 * NdotV * NdotL, 1e-4);

    return (diffuse + spec) * NdotL;
}

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position) {
    vec4 homogeneousPosition = projectionMatrix * vec4(position, 1.0);
    return homogeneousPosition.xyz / homogeneousPosition.w;
}

vec3 lightingCalc(
    vec3 albedo,
    vec2 texCoord, vec2 lightMapCoords,
    vec3 geoNormal, vec3 viewSpacePosition, vec4 tangent,
    sampler2D gtexture, sampler2D lightmap, sampler2D normals, sampler2D specular,
    mat4 gbufferModelViewInverse, vec3 shadowLightPosition, vec3 cameraPosition, sampler2D shadowcolor0,
    mat4 shadowProjection, mat4 shadowModelView)
{
    // TBN (world space)
    mat3 invMV3 = mat3(gbufferModelViewInverse);
    vec3 N = normalize(invMV3 * geoNormal);
    vec3 T = normalize(invMV3 * tangent.xyz);
    T = normalize(T - N * dot(T, N));
    vec3 B = cross(N, T) * (tangent.w < 0.0 ? -1.0 : 1.0);
    mat3 TBN = mat3(T, B, N);

    // Normal decode (TS → world)
    vec2 enc = texture(normals, texCoord).xy * 2.0 - 1.0;
    // enc.y *= -1.0; // flip if needed
    vec3 nTS = normalize(vec3(enc, sqrt(max(0.0, 1.0 - dot(enc, enc)))));
    vec3 nWorld = normalize(TBN * nTS);

    // Directions (world space)
    vec3 L = normalize(invMV3 * shadowLightPosition);
    vec3 fragWorldPos = (gbufferModelViewInverse * vec4(viewSpacePosition, 1.0)).xyz + cameraPosition;
    vec3 V = normalize(cameraPosition - fragWorldPos);

    // Material params (R: smoothness, G: spec/metal)
    vec4 specData = texture(specular, texCoord);
    float perceptualSmoothness = specData.r;
    float roughness = pow(1.0 - perceptualSmoothness, 2.0);
    float metallic = 0.0;
    vec3  F0 = vec3(0.04);
    if (specData.g * 255.0 > 229.0) { metallic = 1.0; F0 = albedo; }
    else { F0 = vec3(max(specData.g, 0.04)); }

    // Space Conversions
    vec3 worldGeoNormal = normalize(invMV3 * geoNormal);
    vec3 adjustedFragFeetPlayerSpace = (fragWorldPos - cameraPosition) + (0.03 * worldGeoNormal);
    vec3 fragShadowViewSpace = (shadowModelView * vec4(adjustedFragFeetPlayerSpace, 1.0)).xyz;
    vec3 fragShadowNdcSpace = projectAndDivide(shadowProjection, fragShadowViewSpace);
    float distanceFromPlayerShadowNdcSpace = length(fragShadowNdcSpace.xy);
    vec3 distortedShadowNdcSpace = vec3(fragShadowNdcSpace.xy / (0.1 + distanceFromPlayerShadowNdcSpace), fragShadowNdcSpace.z);
    vec3 fragShadowScreenSpace = distortedShadowNdcSpace * 0.5 + 0.5;

    // Shadow
    float isInShadow = step(fragShadowScreenSpace.z - 0.001, texture(shadowtex0, fragShadowScreenSpace.xy).r);
    float isInNonColoredShadow = step(fragShadowScreenSpace.z - 0.001, texture(shadowtex1, fragShadowScreenSpace.xy).r);
    vec3 shadowColor = texture(shadowcolor0, fragShadowScreenSpace.xy).rgb;

    vec3 shadowMultiplier = vec3(1.0);

    if (isInShadow == 0.0) {
        if (isInNonColoredShadow == 0.0) {
            shadowMultiplier = vec3(0.0); // Non-colored shadow
        } else {
            shadowMultiplier = shadowColor; // Colored shadow
        }
    } else {
        shadowMultiplier = vec3(1.0); // No shadow
    }

    // Lightmap & output
    vec3 blockLight = toLinear(texture(lightmap, vec2(lightMapCoords.x, 1.0 / 32.0)).rgb);
    vec3 skyLight   = toLinear(texture(lightmap, vec2(1.0 / 32.0, lightMapCoords.y)).rgb);

    // Lighting
    vec3 ambientLightDirection = worldGeoNormal;
    vec3 ambient = (blockLight + 0.2 * skyLight) * clamp(dot(nWorld, ambientLightDirection), 0.0, 1.0) * albedo;
    vec3 direct  = skyLight * shadowMultiplier * brdf_ggx(nWorld, V, L, albedo, roughness, metallic, F0);

    //output color
    vec3 outputColor = ambient + direct;

    return toSRGB(outputColor);
}