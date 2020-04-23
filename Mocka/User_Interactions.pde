class MyRocket extends Rocket {
  MyRocket(float x, float y) {
    super(x, y);
  }
}

void keyPressed() {
  if (keyCode == UP) myRocket.INPUT_up = true;
  if (keyCode == LEFT)myRocket.INPUT_left = true;
  if (keyCode == RIGHT)myRocket.INPUT_right = true;
}

void keyTyped() {
  if (key == 'r') {
    myRocket.killBody();
    myRocket = new MyRocket(width/2, height/2);
  }
  if (key == 't') {
    killTerrain();
    setupTerrain();
  }
}

void keyReleased() {
  if (keyCode == UP) myRocket.INPUT_up = false;
  if (keyCode == LEFT) myRocket.INPUT_left = false;
  if (keyCode == RIGHT) myRocket.INPUT_right = false;
}
