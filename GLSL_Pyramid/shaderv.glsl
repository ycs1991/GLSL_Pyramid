attribute vec4 position;
attribute vec4 positionColor;

attribute vec2 textCoordinate;

uniform mat4 projectionMatrix;
uniform mat4 modelViewMatrix;

varying lowp vec4 varyColor;
varying lowp vec2 varyTextCoord;

void main() {
    varyColor = positionColor;

    varyTextCoord = textCoordinate;

    vec4 vPos;

    //投影矩阵 * 模型视图矩阵 * 顶点矩阵 4*4 * 4*4 * 4*1
    vPos = projectionMatrix * modelViewMatrix * position;

    gl_Position = vPos;
}
