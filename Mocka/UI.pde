boolean KEY_up, KEY_left, KEY_right;

void mousePressed() {
  if (current_scene == Scene.color_palette) {
    GAME_COLOR_ = myRocket.col;
    setScene(Scene.game);
  } else {
    if (gamemode instanceof Editor) {
      ((Editor)gamemode).mousePressed();
    }
  }
}
void mouseReleased() {
  if (gamemode instanceof Editor) {
    ((Editor)gamemode).mouseReleased();
  }
}

void mouseDragged() {
  if (gamemode instanceof Editor) {
    ((Editor)gamemode).mouseDragged();
  }
}

void keyPressed() {
  char ckey = (""+key).toUpperCase().charAt(0);
  println("KyP", ckey, keyCode, key);
  if (keyCode == UP || ckey == 'Z' || ckey == 'I') KEY_up = true;
  if (keyCode == LEFT || ckey == 'Q' || ckey == 'J') KEY_left = true;
  if (keyCode == RIGHT || ckey == 'D' || ckey == 'L') KEY_right = true;
  if (keyCode == DELETE || keyCode == 8) {
    keyTyped();
    if (gamemode instanceof Editor) ((Editor)gamemode).keyPressedDelete();
  }
  if (keyCode == 27 || key == ESC) {
    if (current_scene != Scene.game) {
      setScene(Scene.game);
      key = 0; // prevent esc to close
    } else exit();
  }
  if (ckey == 10)keyTyped();
}

void keyReleased() {
  char ckey = (""+key).toUpperCase().charAt(0);
  if (keyCode == UP || ckey == 'Z' || ckey == 'I') KEY_up = false;
  if (keyCode == LEFT || ckey == 'Q' || ckey == 'J') KEY_left = false;
  if (keyCode == RIGHT || ckey == 'D' || ckey == 'L') KEY_right = false;
}

void updateUI() {
  myRocket.KEY_up = KEY_up;
  myRocket.KEY_left = KEY_left;
  myRocket.KEY_right = KEY_right;
}

void keyTyped() {
  char ckey = (""+key).toUpperCase().charAt(0);
  println("KeyTyped", ckey, keyCode, key);
  if (current_scene == Scene.game) keyTyped_GAME();
  else if (current_scene == Scene.chat) keyTyped_CHAT();
}

void keyTyped_GAME() {
  char ckey = (""+key).toUpperCase().charAt(0);
  if (ckey == 'R') {
    myRocket.respawnRocket();
    gamemode.respawn();
    NOTIFY_RESPAWN();
  }
  if (ckey == 'T') setScene(Scene.chat);
  if (key == '/') {
    chat_txt_entry = "/";
    setScene(Scene.chat);
  }
  if (ckey == 'Y') current_scene = Scene.color_palette;
  if (ckey == 'A') myRocket.AP_ACTIVE = !myRocket.AP_ACTIVE;
  if (key == ' ') myRocket.initiateStandup();
  if (key == TAB) {
    if (gamemode instanceof Editor) {
      ((Editor)gamemode).tab();
    }
  }
  if (keyCode == 27) key = ESC;
}
