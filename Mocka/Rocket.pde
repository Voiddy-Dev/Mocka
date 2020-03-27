// GEOMETRY PARAMS for all rockets
/** Position correspond to COM (center of mass)
 * All other attributes of the ship (hit points) are
 * given with respect to the COM. */
//float

// PHYSICS PARAMS for all rockets

float THRUST_VECTORING_MAXIMUM_DEFLECTION_ANGLE = radians(10);

public class Rocket extends PhysObj {
  int size = 20;

  // Constructor of the Rocket.
  public Rocket(float x, float y) {
    super(new PVector(x, y), 1);
  }

  // method to display the rocket 
  public void show() {
    strokeWeight(5);
    stroke(GAME_COLOR);

    //float topPointx = size*cos(posRot) + pos.x;
    //float topPointy = size*sin(posRot) + pos.y;
    //line(topPointx, topPointy, pos.x, pos.y);
    pushMatrix();
    translate(pos.x, pos.y);
    rotate(posRot);
    line(0, 0, size, 0);

    strokeWeight(1);
    noFill();
    rectMode(CENTER);
    rect(0, 0, size * 2, size * 2);
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
    applyForce(new PVector(force*cos(posRot), force*sin(posRot)));
  }
}
