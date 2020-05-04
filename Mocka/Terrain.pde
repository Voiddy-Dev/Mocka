Platform[] platforms = new Platform[0];

void killTerrain() {
  for (Platform p : platforms) {
    box2d.destroyBody(p.body);
  }
  platforms = new Platform[0];
}

void showTerrain() {
  noStroke();
  fill(0);

  rectMode(CENTER);
  // Simple small rectangle at the bottom of the screen
  for (Platform p : platforms) p.show();
}

// ###@@@### sync client / server sync

PlatformInfo[] randomTerrain(int num_platforms) {
  PlatformInfo[] platforms = new PlatformInfo[num_platforms];
  platforms[0] = new PlatformInfo(width/2, height - 50, width, 100);
  for (int i = 1; i < num_platforms; i++) {
    platforms[i] = new PlatformInfo(random(width), random(height), random(40, 200), random(40, 100));
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

class Platform extends PlatformInfo {
  // coordinates and used var
  int used;

  Body body;

  // constant that corresponds the necessary wait time
  // to make a platform disappear
  int NECESSARY_FRAMES = 20;
  int HEIGHT = 20;

  // constructor and initialize the platform
  public Platform(PlatformInfo info) {
    super(info);

    this.used = NECESSARY_FRAMES;

    // Define the polygon
    PolygonShape sd = new PolygonShape();
    // Figure out the box2d coordinates
    float box2dW = box2d.scalarPixelsToWorld(w/2);
    float box2dH = box2d.scalarPixelsToWorld(h/2);
    // We're just a box
    sd.setAsBox(box2dW, box2dH);


    // Create the body
    BodyDef bd = new BodyDef();
    bd.type = BodyType.STATIC;
    bd.angle = 0;
    bd.position.set(box2d.coordPixelsToWorld(x, y));
    body = box2d.createBody(bd);

    // Attached the shape to the body using a Fixture
    body.createFixture(sd, 1);
    body.setUserData(this);
  }

  // reduce the used variable if possible otherwise return false
  public boolean reduceUsed() {
    if (used <= 0) return false;

    used--;
    return true;
  }

  // display the platform
  public void show() {
    rect(x, y, w, h);
  }
}
