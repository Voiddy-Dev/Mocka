/*
The rocket class encapsulates a BOX2D object.
 */

public class Rocket {
  Body body; // Box2d body
  ParticleSystem exhaust;
  boolean INPUT_up, INPUT_right, INPUT_left;
  color col;
  int UUID = -1;
  float x = 0, y = 0, angle, px = 0, py = 0;

  String name = "";

  int place, points;

  public Rocket(float x, float y) {
    exhaust = new ParticleSystem();
    makeBody(new Vec2(x, y));

    rocketIcon = loadShape("rocket.svg");
  }

  void setName(String name) {
    this.name = name; // all checks should be done server side
  }

  void setColor(color col) {
    this.col = col;
  }

  private void makeBody(Vec2 center) {
    // Define a polygon (this is what we use for a rectangle)
    PolygonShape sd = new PolygonShape();

    Vec2[] vertices = new Vec2[rocketShape.getVertexCount()];
    for (int i = 0; i < vertices.length; i++) vertices[i] = box2d.vectorPixelsToWorld(new Vec2(rocketShape.getVertexX(i), rocketShape.getVertexY(i)));
    sd.set(vertices, vertices.length);

    // Define the body and make it from the shape
    BodyDef bd = new BodyDef();
    bd.type = BodyType.DYNAMIC;
    bd.position.set(center);
    body = box2d.createBody(bd);

    body.createFixture(sd, 1.0);
    body.setUserData(this);
  }

  protected void killBody() {
    box2d.destroyBody(body);
  }

  // method to display the rocket
  public void show() {
    Vec2 pos = box2d.getBodyPixelCoord(body);
    px = x;
    py = y;
    x = pos.x;
    y = pos.y;
    angle = body.getAngle();

    fill(col);
    noStroke();
    triangle(pos.x-7, pos.y-30, pos.x+7, pos.y-30, pos.x, pos.y-22);

    pushMatrix();
    translate(pos.x, pos.y);

    if (this.name != null) {
      fill(255); // White text on black background
      textSize(18);
      textAlign(CENTER, CENTER);
      rectMode(CENTER);
      text(name, 0, -43, 100, 30);
    }

    rotate(-angle);
    scale(1.0/10);

    pushMatrix();
    gamemode.decoratePre(this);
    popMatrix();

    // Jets
    noStroke();
    fill(col);
    final int JET_OFFSET=50;
    if (INPUT_right) triangle(-50, -50 - JET_OFFSET, -50, 50 - JET_OFFSET, -random(100, 180), -JET_OFFSET);
    if (INPUT_left) triangle(50, -50 - JET_OFFSET, 50, 50 - JET_OFFSET, random(100, 180), -JET_OFFSET);

    // Rocket body
    rocketShape.setFill(col);
    rocketShape.setStroke(false);
    pushMatrix();
    translate(-rocketIcon.width/2, -rocketIcon.height/2);
    shape(rocketIcon);
    popMatrix();

    gamemode.decoratePost(this);
    popMatrix();

    exhaust.show(col);
  }

  // User interactions / arrow keys
  public void interactions() {
    Vec2 pos = box2d.getBodyPixelCoord(body);
    float angle = body.getAngle();

    //if (pos.x > WIDTH) body.setTransform(box2d.coordPixelsToWorld(new Vec2(pos.x-WIDTH, pos.y)), angle);
    //if (pos.x < 0) body.setTransform(box2d.coordPixelsToWorld(new Vec2(pos.x+WIDTH, pos.y)), angle);

    // createExhaust
    float DIST_FROM_CENTER = 17;
    PVector part_Pos = new PVector(pos.x + DIST_FROM_CENTER * sin(angle),
      pos.y + DIST_FROM_CENTER * cos(angle));
    Vec2 bodyvel = body.getLinearVelocity();
    PVector acc = new PVector(0, 0.1).rotate(-angle);
    PVector vel = new PVector(bodyvel.x, bodyvel.y).mult(0.01);
    vel.add(PVector.mult(acc, 35));

    if (INPUT_up) {
      float mag = - box2d.world.getGravity().y * 10;
      Vec2 force = new Vec2(-mag * sin(angle), mag * cos(angle));
      body.applyForceToCenter(force);

      exhaust.turnOn(part_Pos, acc, vel);
    }
    if (INPUT_left) {
      body.applyTorque(35);
    }
    if (INPUT_right) {
      body.applyTorque(-35);
    }
  }
}

PVector respawnPos;

class MyRocket extends Rocket {
  boolean KEY_up, KEY_right, KEY_left;

  int standupCounter = Integer.MAX_VALUE;
  float standupAngle;
  boolean standupDirection;

  int TOUCHING_PLATFORMS = 0;

  boolean AP_ACTIVE = SETTING_DEFAULT_AP_STATE;
  float AP_P_COEF = 10;
  float AP_D_COEF = 1.5;

  MyRocket(float x, float y) {
    super(x, y);
  }
  void setColor(color col) {
    GAME_COLOR_ = col;
    super.setColor(col);
  }
  public void interactions() {
    float angle = myRocket.body.getAngle();
    angle = ((angle % TAU) + TAU) % TAU;
    float angle_vel = myRocket.body.getAngularVelocity();
    if (!doingStandingProcedure()) {
      INPUT_up = KEY_up;
      INPUT_right = KEY_right;
      INPUT_left = KEY_left;
      if (AP_ACTIVE && !KEY_right && !KEY_left) {
        float angle2 = angle;
        if (angle2 > PI) angle2 -= TAU;
        float sum = AP_P_COEF * angle2 + angle_vel * AP_D_COEF;
        if (abs(sum) > 2) {
          INPUT_right = sum > 0;
          INPUT_left = sum < 0;
        } else {
          INPUT_right = INPUT_left = false;
        }
      }
    } else {
      standupCounter++;
      if (angle > PI) angle -= TAU;
      int dir = standupDirection ? -1 : 1;
      standupAngle += (angle - standupAngle) * 0.2;
      standupAngle -= dir * (radians(45)/20);
      float force = (angle - standupAngle) * 20;
      force = constrain(force, -13, 13);
      myRocket.body.applyAngularImpulse(-force);
      if (abs(angle) < radians(10)) standupCounter = Integer.MAX_VALUE;
      myRocket.INPUT_up = false;
      myRocket.INPUT_left = standupDirection;
      myRocket.INPUT_right = !standupDirection;
    }
    super.interactions();
  }
  boolean contactIsWithPlatform(Contact cp) {
    Object o1 = cp.getFixtureA().getBody().getUserData();
    Object o2 = cp.getFixtureB().getBody().getUserData();
    if (o1 != this && o2 != this) return false; // does not concern us (ie our player-local simulation)
    return o1 instanceof Platform || o2 instanceof Platform;
  }
  void respawnRocket(float x, float y) {
    TOUCHING_PLATFORMS = 0;
    standupCounter = Integer.MAX_VALUE;
    Vec2 new_pos = box2d.coordPixelsToWorld(x, y);
    myRocket.body.setTransform(new_pos, 0);
    Vec2 new_vel = new Vec2(0, 0);
    myRocket.body.setLinearVelocity(new_vel);
    myRocket.body.setAngularVelocity(0);
  }
  void respawnRocket() {
    //respawnRocket(WIDTH/2, HEIGHT/2);
    respawnRocket(respawnPos.x, respawnPos.y);
  }
  boolean doingStandingProcedure() {
    return standupCounter < 60;
  }
  void initiateStandup() {
    if (TOUCHING_PLATFORMS == 0) return;
    if (doingStandingProcedure()) return;
    float angle = myRocket.body.getAngle();
    angle = ((angle % TAU) + TAU) % TAU;
    if (angle > PI) angle -= TAU;
    if (abs(angle) > radians(45)) {
      standupDirection = angle < 0;
      standupAngle = angle;
    }
    standupCounter = 0;
  }
}
