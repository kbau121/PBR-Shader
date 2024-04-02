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
    // TODO
    out_Col = vec4(1.0);
}
