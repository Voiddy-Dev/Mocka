import java.util.Map;

color GAME_COLOR; // Random color that can be used throughout the code

MyRocket myRocket;

void setup() {
  //size(120, 80, FX2D);
  //size(1200, 800, FX2D);
  //size(480, 320, FX2D);
  size(960, 640, FX2D);

  rocketShape = createRocketShape();

  setupBox2D();

  setupNetworking();

  myRocket = new MyRocket(width/2, height-80);
  randomRocketColor();
}

void draw() {
  //if (frameCount % 60 == 0) {
  //  myRocket.killBody();
  //  myRocket = new MyRocket(width * MY_UUID / 256., height/2);
  //}
  updateNetwork();

  myRocket.interactions();
  updateEnemies();
  box2d.step();
  informEnemies();

  background(255); // white background
  // updating and displaying the rocket
  //rock.update();
  myRocket.show();
  showEnemies();

  showTerrain(); // terrain

  //for (HashMap.Entry<Integer, Enemy> entry : enemies.entrySet()) {
  //  if (entry.getKey() != UUID) entry.getValue().update();
  //}
}
