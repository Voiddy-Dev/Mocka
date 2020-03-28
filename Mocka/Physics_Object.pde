// Main class for the Physics Object //<>//
public abstract class PhysObj {
  PVector pos, vel, acc; // posal physics
  float accRot, velRot, posRot; // Angular physics
  float mass; // mass of the rocket
  float angularMass; // AKA moment of inertia
  float G = 0.08; // gravity value

  // Constructor for the rocket
  public PhysObj(PVector pos, int mass) {
    this.pos = pos;
    this.acc = new PVector(0, 0);
    this.vel = new PVector(0, 0);

    this.accRot = 0;
    this.velRot = 0;
    this.posRot = 0;

    this.mass = mass;
    this.angularMass = 70.0;
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
    //applyForce(new PVector(0, G));

    int num_collisions = 0;
    for (int i = 0; i < ROCKET_BODY_POINTS; i++) {
      num_collisions += pointCollides(rocketBodyPoints[i].x, rocketBodyPoints[i].y, rocketBodyPointsPolar[i].x, rocketBodyPointsPolar[i].y);
    }

    for (int i = 0; i < ROCKET_BODY_POINTS; i++) {
      pointCollision(num_collisions, rocketBodyPoints[i].x, rocketBodyPoints[i].y, rocketBodyPointsPolar[i].x, rocketBodyPointsPolar[i].y);
    }

    if (num_collisions > 1) {
      //applyForce(new PVector(0, -G));
      //accRot -= velRot * 0.01;
    }

    //applyForceAbsolute(ppmouseX, ppmouseY, mouseX-ppmouseX, mouseY-ppmouseY);
    float point_ax = pos.x + cos(posRot)*rocketBodyPoints[0].x - sin(posRot)*rocketBodyPoints[0].y;
    float point_ay = pos.y + sin(posRot)*rocketBodyPoints[0].x + cos(posRot)*rocketBodyPoints[0].y;
    float mult = 0.001;
    applyForceAbsolute(point_ax, point_ay, (mouseX-point_ax)*mult, (mouseY-point_ay)*mult);

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
    velRot *= 0.98;

    // reset all the vectors
    acc.set(0, 0);
    accRot = 0;
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

      applyForceAbsolute(apx, apy, -avx * mass * 1, -avy * mass * 1.5);
      pos.y = min(pos.y, pos.y - apy + GROUND);
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
    applyTorque(dotprod / rfr);

    dotprod = (rfx*rpx + rfy*rpy)/sq(rfr);
    applyForce(new PVector(rpx_*dotprod, rpy_*dotprod));

    stroke(255, 0, 0);
    strokeWeight(2);
    noFill();    
    pushMatrix();
    translate(pos.x, pos.y);
    rotate(posRot);
    line(rpx, rpy, rpx+rfx*100, rpy+rfy*100);
    popMatrix();
  }
}
