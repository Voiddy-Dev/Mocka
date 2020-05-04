class BallShape {
  Body body;

  int radius = 0;

  BallShape(float x, float y, int radius) {
    this.radius = radius;

    makeBody(new Vec2(x, y));
  }

  void makeBody(Vec2 center) {
    CircleShape cs = new CircleShape();
    cs.m_radius = box2d.scalarPixelsToWorld(this.radius);

    // Define the body and make it from the shape
    BodyDef bd = new BodyDef();
    bd.type = BodyType.STATIC;
    bd.position.set(box2d.coordPixelsToWorld(center));
    body = box2d.createBody(bd);

    body.createFixture(cs, 1.0);
  }

  // Drawing the ball
  void display() {
    // We look at each body and get its screen position
    Vec2 pos = box2d.getBodyPixelCoord(body);

    pushMatrix();
    translate(pos.x, pos.y);
    fill(0);
    noStroke();
    ellipse(0, 0, radius*2, radius*2);
    popMatrix();
  }
}
