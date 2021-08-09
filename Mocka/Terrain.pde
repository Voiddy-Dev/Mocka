HashMap<Integer, Platform> platforms;

float cam_x_pos = WIDTH/2;
float cam_y_pos = HEIGHT/2;
float cam_x_pos_smooth = cam_x_pos;
float cam_y_pos_smooth = cam_y_pos;

void killTerrain() {
  for (Platform p : platforms.values()) p.killBody();
  platforms = new HashMap<Integer, Platform>(0);
}

void showTerrain() {
  noStroke();
  fill(255); // bright terrain
  rectMode(CENTER);
  for (Platform p : platforms.values()) p.show();
}

HashMap<Integer, Platform> randomTerrain(int num_platforms) {
  HashMap<Integer, Platform> platforms = new HashMap<Integer, Platform>(4+num_platforms);

  // BORDERS
  platforms.put(0, new Rectangle(WIDTH/2, HEIGHT - 25, WIDTH, 50)); // base platform
  platforms.put(1, new Rectangle(1, HEIGHT/2, 2, HEIGHT)); // left
  platforms.put(2, new Rectangle(WIDTH-1, HEIGHT/2, 2, HEIGHT)); // right
  platforms.put(3, new Rectangle(WIDTH/2, 1, WIDTH, 2)); // top

  for (int i = 0; i < num_platforms; i++) {
    platforms.put(i+4, randomPlatform());
  }
  return platforms;
}

Platform randomPlatform() { // Update this to code from Server
  float rand = random(1);
  if (rand < 0.6) return new Rectangle(random(WIDTH), random(HEIGHT), random(40, 200), random(40, 100), 0);
  else if (rand < 0.8) return new Rectangle(random(WIDTH), random(HEIGHT), random(40, 100), random(40, 100), random(TAU));
  else return new Circle(random(WIDTH), random(HEIGHT), random(40, 100));
}

int sizePlatforms(HashMap<Integer, Platform> plats) {
  int total = 4 + 4*plats.size();
  for (Platform p : plats.values()) total += p.size();
  return total;
}

void putPlatforms(ByteBuffer data, HashMap<Integer, Platform> plats) {
  data.putInt(plats.size());
  for (Map.Entry<Integer, Platform> e : plats.entrySet()) {
    data.putInt(e.getKey());
    e.getValue().putData(data);
  }
}

HashMap<Integer, Platform> getPlatforms(ByteBuffer data) {
  int size = data.getInt();
  HashMap<Integer, Platform> plats = new HashMap<Integer, Platform>(size);
  for (int i = 0; i < size; i++) {
    int id = data.getInt();
    plats.put(id, getPlatform(data));
  }
  return plats;
}

Platform getPlatform(ByteBuffer data) {
  byte id = data.get();
  if (id == (byte) 0) return new Rectangle(data);
  if (id == (byte) 1) return new Circle(data);
  if (id == (byte) 2) return new Polygon(data);
  println("client: Unkown platform type id: "+id+" - the server is likely running a more recent version!");
  exit();
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
    byte useless = data.get(); // big phat bodge // Why is this here again? // Oh because we're just restating the ID of the platform, which we already know
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

class Polygon implements Platform {
  int vertexCount; // Sent as a byte
  PVector[] vertices;
  PVector[] lvertices;
  Body body;

  Polygon(ByteBuffer data) {
    vertexCount = (int) data.get();
    vertices = new PVector[vertexCount];
    lvertices = new PVector[vertexCount];
    for (int i = 0; i < vertexCount; i++) {
      vertices[i] = new PVector(data.getFloat(), data.getFloat());
      lvertices[i] = vertices[i].copy();
    }
    makeBody();
  }
  Polygon(int vertexCount, PVector[] vertices) {
    this.vertexCount = vertexCount;
    this.vertices = vertices;
    this.lvertices = new PVector[vertexCount];
    for (int i = 0; i < vertexCount; i++) lvertices[i] = vertices[i].copy();
    makeBody();
  }
  void makeBody() {
    // Define the polygon
    PolygonShape sd = new PolygonShape();
    // Figure out the box2d coordinates

    Vec2[] vecs = new Vec2[vertexCount];
    for (int i = 0; i < vertexCount; i++) vecs[i] = box2d.coordPixelsToWorld(vertices[i]);
    sd.set(vecs, vertexCount);

    // Create the body
    BodyDef bd = new BodyDef();
    bd.type = BodyType.STATIC;
    //    bd.angle = -angle;
    //bd.position.set(box2d.coordPixelsToWorld(x, y));
    body = box2d.createBody(bd);

    // Attached the shape to the body using a Fixture
    body.createFixture(sd, 1);
    body.setUserData(this);
  }
  void putData(ByteBuffer data) {
    data.put((byte)2);
    data.put((byte)vertexCount);
    for (PVector v : vertices) {
      data.putFloat(v.x);
      data.putFloat(v.y);
    }
  }
  void putLocalData(ByteBuffer data) {
    data.put((byte)2);
    data.put((byte)vertexCount);
    for (PVector v : lvertices) {
      data.putFloat(v.x);
      data.putFloat(v.y);
    }
  }
  void getChanges(ByteBuffer data) {
    byte useless = data.get(); // this again came to bite me
    vertexCount = (int) data.get();
    vertices = new PVector[vertexCount];
    //lvertices = new PVector[vertexCount]; // hum... I guess we should keep our own changes right // Yep, for sure. Testing confirms. Otherwise leads to drifting over time
    for (int i = 0; i < vertexCount; i++) vertices[i] = new PVector(data.getFloat(), data.getFloat());
    killBody();
    makeBody();
  }
  int size() {
    return 2 + 8 * vertexCount;
  }

  void killBody() {
    box2d.destroyBody(body);
  }
  void show() {
    beginShape();
    if (changes)for (PVector v : lvertices)vertex(v.x, v.y);
    else for (PVector v : vertices)vertex(v.x, v.y);
    endShape();
  }

  boolean isTouching(float x, float y) {
    PVector center = new PVector(0, 0); // This is the reference frame I guess
    for (PVector v : vertices) center.add(v);
    center.mult(1.0/vertexCount); // This is not a fool proof solution. Not all polygons are guarenteed to be convex. This will lead to glithes.
    PVector m = new PVector(x, y).sub(center);
    for (int i = 0; i < vertexCount; i++) {
      PVector va = PVector.sub(vertices[i], center);
      PVector vb = PVector.sub(vertices[(i+1)%vertexCount], center);
      if (PVector.dot(va.copy().rotate(HALF_PI), m) < 0) continue;
      if (PVector.dot(vb.copy().rotate(HALF_PI), m) > 0) continue;
      if (PVector.dot(PVector.sub(vb, va).rotate(HALF_PI), PVector.sub(m, va)) < 0) continue;
      return true;
    }
    return false;
  }
  //void moveBy(float x, float y);

  boolean changes = false;
  void noteChanges() {
    //changes = true; // Or not? seems to make this crash...
  }
  void noteUnchanges() {
    changes = false;
  }
  void moveBy(float x, float y) {
    PVector move = new PVector(x, y);
    if (changes) for (int i = 0; i < vertexCount; i++) lvertices[i].add(move);
    else for (int i = 0; i < vertexCount; i++) lvertices[i] = PVector.add(vertices[i], move);
    changes = true;
  }
}
