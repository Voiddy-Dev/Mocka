Platform[] platforms = new Platform[0];

void killTerrain() {
  for (Platform p : platforms) p.killBody();
  platforms = new Platform[0];
}

void showTerrain() {
  noStroke();
  fill(0);
  rectMode(CENTER);
  for (Platform p : platforms) p.show();
}

Platform[] getPlatforms(ByteBuffer data) {
  int size = data.getInt();
  Platform[] plats = new Platform[size];
  for (int i = 0; i < size; i++) plats[i] = getPlatform(data);
  return plats;
}

Platform getPlatform(ByteBuffer data) {
  //byte id = data.get();
  //if (id == (byte) 0) return new Rectangle(data);
  return new Rectangle(data);
}

interface Platform {
  void show();
  void killBody();
  void putData(ByteBuffer data);
}

Platform[] randomTerrain(int num_platforms) {
  Platform[] platforms = new Platform[num_platforms];
  platforms[0] = new Rectangle(WIDTH/2, HEIGHT - 50, WIDTH, 100, 0);
  for (int i = 1; i < num_platforms; i++) {
    platforms[i] = new Rectangle(random(WIDTH), random(HEIGHT), random(40, 200), random(40, 100), 0);
  }
  return platforms;
}

void writeTerrain(ByteBuffer data, Platform[] platforms) {
  data.putInt(platforms.length);
  for (Platform p : platforms) p.putData(data);
}

Platform[] dataToTerrain(ByteBuffer data) {
  Platform[] platforms = new Platform[data.getInt()];
  for (int i = 0; i < platforms.length; i++) platforms[i] = new Rectangle(data);
  return platforms;
}

class Rectangle implements Platform {
  float x, y, w, h, angle;
  Body body;

  // constructor and initialize the platform
  Rectangle(ByteBuffer data) {
    this(data.getFloat(), data.getFloat(), data.getFloat(), data.getFloat(), 0);
  }
  Rectangle(float x, float y, float w, float h, float angle) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.angle = angle;

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

  void putData(ByteBuffer data) {
    data.putFloat(x);
    data.putFloat(y);
    data.putFloat(w);
    data.putFloat(h);
    //data.putFloat(angle);
  }

  void killBody() {
    box2d.destroyBody(body);
  }

  // display the platform
  public void show() {
    rect(x, y, w, h);
  }
}
