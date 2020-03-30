boolean up = false, left = false, right = false;

void keyPressed() {
  if (keyCode == UP) {
    up = true;
  }
  if (keyCode == LEFT) {
    left = true;
  }
  if (keyCode == RIGHT) {
    right = true;
  }
}

void keyTyped() {
  if (key == 'r') {
    rock = new Rocket(width/2, 400);
  }
}

void keyReleased() {
  if (keyCode == UP) {
    up = false;
  }
  if (keyCode == LEFT) {
    left = false;
  }
  if (keyCode == RIGHT) {
    right = false;
  }
}

float ppmouseX = 0, ppmouseY = 0;

void mousePressed() {
  ppmouseX = mouseX;
  ppmouseY = mouseY;
}

void mouseMoved() {
  if (ppmouseX == 0 && ppmouseY == 0)mousePressed();
}
