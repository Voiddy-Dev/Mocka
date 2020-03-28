float rocketBodyMult = 10;

PVector[] rocketBodyPoints = {
  new PVector(0, -1.8).mult(rocketBodyMult), // TIP
  new PVector(.5, -1.5).mult(rocketBodyMult), //
  new PVector(.6, -1.3).mult(rocketBodyMult), // 
  new PVector(1.2, .7).mult(rocketBodyMult), // HIP
  new PVector(.9, 1.8).mult(rocketBodyMult), // RIGHT CORNER
  new PVector(-.9, 1.8).mult(rocketBodyMult), // LEFT  CORNER
  new PVector(-1.2, .7).mult(rocketBodyMult), // HIP
  new PVector(-.6, -1.3).mult(rocketBodyMult), //
  new PVector(-.5, -1.5).mult(rocketBodyMult)  //
};

PShape rocketBodyShape;

void setupRocketBody() {
  rocketBodyShape = createShape();
  rocketBodyShape.beginShape();
  rocketBodyShape.noFill();
  rocketBodyShape.stroke(GAME_COLOR);
  for (PVector p : rocketBodyPoints) {
    rocketBodyShape.vertex(p.x, p.y);
  }
  rocketBodyShape.endShape(CLOSE);
  //rocketBody.scale(40);
}

public class Rocket extends PhysObj {
  int size = 20;

  // Constructor of the Rocket.
  public Rocket(float x, float y) {
    super(new PVector(x, y), 1);
  }

  // method to display the rocket 
  public void show() {
    stroke(GAME_COLOR);
    strokeWeight(1);
    noFill();    

    pushMatrix();
    translate(pos.x, pos.y);
    rotate(posRot);
    shape(rocketBodyShape);
    popMatrix();
  }

  // User interactions
  // Arrow keys
  public void interactions() {
    if (up) {
      this.push(2.0*G);
    } 
    if (left) {
      this.applyTorque(-0.03);
    } else if (right) {
      this.applyTorque(0.03);
    }
  }

  // Pushing towards a direction.
  public void push(float force) {
    applyForce(new PVector(force*sin(posRot), -force*cos(posRot)));
  }
}
