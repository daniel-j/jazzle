// Input fragment attributes (from fragment shader)
in vec2 fragTexCoord;
in vec4 fragColor;

// Input uniform values
uniform sampler2D texture0; // tilemap
uniform sampler2D texture1; // palette provided as a 256x1 texture
uniform sampler2D texture2; // tileset images 2048x2048
uniform sampler2D texture3; // tileset mapping 64x64
uniform vec2 layerSize;

void main() {
  vec2 tileId = texture(texture0, fragTexCoord).ra * 4.0;

  vec2 uv = mod(fragTexCoord * layerSize, 1.0);

  vec2 tileMap = texture(texture3, tileId).ra * 4.0;
  vec4 tilesetTile = texture(texture2, (floor(tileMap * 64.0) + uv) / 64.0);
  finalColor = texture(texture1, vec2(tilesetTile.r, 0.0)) * fragColor;
  finalColor.a = 1.0 * tilesetTile.a;
}
