
attribute vec4 Position;
attribute vec2 TextureCoords;
varying vec2 TextureCoordsVarying;

uniform float Time;

void main (void) {
    gl_Position = Position;
    TextureCoordsVarying = TextureCoords;
}
