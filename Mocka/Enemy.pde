public class Enemy {
  color ENEMY_COLOR;
  int UUID, sup;

  PShape bod;

  float x = -100, y = -1, ang = -1;
  float acc_x = -1, acc_y = -1;
  float vel_x = -1, vel_y = -1;

  ParticleSystem exhaust;

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

    exhaust = new ParticleSystem();
  }

  void setValues(float x, float y, float ang, int sup, float acc_x, float acc_y, float vel_x, float vel_y) {
    this.x = x;
    this.y = y;
    this.ang = ang;
    this.sup = sup;
    this.acc_x = acc_x;
    this.acc_y = acc_y;
    this.vel_x = vel_x;
    this.vel_y = vel_y;
  }

  void update() {
    if (x != -100) {
      pushMatrix();
      translate(x, y);
      rotate(ang);
      shape(rocket_icon, - ((rocket_icon.width * ROCKET_ICON_SCALE)/2), -((rocket_icon.height * ROCKET_ICON_SCALE)/2));
      popMatrix();
    }

    if (sup == 0) {// If applying force update the exhaust
      PVector part_Pos = new PVector(x - ((rocket_icon.width * ROCKET_ICON_SCALE)/2) * sin(ang), 
        y + ((rocket_icon.height * ROCKET_ICON_SCALE)/2) * cos(ang));
      exhaust.turnOn(part_Pos, new PVector(this.acc_x, this.acc_y), new PVector(this.vel_x, this.vel_y));
    }

    exhaust.update(ENEMY_COLOR);
  }
}
