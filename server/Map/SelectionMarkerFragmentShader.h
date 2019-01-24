"																		\n\
precision mediump float;                                                \n\
\n\
uniform float u_time;                                                   \n\
uniform vec4 u_color1;                                                   \n\
uniform vec4 u_color2;                                                   \n\
varying vec4 v_fragmentColor;						\n\
\n\
void main(void) {                                                       \n\
\n\
    //gl_FragColor = vec4( v_fragmentColor.rgb, u_time );                 \n\
    gl_FragColor = mix( u_color1, u_color2, u_time );                 \n\
}                                                                       \n\
";
