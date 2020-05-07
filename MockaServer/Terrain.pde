PlatformInfo[] platforms;

void randomizeTerrain(int num_platforms) {
  platforms = randomTerrain(num_platforms);
  TCP_SEND_ALL_CLIENTS(NOTIFY_TERRAIN(platforms));
}

// ###@@@### sync client / server sync

PlatformInfo[] randomTerrain(int num_platforms) {
  PlatformInfo[] platforms = new PlatformInfo[num_platforms+4];

  // BORDERS
  platforms[0] = new PlatformInfo(WIDTH/2, HEIGHT - 25, WIDTH, 50); // base platform
  platforms[1] = new PlatformInfo(1, HEIGHT/2, 2, HEIGHT); // left 
  platforms[2] = new PlatformInfo(WIDTH-1, HEIGHT/2, 2, HEIGHT); // right
  platforms[3] = new PlatformInfo(WIDTH/2, 1, WIDTH, 2); // top 

  for (int i = 0; i < num_platforms; i++) {
    platforms[i+4] = new PlatformInfo(random(WIDTH), random(HEIGHT), random(40, 200), random(40, 100));
  }
  return platforms;
}

void writeTerrain(ByteBuffer data, PlatformInfo[] platforms) {
  data.putInt(platforms.length);
  for (PlatformInfo p : platforms) p.putData(data);
}

PlatformInfo[] dataToTerrain(ByteBuffer data) {
  PlatformInfo[] platforms = new PlatformInfo[data.getInt()];
  for (int i = 0; i < platforms.length; i++) platforms[i] = new PlatformInfo(data);
  return platforms;
}

class PlatformInfo {
  float x, y, w, h;

  PlatformInfo(float x, float y, float w, float h) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
  }

  PlatformInfo(PlatformInfo info) {
    this(info.x, info.y, info.w, info.h);
  }

  PlatformInfo(ByteBuffer data) {
    this(data.getFloat(), data.getFloat(), data.getFloat(), data.getFloat());
  }

  void putData(ByteBuffer data) {
    data.putFloat(x);
    data.putFloat(y);
    data.putFloat(w);
    data.putFloat(h);
  }
}

// ###@@@### end client / server sync
