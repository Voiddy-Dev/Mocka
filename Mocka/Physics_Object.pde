// GEOMETRY PARAMS for all rockets //<>//
/** Position correspond to COM (center of mass)
 * All other attributes of the ship (hit points) are
 * given with respect to the COM. */

float LEGS_HEIGHT = 20;
float LEGS_WIDTH = 13; // measured in x displacement from COM
float POINT_HEIGHT = -25; // from COM
// (so half of distance between the two legs)

// Main class for the Physics Object //<>//
public abstract class PhysObj {
  PVector pos, vel, acc; // posal physics
  float accRot, velRot, posRot; // Angular physics
  float mass; // mass of the rocket
  float angularMass; // AKA moment of inertia
  float G = 0.23; // gravity value

  // Constructor for the rocket
  public PhysObj(PVector pos, int mass) {
    this.pos = pos;
    this.acc = new PVector(0, 0);
    this.vel = new PVector(0, 0);

    this.accRot = 0;
    this.velRot = 0;
    this.posRot = 0;

    this.mass = mass;
    this.angularMass = 1.0;
  }

  // Applying the necessary force.
  public void applyForce(PVector force) {
    acc.add(PVector.div(force, mass));
  }

  // Applying the necessary rotation.
  public void applyTorque(float torque) {
    accRot += torque/angularMass;
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

    /*
    // if object touches the terrain make it bounce a little
     if (pos.y > terrain_values[1]) {
     vel.y *= -0.5; // making it bounce a bit
     pos.y = terrain_values[1];
     }
     */


    // drag
    vel.mult(0.997);
    velRot *= 0.997;

    // reset all the vectors
    acc.set(0, 0);
    accRot = 0;
  }
}
