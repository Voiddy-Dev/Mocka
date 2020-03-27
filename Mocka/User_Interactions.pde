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

//just to have fun with the particle system
void mouseDragged() {
  PVector diff = new PVector(pmouseX - mouseX, pmouseY - mouseY);
  diff.normalize();

  partSys.pos = new PVector(mouseX, mouseY);
  partSys.init = diff.copy();
}
