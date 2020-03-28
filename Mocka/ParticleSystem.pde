// Particle system class
public class ParticleSystem {
  // list of particles
  ArrayList<Particle> particles;

  // constructor with only the positino and the direction the particles
  // should go towards
  public ParticleSystem() {
    //    // create 20 original particles
    //    this.particles = new ArrayList();
    //    for (int i = 0; i < 20; i++) {
    //      Particle new_one = new Particle(pos, init);
    //      particles.add(new_one);
    //    }
    particles = new ArrayList();
  }

  public void turnOn(PVector pos, PVector init) {
    // create random particles
    particles.add(new Particle(pos, init));
  }

  //called everytime to update everything
  public void update() {
    // go through every particle
    for (int i = particles.size()-1; i >= 0; i--) {
      Particle p = particles.get(i);

      // if it is supposed to die or its out of bounds kill it
      if (p.getLifespan() <= 0 || p.outOfBounds()) {
        particles.remove(i); // death to particle
      } else {
        p.reduceLife(); // otherwise reduce its lifespan

        p.update(); // and update it
      }
    }
  }
}

// Single particle in the particle effect system
public class Particle {
  private int lifespan;
  // MIN AND MAX LIFESPAN
  int MIN_LIFESPAN = 50;
  int MAX_LIFESPAN = 125;

  //size of the particles for some interesting modifiers
  int size_of_particle;

  PVector pos, vel, acc;

  // spread for randomness of new particles
  float around_value = QUARTER_PI;

  //constructor of Particle
  public Particle(PVector start, PVector init) {
    this.lifespan = (int) random(MIN_LIFESPAN, MAX_LIFESPAN);

    size_of_particle = (int) random(5, 15);

    this.pos = start.copy();
    this.acc = init.copy();
    // random spread so that not all particles are agglutinated
    this.vel = new PVector(random(acc.x - around_value, acc.x + around_value), 
      random(acc.y - around_value, acc.y + around_value));
    // SLOW THE FUCK DOWN M8
    this.acc.mult(0.2);
  }

  public int getLifespan() {
    return lifespan;
  }

  public void reduceLife() {
    if (lifespan > 0) lifespan--;
  }

  //checking if particle system is out of bounds or not
  public boolean outOfBounds() {
    return (pos.x > terrain_values[2]) || (pos.x < terrain_values[0]) ||
      (pos.y > terrain_values[1]) || (pos.y < 0);
  }

  // method to update the particle 
  public void update() {
    // physics stuff
    vel.add(acc);
    pos.add(vel);

    // display the particle - in accordance to its lifespan
    noStroke();
    fill(0, map(this.getLifespan(), 0, 200, 0, 255));
    ellipse(pos.x, pos.y, size_of_particle, size_of_particle);
  }
}
