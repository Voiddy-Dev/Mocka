color GAME_COLOR; // Random color that can be used throughout the code
int[] terrain_values = new int[4]; // rect values for the terrain

Rocket rock;

void setup() {
  size(1200, 800, FX2D);

  // create random color that could be used from here on out
  GAME_COLOR = color(random(0, 255), random(0, 255), random(0, 255));

  // setup terrain values
  terrain_values[0] = 0;
  terrain_values[1] = height-50;
  terrain_values[2] = width;
  terrain_values[3] = 100;

  setupBox2D();
  setupRocketBody();
  rock = new Rocket(width/2, height-80);
}

void draw() {
  background(255); // white background
  terrain(); // terrain

  // user interactions
  rock.interactions();
  box2d.step();

  // updating and displaying the rocket
  rock.update();
  rock.show();

  if (UUID != -1) send_udp_to_server();

  for (HashMap.Entry<Integer, Enemy> entry : enemies.entrySet()) {
    if (entry.getKey() != UUID) entry.getValue().update();
  }
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
  rect(terrain_values[0], terrain_values[1], terrain_values[2], terrain_values[3]);

  strokeWeight(5);
  stroke(0);
  //line(ppmouseX, ppmouseY, mouseX, mouseY);
}
