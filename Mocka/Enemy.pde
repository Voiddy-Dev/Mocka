public class Enemy {
  color ENEMY_COLOR;
  int UUID;

  PShape bod;

  float x = -100, y = -1, ang = -1;

  void setupEnemyBody() {
    bod = createShape();
    bod.beginShape();
    bod.noStroke();
    bod.fill(ENEMY_COLOR);
    bod.vertex(-.6, -1.3);
    bod.vertex(-.5, -1.5);
    bod.vertex(0, -1.8);
    bod.vertex(.5, -1.5);
    bod.vertex(.6, -1.3);
    bod.vertex(1.2, .7);
    bod.vertex(.9, 1.8);
    bod.vertex(-.9, 1.8);
    bod.vertex(-1.2, .7);
    bod.endShape(CLOSE);
    bod.scale(10);
  }

  public Enemy(int UUID) {
    ENEMY_COLOR = color(random(0, 255), random(0, 255), random(0, 255));
    setupEnemyBody();

    this.UUID = UUID;
  }

  void setValues(float x, float y, float ang) {
    this.x = x;
    this.y = y;
    this.ang = ang;
  }

  void update() {
    if (x != -100) {
      pushMatrix();
      translate(x, y);
      rotate(ang);
      shape(bod);
      popMatrix();
    }
  }
}
