PShape rocketBody;

void setupRocketBody() {
  rocketBody = createShape();
  rocketBody.beginShape();
  rocketBody.noFill();
  rocketBody.stroke(GAME_COLOR);
  rocketBody.vertex(0, POINT_HEIGHT);
  rocketBody.vertex(LEGS_WIDTH, LEGS_HEIGHT);
  rocketBody.vertex(-LEGS_WIDTH, LEGS_HEIGHT);
  rocketBody.endShape(CLOSE);
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
    shape(rocketBody);
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
