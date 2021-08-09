//import processing.javafx.*;

import java.util.Map;

MyRocket myRocket;

boolean SETTING_DO_ANAGLYPH_FILTER = true;
boolean SETTING_DO_NEON_BACKGROUND = true;
boolean SETTING_DEFAULT_AP_STATE = false;

final boolean DEBUG_PUNCHING = false;
final boolean DEBUG_PACKETS  = false;
final boolean DEBUG_GAMEMODE = false;
final boolean DEBUG_ZOOMOUT = false;

final int WIDTH = 1200;
final int HEIGHT = 790;

PShader anaglyphShader;

void setup() {
  //size(1200, 800, P2D);
  //size(480, 320, P2D);
  //size(960, 640, P2D);
  //size(1200, 790, P2D);
  //size(901, 593, P2D);
  fullScreen(P2D);
  //pixelDensity(1);

  loadAssets();
  setGamemode(new Disconnected());
  setupBox2D();
  setupNetworking();
  platforms = randomTerrain(10);
  myRocket = new MyRocket(1, -2);
  setupBackground();

  anaglyphShader = loadShader("anaglyph.glsl");
}

void draw() {
  updateUI();
  if (current_scene == Scene.game || current_scene == Scene.color_palette) drawGame();
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

float MOUSEX, MOUSEY;

float computeScale() {
  if (DEBUG_ZOOMOUT) return 0.9 * min(float(width)/WIDTH, float(height)/HEIGHT);
  return min(float(width)/WIDTH, float(height)/HEIGHT);
}

void drawGame() {
  updateNetwork();

  myRocket.interactions();
  updateEnemies();
  box2d.step();
  gamemode.update();
  informEnemies();

  if (SETTING_DO_NEON_BACKGROUND) drawBackground();
  else background(0);

  translate(width/2, height/2);
  scale(computeScale());
  translate(-WIDTH/2, -HEIGHT/2);
  MOUSEX = (mouseX - width/2) / computeScale() + WIDTH/2;
  MOUSEY = (mouseY - height/2) / computeScale() + HEIGHT/2;
  box2d.setScaleFactor(10);
  box2d.transX = WIDTH/2;
  box2d.transY = HEIGHT/2;

  myRocket.show();
  showEnemies();

  showTerrain(); // terrain

  anaglyphShader.set("WindowSize", float(backgroundGraphics.width), float(backgroundGraphics.height));
  if (SETTING_DO_ANAGLYPH_FILTER) filter(anaglyphShader);

  gamemode.hud();
}
