precision highp float;
uniform sampler2D Texture;
varying vec2 TextureCoordsVarying;
uniform float Time;

void main (void) {
    float duration = 1.0;
    float process = mod(Time, duration)/duration;
    
    float maxAlpha = 0.4;
    float alpha = maxAlpha * (1.0 - process);
    
    float maxScale = 0.8;
    float scale = 1.0 + maxScale * process;
    
    float weakX = 0.5 + (TextureCoordsVarying.x - 0.5)/scale;
    float weakY = 0.5 + (TextureCoordsVarying.y - 0.5)/scale;
    vec2 weakTextureCoords = vec2(weakX, weakY);
    
    vec4 weakMask = texture2D(Texture, weakTextureCoords);
    vec4 mask = texture2D(Texture, TextureCoordsVarying);
    gl_FragColor = weakMask * alpha + mask * (1.0 - alpha);
}
