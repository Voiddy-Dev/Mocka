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
    Vec2 new_pos = box2d.coordPixelsToWorld(width/2, height/2);
    myRocket.body.setTransform(new_pos, 0);
    Vec2 new_vel = new Vec2(0, 0);
    myRocket.body.setLinearVelocity(new_vel);
    myRocket.body.setAngularVelocity(0);
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
