#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

uniform vec2 WindowSize;
uniform bool do1;
uniform bool do2;
uniform bool do3;
uniform vec2 diff;

uniform sampler2D texture;

varying vec4 vertColor;
varying vec4 vertTexCoord;

void main() {
  vec2 texCoord = vertTexCoord.st - diff/WindowSize;
  vec2 off1 = vec2(1.0, 0) / WindowSize;
  vec2 off2 = vec2(0, 1.0) / WindowSize;
  vec4 color = vec4(0);
  color += texture2D(texture, texCoord.xy) * 0.2270270270;
  color += texture2D(texture, texCoord.xy + off1) * 0.3162162162;
  color += texture2D(texture, texCoord.xy - off1) * 0.3162162162;
  color += texture2D(texture, texCoord.xy + off2) * 0.0702702703;
  color += texture2D(texture, texCoord.xy - off2) * 0.0702702703;
  // color = texture2D(texture, texCoord.xy);
  if (do1){
    color = max(texture2D(texture, texCoord.xy + off1), color);
    color = max(texture2D(texture, texCoord.xy - off1), color);
    color = max(texture2D(texture, texCoord.xy + off2), color);
    color = max(texture2D(texture, texCoord.xy - off2), color);
    if (do2){
      color = max(texture2D(texture, texCoord.xy + off1 + off2), color);
      color = max(texture2D(texture, texCoord.xy - off1 + off2), color);
      color = max(texture2D(texture, texCoord.xy + off1 - off2), color);
      color = max(texture2D(texture, texCoord.xy - off1 - off2), color);
    }
  }
  if (do3)gl_FragColor = max(vec4(0,0,0,1), vec4(color.xyz - vec3(0.002), 1.0));
  else gl_FragColor = max(vec4(0,0,0,1), vec4(color.xyz, 1.0));
  //gl_FragColor = vec4((texture2D(texture, texCoord.xy + vec2(0.5,0.5)) * vertColor * 0.9).xyz, 1.0);
}