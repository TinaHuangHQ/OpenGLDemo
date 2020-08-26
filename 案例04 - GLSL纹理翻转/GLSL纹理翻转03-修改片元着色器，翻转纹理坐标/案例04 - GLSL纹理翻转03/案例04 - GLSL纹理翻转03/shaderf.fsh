precision highp float;
varying lowp vec2 varyTextCoord;
uniform sampler2D colorMap;
void main(){
    vec2 newCoord = vec2(varyTextCoord.x, 1.0-varyTextCoord.y);
    gl_FragColor = texture2D(colorMap, newCoord);
}
