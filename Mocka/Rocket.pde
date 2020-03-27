// Main class for the Rocket
public class Rocket extends PhysObj {
  int size = 20;

  // Constructor of the Rocket.
  public Rocket(float x, float y) {
    super(new PVector(x, y), 50);
  }

  public void show() {
    strokeWeight(5);
    stroke(GAME_COLOR);
    float topPointx = size*cos(posRot) + pos.x;
    float topPointy = size*sin(posRot) + pos.y;

    line(topPointx, topPointy, pos.x, pos.y);

    strokeWeight(1);
    noFill();
    rectMode(CENTER);
    rect(pos.x, pos.y, size* 2, size * 2);
  }
}
