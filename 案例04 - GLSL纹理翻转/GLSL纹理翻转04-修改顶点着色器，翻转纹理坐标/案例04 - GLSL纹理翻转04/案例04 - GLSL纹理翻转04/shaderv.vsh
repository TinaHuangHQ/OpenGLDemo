attribute vec4 position;
attribute vec2 textCoordinate;
varying lowp vec2 varyTextCoord;
void main(){
    vec2 newCoord = vec2(textCoordinate.x, 1.0-textCoordinate.y);
    varyTextCoord = newCoord;
    gl_Position = position;
}
