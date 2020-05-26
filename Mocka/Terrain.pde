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
  void show();
  void killBody();
  void putData(ByteBuffer data);
  int size();

  boolean isTouching(float x, float y);
  void mouseBy(float x, float y);
}

class Circle implements Platform {
  float x, y, r;
  Body body;

  // constructor and initialize the platform
  Circle(ByteBuffer data) {
    this(data.getFloat(), data.getFloat(), data.getFloat());
  }
  Circle(float x, float y, float r) {
    this.x = x;
    this.y = y;
    this.r = r;

    // Define the polygon
    CircleShape sd = new CircleShape();
    // We're just a circle
    float b2dr = box2d.scalarPixelsToWorld(r);
    sd.setRadius(b2dr);

    // Create the body
    BodyDef bd = new BodyDef();
    bd.type = BodyType.STATIC;
    bd.position.set(box2d.coordPixelsToWorld(x, y));
    body = box2d.createBody(bd);

    // Attached the shape to the body using a Fixture
    body.createFixture(sd, 1);
    body.setUserData(this);
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

  void killBody() {
    box2d.destroyBody(body);
  }

  // display the platform
  public void show() {
    ellipse(x, y, 2*r, 2*r);
  }

  boolean isTouching(float x, float y) {
    return dist(x, y, this.x, this.y) < r;
  }
  void mouseBy(float x, float y) {
    this.x += x;
    this.y += y;
    Vec2 new_pos = box2d.coordPixelsToWorld(this.x, this.y);
    body.setTransform(new_pos, 0);
  }
}


class Rectangle implements Platform {
  float x, y, w, h, angle;
  Body body;

  // constructor and initialize the platform
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
    bd.angle = -angle;
    bd.position.set(box2d.coordPixelsToWorld(x, y));
    body = box2d.createBody(bd);

    // Attached the shape to the body using a Fixture
    body.createFixture(sd, 1);
    body.setUserData(this);
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

  void killBody() {
    box2d.destroyBody(body);
  }

  // display the platform
  public void show() {
    // note - rectMode(CENTER);
    pushMatrix();
    translate(x, y);
    rotate(angle);
    rect(0, 0, w, h);
    popMatrix();
  }

  boolean isTouching(float x, float y) {
    PVector relpos = new PVector(x - this.x, y - this.y);
    relpos.rotate(-angle);
    return abs(relpos.x) < w/2 && abs(relpos.y) < h/2;
  }
  void mouseBy(float x, float y) {
    this.x += x;
    this.y += y;
    Vec2 new_pos = box2d.coordPixelsToWorld(this.x, this.y);
    body.setTransform(new_pos, -angle);
  }
}
