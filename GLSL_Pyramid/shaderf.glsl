precision highp float;
varying lowp vec4 varyColor;
varying lowp vec2 varyTextCoord;
uniform sampler2D colorMap;

void main() {
    //(1)
    //gl_FragColor = varyColor;
    //(2)
    //gl_FragColor = texture2D(colorMap, varyTextCoord);

    //(3)颜色和纹理混合
    vec4 weakMask = texture2D(colorMap, varyTextCoord);
    vec4 mask = varyColor;
    float alpha = 0.3;
    vec4 tempColor = mask * (1.0 - alpha) + weakMask * alpha;
    gl_FragColor = tempColor;
}
