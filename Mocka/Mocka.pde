import java.util.Map;

MyRocket myRocket;

final boolean DEBUG_PUNCHING = false;
final boolean DEBUG_PACKETS  = true;
final boolean DEBUG_GAMEMODE = true;

void setup() {
  //size(120, 80, FX2D);
  //size(1200, 800, FX2D);
  //size(480, 320, FX2D);
  //size(960, 640, FX2D);
  size(1200, 790, FX2D);

  setGamemode(new Disconnected());
  rocketShape = createRocketShape();
  setupBox2D();
  setupNetworking();
  myRocket = new MyRocket(width/2, height-80);
}

void draw() {
  updateUI();
  if (current_scene == Scene.game) drawGame();
  if (current_scene == Scene.color_palette) drawColors();
  if (current_scene == Scene.chat) drawChat();
}

enum Scene {
  game, color_palette, chat;
}

Scene current_scene = Scene.game;

void setScene(Scene scene) {
  if (scene == current_scene) return;
  if (current_scene == Scene.game) {
    myRocket.INPUT_up = false;
    myRocket.INPUT_left = false;
    myRocket.INPUT_right = false;
  } else if (current_scene == Scene.chat) {
    chat_txt_entry = "";
  } else if (current_scene == Scene.color_palette) {
    myRocket.col = GAME_COLOR_;
    NOTIFY_MY_COLOR(myRocket.col);
  }
  current_scene = scene;
  if (scene == Scene.color_palette) {
    GAME_COLOR_ = myRocket.col;
  }
}

void drawGame() {
  updateNetwork();

  myRocket.interactions();
  updateEnemies();
  box2d.step();
  gamemode.update();
  informEnemies();

  background(255); // white background
  // updating and displaying the rocket
  //rock.update();
  noStroke();
  rectMode(CENTER);
  myRocket.show();
  showEnemies();

  showTerrain(); // terrain
  gamemode.hud();
}
