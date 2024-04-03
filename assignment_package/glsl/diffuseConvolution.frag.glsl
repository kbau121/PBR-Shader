#version 330 core

// Compute the irradiance across the entire
// hemisphere aligned with a surface normal
// pointing in the direction of fs_Pos.
// Thus, our surface normal direction
// is normalize(fs_Pos).

in vec3 fs_Pos;
out vec4 out_Col;
uniform samplerCube u_EnvironmentMap;

const float PI = 3.14159265359;

void main()
{
    // The normal and orientation of the hemisphere
    // is simply the direction of the position
    vec3 normal = normalize(fs_Pos);

    // Average of all irradiance samples
    vec3 irradiance  = vec3(0.f);

    // Tangent space directions at the point
    vec3 up = vec3(0.f, 1.f, 0.f);
    vec3 right = normalize(cross(up, normal));
    up = normalize(cross(normal, right));

    // Sample around the hemisphere
    float sampleDelta = 0.025;
    float nrSamples = 0.0;
    for (float phi = 0.f; phi < 2.0 * PI; phi += sampleDelta)
    {
        for (float theta = 0.0; theta < 0.5 * PI; theta += sampleDelta)
        {
            // Spherical to cartesian
            vec3 tangentSample = vec3(sin(theta) * cos(phi), sin(theta) * sin(phi), cos(theta));
            // Tangent to world space
            vec3 sampleVec = tangentSample.x * right + tangentSample.y * up + tangentSample.z * normal;

            // Sample the environment map
            irradiance += texture(u_EnvironmentMap, sampleVec).rgb * cos(theta) * sin(theta);
            nrSamples++;
        }
    }
    // Average the samples
    irradiance = PI * irradiance * (1.f / nrSamples);

    out_Col = vec4(irradiance, 1.f);
}
