// Input fragment attributes (from fragment shader)
in vec2 fragTexCoord;
in vec4 fragColor;

// Input uniform values
uniform sampler2D texture0; // tilemap
uniform sampler2D texture1; // palette provided as a 256x1 texture
uniform sampler2D texture2; // tileset 2048x2048
uniform vec2 layerSize;

void main() {
  vec2 tileId = floor(texture(texture0, fragTexCoord).ra * 256.0);

  vec2 uv = mod(fragTexCoord * layerSize, 1.0);

  vec4 tilesetTile = texture(texture2, (tileId + uv) / 64.0);
  finalColor = texture(texture1, vec2(tilesetTile.r, 0.0)) * fragColor;
  finalColor.a = 1.0 * tilesetTile.a;
}
