import java.util.Map;

color GAME_COLOR; // Random color that can be used throughout the code

MyRocket myRocket;

void setup() {
  size(120, 80, FX2D);
  //size(1200, 800, FX2D);

  setupBox2D();

  setupNetworking();

  // create random color that could be used from here on out
  GAME_COLOR = color(random(0, 255), random(0, 255), random(0, 255));

  setupTerrain();

  setupRocketBody();
  myRocket = new MyRocket(width/2, height-80);
}

void draw() {
  updateNetwork();

  background(255); // white background
  showTerrain(); // terrain

  // user interactions
  myRocket.interactions();
  box2d.step();

  // updating and displaying the rocket
  //rock.update();
  myRocket.show();
  showEnemies();

  //for (HashMap.Entry<Integer, Enemy> entry : enemies.entrySet()) {
  //  if (entry.getKey() != UUID) entry.getValue().update();
  //}
}
