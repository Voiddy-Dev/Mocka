// Main class for the Physics Object
public abstract class PhysObj {
  PVector pos, vel, acc; // posal physics
  float accRot, velRot, posRot; // Angular physics
  int mass; // mass of the rocket

  // Constructor for the rocket
  public PhysObj(PVector pos, int mass) {
    this.pos = pos;
    this.acc = new PVector(0, 0);
    this.vel = new PVector(0, 0);

    this.accRot = 0;
    this.velRot = 0;
    this.posRot = -PI/2;

    this.mass = mass;
  }

  // Applying the necessary force.
  public void applyForce(PVector force) {
    acc.add(force);
  }

  // Applying the necessary rotation.
  public void applyRot(float rotation) {
    accRot += rotation;
  }

  // Updating all the physics.
  public void update() {
    vel.add(acc); //<>//
    velRot += accRot;
    pos.add(vel);
    posRot += velRot;

    if (pos.x < 0) {
      vel.x *= -1;
      pos.x = 0;
    } 
    if (pos.x > terrain_values[2]) {
      vel.x *= -1;
      pos.x = terrain_values[2];
    }

    if (pos.y < 0) {
      vel.y *= -1;
      pos.y = 0;
    }

    if (pos.y > terrain_values[1]) {
      vel.y *= -1;
      pos.y = terrain_values[1];
    }

    acc.set(0, 0);
    accRot = 0;
  }
}
