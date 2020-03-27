// Main class for the Rocket
public class Rocket extends PhysObj {
  int size = 20;

  // Constructor of the Rocket.
  public Rocket(float x, float y) {
    super(new PVector(x, y), 30);
  }

  // method to display the rocket 
  public void show() {
    strokeWeight(5);
    stroke(GAME_COLOR);
    float topPointx = size*cos(posRot) + pos.x;
    float topPointy = size*sin(posRot) + pos.y;

    line(topPointx, topPointy, pos.x, pos.y);

    strokeWeight(1);
    noFill();
    rectMode(CENTER);
    rect(pos.x, pos.y, size * 2, size * 2);
  }

  // User interactions
  // Arrow keys
  public void interactions() {
    if (up) {
      this.push(0.7);
    } 
    if (left) {
      this.applyRot(-0.003);
    } else if (right) {
      this.applyRot(0.003);
    }
  }

  // Pushing towards a direction.
  public void push(float force) {
    applyForce(new PVector(force*cos(posRot), force*sin(posRot)));
  }
}
