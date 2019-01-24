"																		\n\
precision highp float;                                                \n\
                                                                        \n\
varying vec2      v_texCoord;											\n\
\n\
uniform sampler2D u_terrain;                                            \n\
uniform sampler2D u_normalMap;                                          \n\
uniform float     u_mapWidth;                                   \n\
uniform float     u_mapHeight;                                   \n\
uniform vec2      u_offset;                                                 \n\
\n\
//const   vec3      lightDir = vec3( 0, 0, 1 );\n\
const   vec3      lightDir = normalize( vec3( -1, 1, 1 ) );\n\
\n\
void main(void) {                                                       \n\
    // a [0..1] coord for the current fragment corresponding to the relative 0..width, 0..height \n\
vec2 normalMapCoord = vec2( (u_offset.x + gl_FragCoord.x ) / u_mapWidth,  (u_mapHeight - (u_offset.y + gl_FragCoord.y) ) / u_mapHeight );   \n\
vec3 normal = texture2D( u_normalMap, normalMapCoord ).xyz; \n\
normal = normalize( normal * 2.0 - 1.0 ); \n\
float angle = clamp( dot( normal, lightDir ), 0.0, 1.0 ); \n\
\n\
\n\
     // base terrain texture\n\
  vec3 terrain = texture2D( u_terrain, v_texCoord ).xyz;   \n\
\n\
//vec3 color = max( dot( normal, lightDir ), 0.0);  \n\
    // modify the base texture with the height\n\
//gl_FragColor = vec4( normal, 1.0 );   \n\
//gl_FragColor = vec4( angle, angle, angle, 1.0 );   \n\
gl_FragColor = vec4( terrain * angle, 1);   \n\
//gl_FragColor = vec4( terrain * color, 1);   \n\
}                                                                       \n\
";
