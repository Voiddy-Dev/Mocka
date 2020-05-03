import java.util.Map;

color GAME_COLOR; // Random color that can be used throughout the code

MyRocket myRocket;

final boolean DEBUG_PUNCHING = false;
final boolean DEBUG_PACKETS  = false;

void setup() {
  //size(120, 80, FX2D);
  //size(1200, 800, FX2D);
  //size(480, 320, FX2D);
  //size(960, 640, FX2D);
  size(1200, 790, FX2D);

  rocketShape = createRocketShape();

  setupBox2D();

  setupNetworking();

  myRocket = new MyRocket(width/2, height-80);
  randomRocketColor();
}

void draw() {
  if (current_scene == Scene.GAME_SCENE) drawGame();
  if (current_scene == Scene.COLOR_SCENE) drawColors();
}

enum Scene {
  GAME_SCENE, COLOR_SCENE
}

Scene current_scene = Scene.GAME_SCENE;

void drawGame() {
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
}
