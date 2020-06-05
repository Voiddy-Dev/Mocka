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
  void putLocalData(ByteBuffer data);
  void getChanges(ByteBuffer data);
  int size();

  boolean isTouching(float x, float y);
  void moveBy(float x, float y);

  void noteChanges(); // Hey! I've made some local changes, so please don't overwrite local vars!
  void noteUnchanges(); // Ok, we're good now, please overwrite. It's 'getChanges' is likely being called because some other player is changing the map
}

abstract class ConcretePlatorm implements Platform {
  protected float x, y;
  float lx, ly; // Local variables - not 'true' (synced) but used for GUI to avoid latency

  void moveBy(float x, float y) {
    this.lx += x;
    this.ly += y;
  }

  boolean changes = false;
  void noteChanges() {
    changes = true;
  }
  void noteUnchanges() {
    changes = false;
  }
}

class Circle extends ConcretePlatorm {
  private float r;
  float lr; // Local var
  Body body;

  // constructor and initialize the platform
  Circle(ByteBuffer data) {
    this(data.getFloat(), data.getFloat(), data.getFloat());
  }
  Circle(float x, float y, float r) {
    this.lx = this.x = x;
    this.ly = this.y = y;
    this.lr = this.r = r;
    makeBody();
  }
  void makeBody() {
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
  void putLocalData(ByteBuffer data) {
    data.put((byte)1);
    data.putFloat(lx);
    data.putFloat(ly);
    data.putFloat(lr);
  }
  void getChanges(ByteBuffer data) {
    byte useless = data.get(); // big phat bodge
    this.x = data.getFloat();
    this.y = data.getFloat();
    this.r = data.getFloat();
    killBody();
    makeBody();
    if (!changes) {
      lx = x;
      ly = y;
      lr = r;
    }
  }
  int size() {
    return 13;
  }

  void killBody() {
    box2d.destroyBody(body);
  }

  // display the platform
  public void show() {
    ellipse(lx, ly, 2*lr, 2*lr);
  }

  boolean isTouching(float x, float y) {
    return dist(x, y, this.lx, this.ly) < lr;
  }
}


class Rectangle extends ConcretePlatorm {
  private float w, h, angle;
  float lw, lh, langle;
  Body body;

  // constructor and initialize the platform
  Rectangle(ByteBuffer data) {
    this(data.getFloat(), data.getFloat(), data.getFloat(), data.getFloat(), data.getFloat());
  }
  Rectangle(float x, float y, float w, float h) {
    this(x, y, w, h, 0);
  }
  Rectangle(float x, float y, float w, float h, float angle) {
    this.lx = this.x = x;
    this.ly = this.y = y;
    this.lw = this.w = w;
    this.lh = this.h = h;
    this.langle = this.angle = angle;
    makeBody();
  }
  void makeBody() {
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
  void putLocalData(ByteBuffer data) {
    data.put((byte)0);
    data.putFloat(lx);
    data.putFloat(ly);
    data.putFloat(lw);
    data.putFloat(lh);
    data.putFloat(langle);
  }
  void getChanges(ByteBuffer data) {
    byte useless = data.get(); // big phat bodge
    this.x = data.getFloat();
    this.y = data.getFloat();
    float w = data.getFloat();
    float h = data.getFloat();
    this.angle = data.getFloat();
    if (w != this.w || h != this.h) {
      //resized - need to change fixture
      this.w = w;
      this.h = h;
      killBody();
      makeBody();
      if (!changes) {
        lx = x;
        ly = y;
        lw = w;
        lh = h;
        langle = angle;
      }
    } else {
      Vec2 new_pos = box2d.coordPixelsToWorld(this.x, this.y);
      body.setTransform(new_pos, -angle);
      if (!changes) {
        lx = x;
        ly = y;
        lw = w;
        lh = h;
        langle = angle;
      }
    }
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
    translate(lx, ly);
    rotate(langle);
    rect(0, 0, lw, lh);
    popMatrix();
  }

  boolean isTouching(float x, float y) {
    PVector relpos = new PVector(x - this.lx, y - this.ly);
    relpos.rotate(-langle);
    return abs(relpos.x) < lw/2 && abs(relpos.y) < lh/2;
  }
}
