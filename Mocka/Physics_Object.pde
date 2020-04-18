float TIME_DELTA = 10.0 / 60;  //<>//

// Main class for the Physics Object
public abstract class PhysObj {
  PVector pos, vel, acc; // posal physics
  float accRot, velRot, posRot; // Angular physics
  float mass; // mass of the rocket
  float angularMass; // AKA moment of inertia
  float G = 0.13; // gravity value

  // Constructor for the rocket
  public PhysObj(PVector pos, int mass) {
    this.pos = pos;
    this.vel = new PVector(0, 0);
    this.acc = new PVector(0, 0);

    this.accRot = 0;
    this.velRot = 0;
    this.posRot = 0;

    this.mass = mass;
    this.angularMass = 300.0;

    for (int i = 0; i < ROCKET_BODY_POINTS; i++) pointCoordsAbsolute[i] = new PVector(0, 0);
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
  public void step() {
    doCollisions();

    //Gravity
    applyForce(new PVector(0, G));

    vel.add(acc.mult(TIME_DELTA));
    velRot += accRot * TIME_DELTA;
    pos.add(PVector.mult(vel, TIME_DELTA));
    posRot += velRot * TIME_DELTA;

    // drag
    //vel.mult(0.995);
    //velRot *= 0.997;

    // reset acceleration
    acc.set(0, 0);
    accRot = 0;

    // Make it wrap around in X
    if (pos.x < terrain_values[0]) {
      pos.x = terrain_values[2];
    } 
    if (pos.x > terrain_values[2]) {
      pos.x = terrain_values[0];
    }
  }

  boolean[] pointCollides = new boolean[ROCKET_BODY_POINTS];
  PVector[] pointCoordsAbsolute = new PVector[ROCKET_BODY_POINTS];

  void doCollisions() {
    int num_collisions = 0;
    for (int i = 0; i < ROCKET_BODY_POINTS; i++) {
      // Compute absolute positions of body points for this current pos & posRot
      pointCoordsAbsolute[i].x = pos.x + cos(posRot) * rocketBodyPoints[i].x - sin(posRot) * rocketBodyPoints[i].y;
      pointCoordsAbsolute[i].y = pos.y + sin(posRot) * rocketBodyPoints[i].x + cos(posRot) * rocketBodyPoints[i].y;
      //
      boolean collides = doesPointCollide(i);
      pointCollides[i] = collides;
      if (collides) num_collisions++;
    }

    PVector newPos = pos.copy();
    // Collisions should make do a bounce
    for (int i = 0; i < ROCKET_BODY_POINTS; i++) if (pointCollides[i]) {
      pointCollisionBounce(newPos, num_collisions, i);
    }
    //newPos.y += 0.1;

    pos = newPos;

    ///////////////////

    //applyForceAbsolute(ppmouseX, ppmouseY, mouseX-ppmouseX, mouseY-ppmouseY);
    //int indx = (frameCount/30)%ROCKET_BODY_POINTS;
    //int indx = 3;
    //PVector force = new PVector(mouseX, mouseY).sub(pointCoordsAbsolute[indx]).mult(0.001);
    //applyForce(rocketBodyPoints[indx], rocketBodyPointsPolar[indx], pointCoordsAbsolute[indx], force);
  }

  boolean doesPointCollide(int i) {
    float apx = pointCoordsAbsolute[i].x;
    float apy = pointCoordsAbsolute[i].y;
    stroke(0);
    strokeWeight(1);
    noFill();
    //ellipse(apx, apy, 10, 10);
    float GROUND = terrain_values[1];
    return apy > GROUND;
  }

  void pointCollisionBounce(PVector newPos, int num_collisions, int i) {
    //float rpx = rocketBodyPoints[i].x;
    //float rpy = rocketBodyPoints[i].y;
    float rpphi = rocketBodyPointsPolar[i].x;
    float rpr   = rocketBodyPointsPolar[i].y;

    float GROUND = terrain_values[1];

    // Absolute velocities
    float avx = vel.x - sin(posRot + rpphi) * rpr * velRot / num_collisions;
    float avy = vel.y + cos(posRot + rpphi) * rpr * velRot / num_collisions;

    stroke(255, 0, 0);
    pushMatrix();
    translate(pointCoordsAbsolute[i].x, pointCoordsAbsolute[i].y); 
    line(0, 0, avx*100, avy*100);
    popMatrix();

    float fact = 2.0;
    //applyForceAbsolute___(pointCoordsAbsolute[i], new PVector(-avx * mass * fact, -avy * mass * fact));
    PVector force = new PVector(-avx * mass, -avy * mass).mult(fact).mult(1.0/num_collisions);
    applyForce(rocketBodyPoints[i], rocketBodyPointsPolar[i], pointCoordsAbsolute[i], force);
    newPos.y = min(newPos.y, newPos.y - pointCoordsAbsolute[i].y + GROUND);
  }

  void applyForce(PVector relativePoint, PVector relativePointPolar, PVector absolutePoint, PVector absoluteForce) {

    stroke(0, 255, 0);
    pushMatrix();
    translate(absolutePoint.x, absolutePoint.y);
    line(0, 0, absoluteForce.x*100, absoluteForce.y*100);
    popMatrix();

    PVector relativeForce = (absoluteForce.copy()).rotate(-posRot);
    float deltaAngle = relativeForce.heading() - relativePointPolar.x;

    //absoluteForce.mult(0.5);
    applyForce(absoluteForce);
    //applyForce(PVector.mult(relativePoint, PVector.dot(relativePoint, relativeForce) / relativePoint.magSq()).rotate(posRot));

    float torque = relativeForce.mag() * relativePointPolar.y * sin(deltaAngle);
    //relativeForce.rotate(-HALF_PI);
    //float torque = relativeForce.dot(relativePoint);
    applyTorque(torque / 60.);
  }
}

// From this tutorial
// https://gamedevelopment.tutsplus.com/tutorials/how-to-create-a-custom-2d-physics-engine-oriented-rigid-bodies--gamedev-8032

float crossProduct(PVector a, PVector b) {
  return a.x * b.y - a.y * b.x;
}

PVector CrossProduct(PVector a, float s) {
  return new PVector(s * a.y, -s * a.x);
}

PVector CrossProduct(float s, PVector b) {
  return new PVector(-s * b.y, s * b.x);
}
