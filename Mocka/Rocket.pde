import processing.svg.*;

PShape rocket_icon;
PShape rocketBody;

float ROCKET_ICON_SCALE = 0.15;

void setupRocketBody() {
  rocket_icon = loadShape("rocket.svg");
  rocket_icon.scale(ROCKET_ICON_SCALE);

  rocketBody = createShape();
  rocketBody.beginShape();
  rocketBody.noFill();
  rocketBody.strokeWeight(0.1);
  rocketBody.stroke(GAME_COLOR);
  //rocketBody.vertex(0, POINT_HEIGHT);
  //rocketBody.vertex(LEGS_WIDTH, LEGS_HEIGHT);
  //rocketBody.vertex(-LEGS_WIDTH, LEGS_HEIGHT);
  rocketBody.vertex(-.6, -1.3);
  rocketBody.vertex(-.5, -1.5);
  rocketBody.vertex(0, -1.8);
  rocketBody.vertex(.5, -1.5);
  rocketBody.vertex(.6, -1.3);
  rocketBody.vertex(1.2, .7);
  rocketBody.vertex(.9, 1.8);
  rocketBody.vertex(-.9, 1.8);
  rocketBody.vertex(-1.2, .7);
  rocketBody.endShape(CLOSE);
  rocketBody.scale(10);
}

public class Rocket {
  float x, y;
  float angle;

  Body body; // Box2d body
  int size = 20;
  ParticleSystem exhaust;

  // Constructor of the Rocket.
  public Rocket(float x, float y) {
    this.x = x;
    this.y = y;

    exhaust = new ParticleSystem();
    makeBody(new Vec2(x, y));
  }

  void makeBody(Vec2 center) {
    // Define a polygon (this is what we use for a rectangle)
    PolygonShape sd = new PolygonShape();

    // Geometry of rocket body, imported from talky.io JS
    float rocketBodyMult = 30.0 * (10.0 / 36);
    PVector[] rocketBodyPoints = {
      new PVector(0, -1.8).mult(rocketBodyMult), // TIP
      //new PVector(.5, -1.5).mult(rocketBodyMult), //
      new PVector(.6, -1.3).mult(rocketBodyMult), // 
      new PVector(1.2, .7).mult(rocketBodyMult), // HIP
      new PVector(.9, 1.8).mult(rocketBodyMult), // RIGHT CORNER
      new PVector(-.9, 1.8).mult(rocketBodyMult), // LEFT  CORNER
      new PVector(-1.2, .7).mult(rocketBodyMult), // HIP
      new PVector(-.6, -1.3).mult(rocketBodyMult), //
      //new PVector(-.5, -1.5).mult(rocketBodyMult)  //
    };

    Vec2[] vertices = new Vec2[rocketBodyPoints.length];
    for (int i = 0; i < vertices.length; i++) {
      vertices[i] = box2d.vectorPixelsToWorld(new Vec2(rocketBodyPoints[i].x, rocketBodyPoints[i].y));
    }

    sd.set(vertices, vertices.length);

    // Define the body and make it from the shape
    BodyDef bd = new BodyDef();
    bd.type = BodyType.DYNAMIC;
    bd.position.set(box2d.coordPixelsToWorld(center));
    body = box2d.createBody(bd);

    body.createFixture(sd, 1.0);


    // Give it some initial random velocity
    //body.setLinearVelocity(new Vec2(random(-5, 5), random(2, 5)));
    //body.setAngularVelocity(random(-5, 5));
  }

  // method to display the rocket 
  public void show() {
    // We look at each body and get its screen position
    Vec2 pos = box2d.getBodyPixelCoord(body);
    // Get its angle of rotation
    float a = body.getAngle();

    Fixture f = body.getFixtureList();
    PolygonShape ps = (PolygonShape) f.getShape();


    rectMode(CENTER);
    pushMatrix();
    translate(pos.x, pos.y);
    rotate(-a);
    stroke(GAME_COLOR);
    strokeWeight(1);
    noFill();    
    beginShape();
    //println(vertices.length);
    // For every vertex, convert to pixel vector
    for (int i = 0; i < ps.getVertexCount(); i++) {
      Vec2 v = box2d.vectorWorldToPixels(ps.getVertex(i));
      vertex(v.x, v.y);
    }
    endShape(CLOSE);
    shape(rocket_icon, - ((rocket_icon.width * ROCKET_ICON_SCALE)/2), -((rocket_icon.height * ROCKET_ICON_SCALE)/2));
    popMatrix();

    ///////////////


    //if (up) {// If applying force update the exhaust
    //  PVector part_Pos = new PVector(pos.x - ((rocket_icon.width * ROCKET_ICON_SCALE)/2) * sin(posRot), 
    //    pos.y + ((rocket_icon.height * ROCKET_ICON_SCALE)/2) * cos(posRot));
    //  exhaust.turnOn(part_Pos, acc, vel);
    //}
    exhaust.update(GAME_COLOR);
  }

  // User interactions
  // Arrow keys
  public void interactions() {
    //if (up) {
    //  this.push(2.0*G);
    //} 
    //if (left) {
    //  this.applyTorque(-0.03);
    //} else if (right) {
    //  this.applyTorque(0.03);
    //}
  }

  // Pushing towards a direction.
  public void push(float force) {
    //applyForce(new PVector(force*sin(posRot), -force*cos(posRot)));
  }
}
