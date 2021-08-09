#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

uniform vec2 WindowSize;
uniform bool do1;
uniform bool do2;
uniform bool do3;

uniform sampler2D texture;

varying vec4 vertColor;
varying vec4 vertTexCoord;

// float rand(vec2 co){
//   return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
// }

void main() {
  vec2 off1 = vec2(1.0, 0) / WindowSize;
  vec2 off2 = vec2(0, 1.0) / WindowSize;
  vec4 color = vec4(0);
  color += texture2D(texture, vertTexCoord.st) * 0.2270270270;
  color += texture2D(texture, vertTexCoord.st + off1) * 0.3162162162;
  color += texture2D(texture, vertTexCoord.st - off1) * 0.3162162162;
  color += texture2D(texture, vertTexCoord.st + off2) * 0.0702702703;
  color += texture2D(texture, vertTexCoord.st - off2) * 0.0702702703;
  // color = texture2D(texture, vertTexCoord.st);
  if (do1){ //rand(vertTexCoord.st + color.xy) > 0.4) {
    color = max(texture2D(texture, vertTexCoord.st + off1), color);
    color = max(texture2D(texture, vertTexCoord.st - off1), color);
    color = max(texture2D(texture, vertTexCoord.st + off2), color);
    color = max(texture2D(texture, vertTexCoord.st - off2), color);
    if (do2){//rand(vertTexCoord.st + color.xy) > 0.4) {
      color = max(texture2D(texture, vertTexCoord.st + off1 + off2), color);
      color = max(texture2D(texture, vertTexCoord.st - off1 + off2), color);
      color = max(texture2D(texture, vertTexCoord.st + off1 - off2), color);
      color = max(texture2D(texture, vertTexCoord.st - off1 - off2), color);
    }
  }
  if (do3)gl_FragColor = max(vec4(0,0,0,1), vec4(color.xyz - vec3(0.002), 1.0));
  else gl_FragColor = max(vec4(0,0,0,1), vec4(color.xyz, 1.0));
  //gl_FragColor = vec4((texture2D(texture, vertTexCoord.st + vec2(0.5,0.5)) * vertColor * 0.9).xyz, 1.0);
}