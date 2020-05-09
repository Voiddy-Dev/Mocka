Platform[] platforms;

void randomizeTerrain(int num_platforms) {
  platforms = randomTerrain(num_platforms);
  TCP_SEND_ALL_CLIENTS(NOTIFY_TERRAIN(platforms));
}

Platform[] randomTerrain(int num_platforms) {
  Platform[] platforms = new Platform[num_platforms+4];

  // BORDERS
  platforms[0] = new Rectangle(WIDTH/2, HEIGHT - 25, WIDTH, 50); // base platform
  platforms[1] = new Rectangle(1, HEIGHT/2, 2, HEIGHT); // left 
  platforms[2] = new Rectangle(WIDTH-1, HEIGHT/2, 2, HEIGHT); // right
  platforms[3] = new Rectangle(WIDTH/2, 1, WIDTH, 2); // top 

  for (int i = 0; i < num_platforms; i++) {
    platforms[i+4] = randomPlatform();
  }
  return platforms;
}

Platform randomPlatform() {
  float rand = random(1);
  if (rand < 0.6) return new Rectangle(random(WIDTH), random(HEIGHT), random(40, 200), random(40, 100), 0);
  else if (rand < 0.8) return new Rectangle(random(WIDTH), random(HEIGHT), random(40, 100), random(40, 100), random(TAU));
  else return new Circle(random(WIDTH), random(HEIGHT), random(40, 100));
}

int sizePlatforms(Platform[] plats) {
  int total = 4;
  for (Platform p : plats) total += p.size();
  return total;
}

void putPlatforms(ByteBuffer data, Platform[] plats) {
  data.putInt(plats.length);
  for (Platform p : plats) p.putData(data);
}

Platform[] getPlatforms(ByteBuffer data) {
  int size = data.getInt();
  Platform[] plats = new Platform[size];
  for (int i = 0; i < size; i++) plats[i] = getPlatform(data);
  return plats;
}

Platform getPlatform(ByteBuffer data) {
  byte id = data.get();
  if (id == (byte) 0) return new Rectangle(data);
  if (id == (byte) 1) return new Circle(data);
  return null;
}

interface Platform {
  void putData(ByteBuffer data);
  int size();
}

class Circle implements Platform {
  float x, y, r;

  Circle(ByteBuffer data) {
    this(data.getFloat(), data.getFloat(), data.getFloat());
  }
  Circle(float x, float y, float r) {
    this.x = x;
    this.y = y;
    this.r = r;
  }

  void putData(ByteBuffer data) {
    data.put((byte)1);
    data.putFloat(x);
    data.putFloat(y);
    data.putFloat(r);
  }
  int size() {
    return 13;
  }
}

class Rectangle implements Platform {
  float x, y, w, h, angle;

  Rectangle(ByteBuffer data) {
    this(data.getFloat(), data.getFloat(), data.getFloat(), data.getFloat(), data.getFloat());
  }
  Rectangle(float x, float y, float w, float h) {
    this(x, y, w, h, 0);
  }
  Rectangle(float x, float y, float w, float h, float angle) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.angle = angle;
  }
  void putData(ByteBuffer data) {
    data.put((byte)0);
    data.putFloat(x);
    data.putFloat(y);
    data.putFloat(w);
    data.putFloat(h);
    data.putFloat(angle);
  }
  int size() {
    return 21;
  }
}
