
void putPlatforms(ByteBuffer data, Platform[] plats) {
  data.putInt(plats.length);
  for (Platform p : plats) p.putData(data);
}

int sizePlatforms(Platform[] plats) {
  int total = 4;
  for (Platform p : plats) total += p.size();
  return total;
}

//Platform[] createTerrain(int num_platforms) {
//  Platform[] platforms = new Platform[num_platforms+4];

//  // BORDERS
//  platforms[0] = new Rectangle(WIDTH/2, HEIGHT - 25, WIDTH, 50); // base platform
//  platforms[1] = new Rectangle(1, HEIGHT/2, 2, HEIGHT); // left 
//  platforms[2] = new Rectangle(WIDTH-1, HEIGHT/2, 2, HEIGHT); // right
//  platforms[3] = new Rectangle(WIDTH/2, 1, WIDTH, 2); // top 

//  for (int i = 0; i < num_platforms; i++) {
//    platforms[i+4] = randomPlatform();
//  }
//  return platforms;
//}

void savePlatforms(Platform[] plats, String filename) {
  int sizeOfMetadata = 16; // Leave some space for whatever
  ByteBuffer data = ByteBuffer.allocate(sizeOfMetadata + sizePlatforms(plats));

  data.putInt(0); // version of fileformat used
  data.putInt(0); // unused // data of creation?
  data.putInt(0); // unused // type of map? 
  data.putInt(0); // unused // Possilbe gamemodes?

  putPlatforms(data, plats);
  saveBytes(filename, data.array());
}
