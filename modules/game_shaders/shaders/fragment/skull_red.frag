varying vec2 v_TexCoord;
uniform vec4 u_Color;
uniform sampler2D u_Tex0;

void main()
{
    vec4 texColor = texture2D(u_Tex0, v_TexCoord);
    float lum = dot(texColor.rgb, vec3(0.299, 0.587, 0.114));
    // Keep SD silhouette/detail, shift it to a strong red.
    vec3 tint = vec3(1.0, 0.12, 0.12);
    gl_FragColor = vec4(lum * tint * 1.35, texColor.a) * u_Color;
    if (gl_FragColor.a < 0.01)
        discard;
}
