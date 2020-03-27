// Main class for the Physics Object //<>//
public abstract class PhysObj {
  PVector pos, vel, acc; // posal physics
  float accRot, velRot, posRot; // Angular physics
  int mass; // mass of the rocket
  float G = 0.5; // gravity value

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
    //Gravity
    applyForce(new PVector(0, G));

    vel.add(acc);
    velRot += accRot;
    pos.add(vel);
    posRot += velRot;

    // Make it wrap around in X
    if (pos.x < terrain_values[0]) {
      pos.x = terrain_values[2];
    } 
    if (pos.x > terrain_values[2]) {
      pos.x = terrain_values[0];
    }

    // if object touches the terrain make it bounce a little
    if (pos.y > terrain_values[1]) {
      vel.y *= -0.5; // making it bounce a bit
      pos.y = terrain_values[1];
    }

    // drag
    vel.mult(0.97);
    velRot *= 0.97;

    // reset all the vectors
    acc.set(0, 0);
    accRot = 0;
  }
}
