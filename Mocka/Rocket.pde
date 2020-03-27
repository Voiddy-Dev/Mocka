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

    line(0, POINT_HEIGHT, LEGS_WIDTH, LEGS_HEIGHT);
    line(LEGS_WIDTH, LEGS_HEIGHT, -LEGS_WIDTH, LEGS_HEIGHT);
    line(-LEGS_WIDTH, LEGS_HEIGHT, 0, POINT_HEIGHT);

    popMatrix();
  }

  // User interactions
  // Arrow keys
  public void interactions() {
    if (up) {
      this.push(1.9*G);
    } 
    if (left) {
      this.applyTorque(-0.0024);
    } else if (right) {
      this.applyTorque(0.0024);
    }
  }

  // Pushing towards a direction.
  public void push(float force) {
    applyForce(new PVector(force*sin(posRot), -force*cos(posRot)));
  }
}
