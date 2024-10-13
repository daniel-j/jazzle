// Input fragment attributes (from fragment shader)
in vec2 fragTexCoord;
in vec4 fragColor;

// Input uniform values
uniform sampler2D texture0;
uniform sampler2D texture1; // palette provided as a 256x1 texture

void main() {
  // Texel color fetching from texture sampler
  // NOTE: The texel is actually the a GRAYSCALE index color
  vec4 texelColor = texture(texture0, fragTexCoord);

  finalColor = texture(texture1, vec2(texelColor.r, 0.0)) * fragColor;
  finalColor.a = 1.0 * texelColor.a;
}
