#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

uniform vec2 WindowSize;

uniform sampler2D texture;

varying vec4 vertColor;
varying vec4 vertTexCoord;

void main() {
  vec2 pos = vertTexCoord.st - vec2(0.5);
  float scale = sqrt(pos.s*pos.s + pos.t*pos.t);
  vec4 col1 = texture2D(texture, vertTexCoord.st + scale * vec2(2.0, 0) / WindowSize);
  vec4 col2 = texture2D(texture, vertTexCoord.st + scale * vec2(-1.0, 1.0) / WindowSize);
  vec4 col3 = texture2D(texture, vertTexCoord.st + scale * vec2(-1.0, -1.0) / WindowSize);
  gl_FragColor = vec4(col1.x, col2.y, col3.z, 1.0);
  // gl_FragColor = (col1 + col2 + col3) / 3;
  // gl_FragColor = texture2D(texture, vertTexCoord.st).xxxz;
}