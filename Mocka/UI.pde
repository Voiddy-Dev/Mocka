boolean INPUT_up, INPUT_left, INPUT_right;

void mousePressed() {
  if (current_scene == Scene.color_palette) {
    GAME_COLOR_ = myRocket.col;
    setScene(Scene.game);
  }
}

void keyPressed() {
  if (keyCode == UP || key == 'Z' || key == 'I') INPUT_up = true;
  if (keyCode == LEFT || key == 'Q' || key == 'J') INPUT_left = true;
  if (keyCode == RIGHT || key == 'D' || key == 'L') INPUT_right = true;
  if (keyCode == 27 || key == ESC) { 
    if (current_scene != Scene.game) {
      setScene(Scene.game);
      key = 0; // prevent esc to close
    } else exit();
  }
}

void keyReleased() {
  if (keyCode == UP || key == 'Z' || key == 'I') INPUT_up = false;
  if (keyCode == LEFT || key == 'Q' || key == 'J') INPUT_left = false;
  if (keyCode == RIGHT || key == 'D' || key == 'L') INPUT_right = false;
}

int standupCounter = 0;
boolean standupDirection;

void updateUI() {
  if (standupCounter == 0) {
    myRocket.INPUT_up = INPUT_up;
    myRocket.INPUT_left = INPUT_left;
    myRocket.INPUT_right = INPUT_right;
  } else {
    myRocket.INPUT_up = false;
    myRocket.INPUT_left = standupDirection;
    myRocket.INPUT_right = !standupDirection;
    standupCounter--;
  }
}

void keyTyped() {
  if (current_scene == Scene.game) keyTyped_GAME();
  else if (current_scene == Scene.chat) keyTyped_CHAT();
}

void keyTyped_GAME() {
  if (key == 'r') {
    Vec2 new_pos = box2d.coordPixelsToWorld(WIDTH/2, HEIGHT/2);
    myRocket.body.setTransform(new_pos, 0);
    Vec2 new_vel = new Vec2(0, 0);
    myRocket.body.setLinearVelocity(new_vel);
    myRocket.body.setAngularVelocity(0);
    gamemode.respawn();
  }
  if (key == 't') setScene(Scene.chat);
  if (key == '/') {
    chat_txt_entry = "/";
    setScene(Scene.chat);
  }
  if (key == 'y') current_scene = Scene.color_palette;
  if (key == ' ') {
    if (standupCounter != 0) return;
    float angle = myRocket.body.getAngle();
    angle = ((angle % TAU) + TAU) % TAU;
    if (angle > PI) angle -= TAU;
    if (abs(angle) > radians(45)) {
      standupDirection = angle < 0;
      if (standupDirection) myRocket.body.applyAngularImpulse(37);
      else myRocket.body.applyAngularImpulse(-37);
      standupCounter = 20;
    }
  }
  if (keyCode == 27) key = ESC;
}
