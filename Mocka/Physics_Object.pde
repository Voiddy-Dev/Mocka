// GEOMETRY PARAMS for all rockets //<>// //<>//
/** Position correspond to COM (center of mass)
 * All other attributes of the ship (hit points) are
 * given with respect to the COM. */

float LEGS_HEIGHT = 20;
float LEGS_WIDTH = 13; // measured in x displacement from COM
float POINT_HEIGHT = -25; // from COM
float LEGS_COM_DIST = sqrt(sq(LEGS_HEIGHT) + sq(LEGS_WIDTH));
float LEGS_ANG_FROM_VERT = atan2(LEGS_HEIGHT, LEGS_WIDTH);
// (so half of distance between the two legs)

// Main class for the Physics Object
public abstract class PhysObj {
  PVector pos, vel, acc; // posal physics
  float accRot, velRot, posRot; // Angular physics
  float mass; // mass of the rocket
  float angularMass; // AKA moment of inertia
  float G = 0.3; // gravity value

  // Constructor for the rocket
  public PhysObj(PVector pos, int mass) {
    this.pos = pos;
    this.acc = new PVector(0, 0);
    this.vel = new PVector(0, 0);

    this.accRot = 0;
    this.velRot = 0;
    this.posRot = 0;

    this.mass = mass;
    this.angularMass = 15.0;
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
    applyForce(new PVector(0, G*0.2));

    int num_collisions = 
      pointCollides(0, POINT_HEIGHT, -POINT_HEIGHT, 0)
      + pointCollides(LEGS_WIDTH, LEGS_HEIGHT, LEGS_COM_DIST, PI - LEGS_ANG_FROM_VERT)
      + pointCollides(-LEGS_WIDTH, LEGS_HEIGHT, LEGS_COM_DIST, PI + LEGS_ANG_FROM_VERT);

    pointCollision(num_collisions, 0, POINT_HEIGHT, -POINT_HEIGHT, 0);
    pointCollision(num_collisions, LEGS_WIDTH, LEGS_HEIGHT, LEGS_COM_DIST, PI - LEGS_ANG_FROM_VERT);
    pointCollision(num_collisions, -LEGS_WIDTH, LEGS_HEIGHT, LEGS_COM_DIST, PI + LEGS_ANG_FROM_VERT); 

    if (num_collisions > 0) {
      applyForce(new PVector(0, -G));
    }

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
    //vel.mult(0.995);
    //velRot *= 0.95;

    // reset all the vectors
    acc.set(0, 0);
    accRot = 0;

    //applyForceAbsolute(ppmouseX, ppmouseY, mouseX-ppmouseX, mouseY-ppmouseY);
    float point_ax = pos.x - sin(posRot)*POINT_HEIGHT;
    float point_ay = pos.y + cos(posRot)*POINT_HEIGHT;
    //applyForceAbsolute(point_ax, point_ay, mouseX-point_ax, mouseY-point_ay);
  }

  int pointCollides(float rpx, float rpy, float rpr, float rpphi) {
    // r means position specified relative to ship
    float apx = pos.x + cos(posRot) * rpx - sin(posRot) * rpy;
    float apy = pos.y + cos(posRot) * rpy + sin(posRot) * rpx;
    stroke(0);
    strokeWeight(1);
    noFill();
    //ellipse(apx, apy, 10, 10);
    float GROUND = terrain_values[1];
    if (apy > GROUND) return 1;
    else return 0;
  }

  void pointCollision(int num_collisions, float rpx, float rpy, float rpr, float rpphi) {
    // r means position specified relative to ship
    float apx = pos.x + cos(posRot) * rpx - sin(posRot) * rpy;
    float apy = pos.y + cos(posRot) * rpy + sin(posRot) * rpx;
    stroke(0);
    strokeWeight(1);
    noFill();
    //ellipse(apx, apy, 10, 10);
    float GROUND = terrain_values[1];
    if (apy > GROUND) {
      // Absolute velocities
      float avx = vel.x + cos(posRot + rpphi) * rpr * velRot / num_collisions;
      float avy = vel.y + sin(posRot + rpphi) * rpr * velRot / num_collisions;

      // 3600 somehow magically comes from FPS squared
      applyForceAbsolute(apx, apy, 0.4 * -avx * mass * 3600, -avy * mass * 3600);
      //pos.y--;
      pos.y = min(pos.y, pos.y - apy + GROUND);
      //applyForce(new PVector(0, -G));
      //applyForceAbsolute(apx, apy, avx * mass * 10, avy * mass * 10);
      //applyForceAbsolute(apx, apy, mouseX-apx, mouseY-apy);
    }
  }

  void applyForceAbsolute(float apx, float apy, float afx, float afy) {
    // helpers
    float rpx_ = apx - pos.x;
    float rpy_ = apy - pos.y;
    // Relative origin of where the force is being applied
    float rpx = cos(posRot) * rpx_ + sin(posRot) * rpy_;
    float rpy =-sin(posRot) * rpx_ + cos(posRot) * rpy_;
    // Relative direction of force application
    float rfx = cos(posRot) * afx + sin(posRot) * afy;
    float rfy =-sin(posRot) * afx + cos(posRot) * afy;

    // dist from COM to center of force application
    float rfr = sqrt(rpx*rpx + rpy*rpy);

    float dotprod = rfy * rpx - rfx * rpy;
    applyTorque(0.0001 * dotprod / rfr);

    dotprod = 0.0001*(rfx*rpx + rfy*rpy)/sq(rfr);
    applyForce(new PVector(rpx_*dotprod, rpy_*dotprod));

    stroke(255, 0, 0);
    strokeWeight(2);
    noFill();    
    pushMatrix();
    translate(pos.x, pos.y);
    rotate(posRot);
    //line(rpx, rpy, rpx+rfx, rpy+rfy);
    popMatrix();
  }
}
