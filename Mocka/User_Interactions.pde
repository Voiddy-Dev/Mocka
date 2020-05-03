class MyRocket extends Rocket {
  MyRocket(float x, float y) {
    super(x, y);
  }
}

void mousePressed() {
  if (current_scene == Scene.color_palette) {
    GAME_COLOR_ = GAME_COLOR;
    setScene(Scene.game);
  }
}

final int ESCC = 567890987; // that's a key mash fyi

void keyPressed() {
  if (keyCode == UP) myRocket.INPUT_up = true;
  if (keyCode == LEFT)myRocket.INPUT_left = true;
  if (keyCode == RIGHT)myRocket.INPUT_right = true;
  if (keyCode == 27) { 
    if (current_scene != Scene.game) {
      setScene(Scene.game);
      key = 0; // prevent esc to close
    }
  }
}

void keyTyped() {
  if (current_scene == Scene.game) keyTyped_GAME();
  else if (current_scene == Scene.chat) keyTyped_CHAT();
}

void keyReleased() {
  if (keyCode == UP) myRocket.INPUT_up = false;
  if (keyCode == LEFT) myRocket.INPUT_left = false;
  if (keyCode == RIGHT) myRocket.INPUT_right = false;
}

void keyTyped_GAME() {
  if (key == 'r') {
    Vec2 new_pos = box2d.coordPixelsToWorld(width/2, height/2);
    myRocket.body.setTransform(new_pos, 0);
    Vec2 new_vel = new Vec2(0, 0);
    myRocket.body.setLinearVelocity(new_vel);
    myRocket.body.setAngularVelocity(0);
    if (myRocket.state != STATE_IS_IT) NOTIFY_CAPITULATE();
  }
  if (key == 't') setScene(Scene.chat);
  if (key == '/') {
    chat_txt_entry = "/";
    setScene(Scene.chat);
  }
  if (key == 'y') current_scene = Scene.color_palette;
  if (key == ' ') {
    float angle = myRocket.body.getAngle();
    angle = ((angle % TAU) + TAU) % TAU;
    if (angle > PI) angle -= TAU;
    println(angle);
    if (abs(angle) > radians(45)) {
      if (angle < 0) myRocket.body.applyAngularImpulse(37);
      else myRocket.body.applyAngularImpulse(-37);
    }
  }
  if (keyCode == 27) key = ESC;
}
