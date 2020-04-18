color GAME_COLOR; // Random color that can be used throughout the code
int[] terrain_values = new int[4]; // rect values for the terrain

Rocket rock;
ParticleSystem partSys;

void setup() {
  size(600, 400, FX2D);
  //frameRate(6);

  // create random color that could be used from here on out
  GAME_COLOR = color(random(0, 255), random(0, 255), random(0, 255));

  // setup terrain values
  terrain_values[0] = 0;
  terrain_values[1] = height-50;
  terrain_values[2] = width;
  terrain_values[3] = 100;

  setupRocketBody();
  rock = new Rocket(width/2, height-400);
  //frameRate(2);
  partSys = new ParticleSystem(new PVector(width/2, height/2), new PVector(0, -1));

  platforms.add(new Platform(250, 200));
}

void draw() {
  TIME_DELTA = map(mouseX, 0, width, 1.0/60, 1);

  // Basic ui
  background(255); // white background
  // user interactions
  rock.interactions();

  // step physics simulation of the rocket
  rock.step();

  terrain(); // terrain
  rock.show();

  // updating the particle system
  //partSys.update();

  //for (Platform p : platforms) p.show();
}

/**
 * Method to create the terrain.
 * Box at the bottom of the screen.
 */
void terrain() {
  noStroke();
  fill(GAME_COLOR);

  rectMode(CORNER);
  // Simple small rectangle at the bottom of the screen
  //rect(terrain_values[0], terrain_values[1], terrain_values[2], terrain_values[3]);

  strokeWeight(5);
  stroke(0);
  //line(ppmouseX, ppmouseY, mouseX, mouseY);
}
