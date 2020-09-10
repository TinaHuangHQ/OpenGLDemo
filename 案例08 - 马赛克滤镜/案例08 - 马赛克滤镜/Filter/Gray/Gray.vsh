attribute vec4 Position;
attribute vec2 TextureCoords;
varying vec2 TextureCoordsVarying;

void main (void) {
    TextureCoordsVarying = TextureCoords;
    gl_Position = Position;
}
