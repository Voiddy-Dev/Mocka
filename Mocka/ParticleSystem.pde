// Particle system class
public class ParticleSystem {
  // list of particles
  ArrayList<Particle> particles;

  // constructor with only the positino and the direction the particles
  // should go towards
  public ParticleSystem() {
    particles = new ArrayList();
  }

  public void turnOn(PVector pos, PVector init, PVector vel) {
    // create random particles
    for (int i = 0; i < 3; i ++) {
      particles.add(new Particle(pos, init, vel));
    }
  }

  //called everytime to update everything
  public void update(color c) {
    // go through every particle
    for (int i = particles.size()-1; i >= 0; i--) {
      Particle p = particles.get(i);

      // if it is supposed to die or its out of bounds kill it
      if (p.getLifespan() <= 0 || p.outOfBounds()) {
        particles.remove(i); // death to particle
      } else {
        p.reduceLife(); // otherwise reduce its lifespan

        p.update(c);
      }
    }
  }
}

// Single particle in the particle effect system
public class Particle {
  private int lifespan;
  // MIN AND MAX LIFESPAN
  int MIN_LIFESPAN = 35;
  int MAX_LIFESPAN = 85;

  //size of the particles for some interesting modifiers
  int size_of_particle, max_size;

  PVector pos, vel, acc;

  // spread for randomness of new particles
  float around_value = QUARTER_PI;

  //constructor of Particle
  public Particle(PVector start, PVector init, PVector velocity) {
    this.lifespan = (int) random(MIN_LIFESPAN, MAX_LIFESPAN);

    size_of_particle = (int) random(10, 20);
    max_size = size_of_particle;

    this.pos = start.copy();
    this.acc = init.copy();
    // random spread so that not all particles are agglutinated
    this.vel = velocity.copy();

    //randomness spread
    PVector random_downwards = new PVector(random(this.acc.x - around_value, this.acc.x + around_value), 
      random(this.acc.y - around_value, this.acc.y + around_value));  
    this.acc.add(random_downwards.mult(0.05));
  }

  public int getLifespan() {
    return lifespan;
  }

  public void reduceLife() {
    if (lifespan > 0) lifespan--;
  }

  //checking if particle system is out of bounds or not
  public boolean outOfBounds() {
    return false; 
    //(pos.x > terrain_values[2]) || (pos.x < terrain_values[0]) || (pos.y > terrain_values[1]) || (pos.y < 0);
  }

  // method to update the particle 
  // will change the size
  public void update(color c) {
    // physics stuff
    vel.add(acc);
    pos.add(vel);

    // display the particle - in accordance to its lifespan
    noStroke();
    fill(c, map(this.getLifespan(), 0, MAX_LIFESPAN, 0, 255));
    ellipse(pos.x, pos.y, size_of_particle, size_of_particle);
    if (size_of_particle > 0) {
      size_of_particle = (int) map(lifespan, 0, MAX_LIFESPAN, 0, max_size);
    }
  }
}
