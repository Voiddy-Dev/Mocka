/*
The rocket class encapsulates a BOX2D object.
 */


import processing.svg.*;

float ROCKET_ICON_SCALE = 0.15;
PShape rocketShape;
PShape rocketIcon;// = loadShape("rocket.svg");

PShape createRocketShape() {
  //Geometry of rocket body imported from talky.io JS
  float mult = 30.0 * (10.0 / 36);
  PShape shape = createShape();
  shape.beginShape();
  //shape.vertex( -.6 * mult, -1.3 * mult);
  shape.vertex( -.5 * mult, -1.5 * mult);
  shape.vertex(   0 * mult, -1.8 * mult);
  shape.vertex(  .5 * mult, -1.5 * mult);
  //shape.vertex(  .6 * mult, -1.3 * mult);
  shape.vertex( 1.2 * mult, .7   * mult);
  shape.vertex(  .9 * mult, 1.8  * mult);
  shape.vertex( -.9 * mult, 1.8  * mult);
  shape.vertex(-1.2 * mult, .7   * mult);
  shape.endShape(CLOSE);
  shape.scale(10);
  return shape;
}

public class Rocket {
  Body body; // Box2d body
  ParticleSystem exhaust;
  boolean INPUT_up, INPUT_right, INPUT_left;
  color col;
  int UUID = -1;

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
    bd.position.set(box2d.coordPixelsToWorld(center));
    body = box2d.createBody(bd);

    body.createFixture(sd, 1.0);
    body.setUserData(this);
  }

  protected void killBody() {
    box2d.destroyBody(body);
  }

  int JET_OFFSET=5;

  // method to display the rocket 
  public void show() {
    Vec2 pos = box2d.getBodyPixelCoord(body);
    float a = body.getAngle();

    fill(col);
    noStroke();
    triangle(pos.x-7, pos.y-30, pos.x+7, pos.y-30, pos.x, pos.y-22);

    pushMatrix();
    translate(pos.x, pos.y);

    if (this.name != null) {
      fill(0);
      textSize(18);
      textAlign(CENTER, CENTER);
      rectMode(CENTER);
      text(name, 0, -43, 100, 30);
    }

    rotate(-a);
    fill(col);
    if (INPUT_right) {
      triangle(-5, -5-JET_OFFSET, -5, 5-JET_OFFSET, -random(10, 18), -JET_OFFSET);
    }
    if (INPUT_left) {
      triangle(5, -5-JET_OFFSET, 5, 5-JET_OFFSET, random(10, 18), -JET_OFFSET);
    }

    scale(1.0/10);
    rocketShape.setFill(col);
    rocketShape.setStroke(false);
    pushMatrix();
    translate(-rocketIcon.width/2, -rocketIcon.height/2);
    shape(rocketIcon);
    popMatrix();
    gamemode.decorate(this);
    popMatrix();

    exhaust.show(col);
  }

  // User interactions / arrow keys
  public void interactions() {
    Vec2 pos = box2d.getBodyPixelCoord(body);
    float angle = body.getAngle();

    if (pos.x > WIDTH) body.setTransform(box2d.coordPixelsToWorld(new Vec2(pos.x-WIDTH, pos.y)), angle);
    if (pos.x < 0) body.setTransform(box2d.coordPixelsToWorld(new Vec2(pos.x+WIDTH, pos.y)), angle);

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

class MyRocket extends Rocket {
  MyRocket(float x, float y) {
    super(x, y);
  }
  void setColor(color col) {
    GAME_COLOR_ = col;
    super.setColor(col);
  }
}
