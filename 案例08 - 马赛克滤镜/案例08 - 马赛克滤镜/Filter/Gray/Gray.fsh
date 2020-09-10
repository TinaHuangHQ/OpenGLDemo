precision highp float;
uniform sampler2D Texture;
varying vec2 TextureCoordsVarying;

void main (void) {
    vec4 mask = texture2D(Texture, TextureCoordsVarying);
    vec3 result = mix(mask.rgb, vec3(0,1,0), 0.4);
    
    gl_FragColor = vec4(result, 1);
}
