attribute vec4 position;
attribute vec2 textCoordinate;
varying lowp vec2 varyTextCoord;
uniform mat4 rotateMatrix;
void main(){
    varyTextCoord = textCoordinate;
    vec4 newPosition = position;
    newPosition = newPosition*rotateMatrix;
    gl_Position = newPosition;
}
