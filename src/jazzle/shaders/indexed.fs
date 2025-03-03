// Input fragment attributes (from fragment shader)
in vec2 fragTexCoord;
in vec4 fragColor;

// Input uniform values
uniform sampler2D texture0;
uniform sampler2D texture1; // palette provided as a 256x1 texture, RGBA
uniform vec4 colDiffuse;


void main() {
  vec4 pixelData = texture(texture0, fragTexCoord);
  // load color from palette
  vec4 outColor = texture(texture1, vec2(pixelData.r, 0.0)) * fragColor;

  // fix alpha
  outColor.a = pixelData.a * fragColor.a;
  finalColor = outColor * colDiffuse;
}
