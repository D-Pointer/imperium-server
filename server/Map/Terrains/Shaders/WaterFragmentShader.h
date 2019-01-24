"																		\n\
precision highp float;                                                  \n\
                                                                        \n\
varying vec2 v_texCoord;												\n\
uniform sampler2D CC_Texture0;                                          \n\
uniform float u_time;                                                   \n\
uniform vec2  u_offset;                                                 \n\
                                                                        \n\
void main(void) {                                                       \n\
    vec2 resolution = vec2(40, 40);                                     \n\
    vec2 cPos = -1.0 + 2.0 * gl_FragCoord.xy / resolution.xy;\n\
    float cLength = length(cPos);                                       \n\
    float timeScale = 2.0;                                              \n\
    vec2 uv = (gl_FragCoord.xy + u_offset) / resolution.xy + (cPos / cLength) * cos(cLength * 12.0 - u_time * timeScale) * 0.03; \n\
    vec3 col = texture2D(CC_Texture0, uv).xyz;                            \n\
                                                                        \n\
    gl_FragColor = vec4(col,1.0);                                       \n\
}                                                                       \n\
";
