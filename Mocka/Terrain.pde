ArrayList<Platform> platforms = new ArrayList();

void setupTerrain() {
  platforms.add(new Platform(width/2, height - 50, width, 100));

  for (int i = 0; i < 8; i++) {
    platforms.add(new Platform(random(width), random(height), random(40, 200), random(40, 100)));
  }
}

void showTerrain() {
  noStroke();
  fill(GAME_COLOR);

  rectMode(CORNER);
  // Simple small rectangle at the bottom of the screen
  for (Platform p : platforms) p.show();

  strokeWeight(5);
  stroke(0);
}

public class Platform {
  // coordinates and used var
  float x, y, w, h;
  int used;

  Body body;

  // constant that corresponds the necessary wait time
  // to make a platform disappear
  int NECESSARY_FRAMES = 20;
  int HEIGHT = 20;

  // constructor and initialize the platform
  public Platform(float x, float y, float w, float h) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;

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
  }

  // reduce the used variable if possible otherwise return false
  public boolean reduceUsed() {
    if (used <= 0) return false;

    used--;
    return true;
  }

  // returns true if something is touching the platform
  public boolean isTouching(int inX, int inY) {
    return (inX <= x + w/2) && (inX >= x - w/2) && (inY <= y + h/2) && (inY >= y - h/2);
  }

  // display the platform
  public void show() {
    rectMode(CENTER);
    noStroke();
    fill(GAME_COLOR);
    rect(x, y, w, h);

    // display units
    fill(255);
    strokeWeight(2);
    textAlign(CENTER, CENTER);
    textSize(18);
    text(String.valueOf(used), x, y-3);
  }
}
