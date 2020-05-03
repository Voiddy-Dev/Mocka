PlatformInfo[] platforms;

void randomizeTerrain() {
  platforms = randomTerrain(8);
  TCP_SEND_ALL_CLIENTS(NOTIFY_TERRAIN(platforms));
}

// ###@@@### sync client / server sync

PlatformInfo[] randomTerrain(int num_platforms) {
  int WIDTH = 1200;
  int HEIGHT = 790;
  PlatformInfo[] platforms = new PlatformInfo[num_platforms];
  platforms[0] = new PlatformInfo(WIDTH/2, HEIGHT - 50, WIDTH, 100);
  for (int i = 1; i < num_platforms; i++) {
    platforms[i] = new PlatformInfo(random(WIDTH), random(HEIGHT), random(140, 250), random(140, 150));
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
