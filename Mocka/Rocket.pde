PShape rocketBody;

void setupRocketBody() {
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

public class Rocket extends PhysObj {
  int size = 20;
  ParticleSystem exhaust;

  // Constructor of the Rocket.
  public Rocket(float x, float y) {
    super(new PVector(x, y), 1);

    exhaust = new ParticleSystem();
  }

  // method to display the rocket 
  public void show() {
    stroke(GAME_COLOR);
    strokeWeight(1);
    noFill();    

    if (up) {
      PVector thrust = new PVector(vel.x*sin(posRot), -vel.y*cos(posRot));
      PVector part_Pos = new PVector(pos.x, pos.y + ((rocket_icon.height * 0.15)/2) * cos(posRot));
      exhaust.turnOn(part_Pos, thrust);
    }
    exhaust.update();

    pushMatrix();
    translate(pos.x, pos.y);
    rotate(posRot);
    shape(rocketBody);
    shape(rocket_icon, -((rocket_icon.width*0.15)/2), -((rocket_icon.height * 0.15)/2));
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
