import hypermedia.net.*;
import processing.net.*;

color GAME_COLOR; // Random color that can be used throughout the code
int[] terrain_values = new int[4]; // rect values for the terrain

Rocket rock;
PShape rocket_icon;

float ROCKET_ICON_SCALE = 0.15;

int UUID = -1;

void setup() {
  size(1200, 800);

  // create random color that could be used from here on out
  GAME_COLOR = color(random(0, 255), random(0, 255), random(0, 255));

  // setup terrain values
  terrain_values[0] = 0;
  terrain_values[1] = height-50;
  terrain_values[2] = width;
  terrain_values[3] = 100;

  //setting up rockets
  setupRocketBody();
  rock = new Rocket(width/2, height-80);
  rocket_icon = loadShape("rocket.svg");
  rocket_icon.scale(ROCKET_ICON_SCALE);

  // setting up 
  client = new Client(this, "127.0.0.1", 25567);

  // create a new datagram connection on port 6100
  // and wait for incomming message
  udp = new UDP( this, 6100 );
  //udp.log( true );     // <-- printout the connection activity
  udp.listen( true );
}

void draw() {
  // Basic ui
  background(255); // white background
  terrain(); // terrain

  // user interactions
  rock.interactions();

  // updating and displaying the rocket
  rock.update();
  rock.show();

  if (UUID != -1) send_udp_to_server();

  for (final HashMap.Entry<Integer, Enemy> entry : enemies.entrySet()) {
    (new Thread() {
      public void run() {
        entry.getValue().update();
      }
    }
    ).start();
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
