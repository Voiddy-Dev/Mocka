boolean INPUT_up, INPUT_left, INPUT_right;

void mousePressed() {
  if (current_scene == Scene.color_palette) {
    GAME_COLOR_ = myRocket.col;
    setScene(Scene.game);
  }
}

void keyPressed() {
  char ckey = (""+key).toUpperCase().charAt(0);
  if (keyCode == UP || ckey == 'Z' || ckey == 'I') INPUT_up = true;
  if (keyCode == LEFT || ckey == 'Q' || ckey == 'J') INPUT_left = true;
  if (keyCode == RIGHT || ckey == 'D' || ckey == 'L') INPUT_right = true;
  if (keyCode == 27 || key == ESC) { 
    if (current_scene != Scene.game) {
      setScene(Scene.game);
      key = 0; // prevent esc to close
    } else exit();
  }
}

void keyReleased() {
  char ckey = (""+key).toUpperCase().charAt(0);
  if (keyCode == UP || ckey == 'Z' || ckey == 'I') INPUT_up = false;
  if (keyCode == LEFT || ckey == 'Q' || ckey == 'J') INPUT_left = false;
  if (keyCode == RIGHT || ckey == 'D' || ckey == 'L') INPUT_right = false;
}

int standupCounter = Integer.MAX_VALUE;
float standupAngle;
boolean standupDirection;

void updateUI() {
  if (!doingStandingProcedure()) {
    myRocket.INPUT_up = INPUT_up;
    myRocket.INPUT_left = INPUT_left;
    myRocket.INPUT_right = INPUT_right;
  } else {
    standupCounter++;
    float angle = myRocket.body.getAngle();
    angle = ((angle % TAU) + TAU) % TAU;
    if (angle > PI) angle -= TAU;
    int dir = standupDirection ? -1 : 1;
    standupAngle += (angle - standupAngle) * 0.2;
    standupAngle -= dir * (radians(45)/20);
    float force = (angle - standupAngle) * 20;
    force = constrain(force, -13, 13);
    myRocket.body.applyAngularImpulse(-force);
    if (abs(angle) < radians(10)) standupCounter = Integer.MAX_VALUE;
    myRocket.INPUT_up = false;
    myRocket.INPUT_left = standupDirection;
    myRocket.INPUT_right = !standupDirection;
  }
}

boolean doingStandingProcedure() {
  return standupCounter < 60;
}

void keyTyped() {
  if (current_scene == Scene.game) keyTyped_GAME();
  else if (current_scene == Scene.chat) keyTyped_CHAT();
}

void keyTyped_GAME() {
  char ckey = (""+key).toUpperCase().charAt(0);
  if (ckey == 'R') {
    TOUCHING_PLATFORMS = 0;
    Vec2 new_pos = box2d.coordPixelsToWorld(WIDTH/2, HEIGHT/2);
    myRocket.body.setTransform(new_pos, 0);
    Vec2 new_vel = new Vec2(0, 0);
    myRocket.body.setLinearVelocity(new_vel);
    myRocket.body.setAngularVelocity(0);
    gamemode.respawn();
    NOTIFY_RESPAWN();
  }
  if (ckey == 'T') setScene(Scene.chat);
  if (key == '/') {
    chat_txt_entry = "/";
    setScene(Scene.chat);
  }
  if (ckey == 'Y') current_scene = Scene.color_palette;
  if (key == ' ' && TOUCHING_PLATFORMS != 0) {
    if (doingStandingProcedure()) return;
    float angle = myRocket.body.getAngle();
    angle = ((angle % TAU) + TAU) % TAU;
    if (angle > PI) angle -= TAU;
    if (abs(angle) > radians(45)) {
      standupDirection = angle < 0;
      standupAngle = angle;
    }
    standupCounter = 0;
  }
  if (keyCode == 27) key = ESC;
}
