// Input fragment attributes (from fragment shader)
in vec2 fragTexCoord;
in vec4 fragColor;

// Input uniform values
uniform sampler2D texture0; // layer data widthXheight, contains tileIds
uniform sampler2D texture1; // palette provided as a 256x1 texture, RGBA
uniform sampler2D texture2; // tileset images 2048x2048, indexed
uniform sampler2D texture3; // tileset mapping 64x64, contains map to static tileIds
uniform vec2 layerSize;
uniform vec4 colDiffuse;

vec4 selection = vec4(0, 0, 0, 0);

void main() {
  vec2 texCoord = fragTexCoord * layerSize;
  // load tileId from layer (it may be an animated tile and/or flipped)
  vec2 tileTex = texture(texture0, fragTexCoord).ra * 255.0;
  float tileId = floor(tileTex.x + tileTex.y * 256.0 + 0.5);
  float flips1 = floor(tileId / 4096.0);
  tileId = mod(tileId, 4096.0);
  if (tileId == 0.0) {discard;}
  vec2 tileIdCoords = vec2(mod(tileId, 64.0), floor(tileId / 64.0));

  // resolve the base tile from tileset (may be flipped again, if inside an animation)
  vec2 tileMapTex = texture(texture3, tileIdCoords / 64.0).ra * 255.0;
  tileId = floor(tileMapTex.x + tileMapTex.y * 256.0 + 0.5);
  float flips2 = floor(tileId / 4096.0);
  tileId = mod(tileId, 4096.0);
  if (tileId == 0.0) {discard;}
  vec2 tileMapCoords = vec2(mod(float(tileId), 64.0), floor(tileId / 64.0));

  // pixel coordinates inside tile (0.0 - 1.0)
  vec2 uv = mod(fragTexCoord * layerSize, 1.0);

  // apply flips
  if (mod(flips1, 2.0) != mod(flips2, 2.0)) {
    uv.x = 1.0 - uv.x;
  }
  if (mod(floor(flips1 / 2.0), 2.0) != mod(floor(flips2 / 2.0), 2.0)) {
    uv.y = 1.0 - uv.y;
  }

  // get the palette index from palette
  vec4 tilesetTile = texture(texture2, (tileMapCoords + uv) / 64.0);
  // load color from palette
  vec4 outColor = texture(texture1, vec2(tilesetTile.r, 0.0)) * fragColor;
  if (texCoord.x >= selection.x && texCoord.x < selection.z && texCoord.y >= selection.y && texCoord.y < selection.w) {
    outColor = vec4(1,1,1,1) - outColor;
  }
  // fix alpha
  outColor.a = tilesetTile.a * fragColor.a;
  finalColor = outColor * colDiffuse;
}
