// Geometry of rocket body

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

PVector[] rocketBodyPointsPolar;
int ROCKET_BODY_POINTS = rocketBodyPoints.length;

PShape rocketBodyShape;

void setupRocketBody() {
  // Compute polar coordinates for rocket body points
  rocketBodyPointsPolar = new PVector[rocketBodyPoints.length]; 
  for (int i = 0; i < ROCKET_BODY_POINTS; i++) {
    PVector p = rocketBodyPoints[i];
    float phi = atan2(p.y, p.x);
    float r = p.mag();
    rocketBodyPointsPolar[i] = new PVector(phi, r);
  }

  // Create PSHape
  rocketBodyShape = createShape(); 
  rocketBodyShape.beginShape(); 
  rocketBodyShape.noFill(); 
  rocketBodyShape.stroke(GAME_COLOR); 
  for (PVector p : rocketBodyPoints) rocketBodyShape.vertex(p.x, p.y); 
  rocketBodyShape.endShape(CLOSE);
}

public class Rocket extends PhysObj {
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

    for (PVector p : rocketBodyPointsPolar) {
      pushMatrix();
      rotate(p.x);
      translate(p.y, 0);
      stroke(0);
      point(0, 0);
      popMatrix();
    }

    popMatrix();
  }

  // User interactions
  // Arrow keys
  public void interactions() {
    if (up) {
      this.push(2.1*G);
    } 
    if (left) {
      this.applyTorque(-1.0);
    } else if (right) {
      this.applyTorque(1.0);
    }
  }

  // Pushing towards a direction.
  public void push(float force) {
    applyForce(new PVector(force*sin(posRot), -force*cos(posRot)));
  }
}
