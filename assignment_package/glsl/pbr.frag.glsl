#version 330 core

uniform vec3 u_CamPos;

// PBR material attributes
uniform vec3 u_Albedo;
uniform float u_Metallic;
uniform float u_Roughness;
uniform float u_AmbientOcclusion;
// Texture maps for controlling some of the attribs above, plus normal mapping
uniform sampler2D u_AlbedoMap;
uniform sampler2D u_MetallicMap;
uniform sampler2D u_RoughnessMap;
uniform sampler2D u_AOMap;
uniform sampler2D u_NormalMap;
// If true, use the textures listed above instead of the GUI slider values
uniform bool u_UseAlbedoMap;
uniform bool u_UseMetallicMap;
uniform bool u_UseRoughnessMap;
uniform bool u_UseAOMap;
uniform bool u_UseNormalMap;

// Image-based lighting
uniform samplerCube u_DiffuseIrradianceMap;
uniform samplerCube u_GlossyIrradianceMap;
uniform sampler2D u_BRDFLookupTexture;

// Varyings
in vec3 fs_Pos;
in vec3 fs_Nor; // Surface normal
in vec3 fs_Tan; // Surface tangent
in vec3 fs_Bit; // Surface bitangent
in vec2 fs_UV;
out vec4 out_Col;

const float PI = 3.14159f;

// Schlick's fresnel approximation accounting for roughness
vec3 fresnelRoughness(float cosViewAngle, vec3 R, float roughness)
{
    return R + (max(vec3(1.f - roughness), R) - R) * pow(max(1.f - cosViewAngle, 0.f), 5.f);
}

// Reinhard operator tone mapping
vec3 reinhard(vec3 in_Col)
{
    return in_Col / (vec3(1.f) + in_Col);
}

// Gamma correction
vec3 gammaCorrect(vec3 in_Col)
{
    return pow(in_Col, vec3(1.f / 2.2f));
}

// Set the input material attributes to texture-sampled values
// if the indicated booleans are TRUE
void handleMaterialMaps(inout vec3 albedo, inout float metallic,
                        inout float roughness, inout float ambientOcclusion,
                        inout vec3 normal) {
    if(u_UseAlbedoMap) {
        albedo = pow(texture(u_AlbedoMap, fs_UV).rgb, vec3(2.2));
    }
    if(u_UseMetallicMap) {
        metallic = texture(u_MetallicMap, fs_UV).r;
    }
    if(u_UseRoughnessMap) {
        roughness = texture(u_RoughnessMap, fs_UV).r;
    }
    if(u_UseAOMap) {
        ambientOcclusion = texture(u_AOMap, fs_UV).r;
    }
    if(u_UseNormalMap) {
        // Get the normal and map it to a [-1, 1] range
        normal = texture(u_NormalMap, fs_UV).rgb;
        normal = normalize(normal * 2.f - 1.f);
        // Tangent to world space
        normal = mat3(fs_Tan, fs_Bit, fs_Nor) * normal;
    }
}

void main()
{
    vec3  N                = fs_Nor;
    vec3  albedo           = u_Albedo;
    float metallic         = u_Metallic;
    float roughness        = u_Roughness;
    float ambientOcclusion = u_AmbientOcclusion;

    handleMaterialMaps(albedo, metallic, roughness, ambientOcclusion, N);

    vec3 wo = normalize(u_CamPos - fs_Pos);

    vec3 R = mix(vec3(0.04f), albedo, metallic);
    vec3 F = fresnelRoughness(max(dot(N, wo), 0.f), R, roughness);

    // Cook-Torrence weights
    vec3 ks = F;
    vec3 kd = 1.f - ks;
    kd *= 1.f - metallic;

    // Diffuse color
    vec3 diffuseIrradiance = texture(u_DiffuseIrradianceMap, N).rgb;
    vec3 diffuse = albedo * diffuseIrradiance;

    // Sample the glossy irradiance map
    vec3 wi = reflect(-wo, N);
    const float MAX_REFLECTION_LOD = 4.f;
    vec3 prefilteredColor = textureLod(u_GlossyIrradianceMap, wi, roughness * MAX_REFLECTION_LOD).rgb;

    // Specular color
    vec2 envBRDF = texture(u_BRDFLookupTexture, vec2(max(dot(N, wo), 0.f), roughness)).rg;
    vec3 specular = prefilteredColor * (F * envBRDF.x + envBRDF.y);

    // Ambient color
    vec3 ambient = vec3(0.03f * ambientOcclusion);

    // Cook-Torrence lighting
    vec3 Lo = ambient + kd * diffuse + specular;

    // Tone mapping
    Lo = reinhard(Lo);
    Lo = gammaCorrect(Lo);

    out_Col = vec4(Lo, 1.f);
}
