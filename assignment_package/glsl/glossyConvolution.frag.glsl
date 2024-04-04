#version 330 core

// Compute the irradiance within the glossy
// BRDF lobe aligned with a hard-coded wi
// that will equal our surface normal direction.
// Our surface normal direction is normalize(fs_Pos).

in vec3 fs_Pos;
out vec4 out_Col;
uniform samplerCube u_EnvironmentMap;
uniform float u_Roughness;

const float PI = 3.14159265359;

float RadicalInverse_VdC(uint bits)
{
    bits = (bits << 16u) | (bits >> 16u);
    bits = ((bits & 0x55555555u) << 1u) | ((bits & 0xAAAAAAAAu) >> 1u);
    bits = ((bits & 0x33333333u) << 2u) | ((bits & 0xCCCCCCCCu) >> 2u);
    bits = ((bits & 0x0F0F0F0Fu) << 4u) | ((bits & 0xF0F0F0F0u) >> 4u);
    bits = ((bits & 0x00FF00FFu) << 8u) | ((bits & 0xFF00FF00u) >> 8u);
    return float(bits) * 2.3283064365386963e-10;
}

vec2 Hammersley(uint i, uint N)
{
    return vec2(float(i) / float(N), RadicalInverse_VdC(i));
}

vec3 ImportanceSampleGGX(vec2 xi, vec3 N, float roughness)
{
    float alpha = roughness * roughness;

    float phi = 2.f * PI * xi.x;
    float cosTheta = sqrt((1.f - xi.y) / (1.f + (alpha * alpha - 1.f) * xi.y));
    float sinTheta = sqrt(1.f - cosTheta * cosTheta);

    // Spherical to Cartesian
    vec3 wi = vec3(cos(phi) * sinTheta, sin(phi) * sinTheta, cosTheta);

    // Tangent to world space
    vec3 up = abs(N.z) < 0.999f ? vec3(0.f, 0.f, 1.f) : vec3(1.f, 0.f, 0.f);
    vec3 tangent = normalize(cross(up, N));
    vec3 bitangent = cross(N, tangent);

    vec3 wh = tangent * wi.x + bitangent * wi.y + N * wi.z;


    return normalize(wh);
}

void main() {
    float roughness = u_Roughness;

    vec3 N = normalize(fs_Pos);
    vec3 wi = N;

    // Sample and weight samples over the environment map
    const uint SAMPLE_COUNT = 1024u;
    float totalWeight = 0.f;
    vec3 prefilteredColor = vec3(0.f);
    for (uint i = 0u; i < SAMPLE_COUNT; ++i)
    {
        vec2 xi = Hammersley(i, SAMPLE_COUNT);
        vec3 wh = ImportanceSampleGGX(xi, N, roughness);
        vec3 wo = normalize(2.f * dot(wi, wh) * wh - wi);

        float NdotWo = max(dot(N, wo), 0.f);
        if (NdotWo > 0.f) {
            prefilteredColor += texture(u_EnvironmentMap, wo).rgb * NdotWo;
            totalWeight += NdotWo;
        }
    }
    prefilteredColor /= totalWeight;

    out_Col = vec4(prefilteredColor, 1.f);
}
