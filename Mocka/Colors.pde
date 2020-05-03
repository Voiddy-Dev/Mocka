void drawColors() {
  drawGame();

  pushStyle();
  pushMatrix();
  translate(width/2, height/2);
  rectMode(CENTER);

  final float WINDOW_WIDTH = width * 2.0 / 3;
  final float WINDOW_HEIGHT = height * 1.1 / 3;

  final float COLOR_GAP = 10;

  strokeWeight(3);
  stroke(0);

  fill(128, 200);
  rect(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT);

  int w = 16;
  int h = 5;

  final float BOX_WIDTH = (WINDOW_WIDTH / w) * 1.0;
  final float BOX_HEIGHT = (WINDOW_HEIGHT / h) * 1.0;

  float my_i = constrain(floor(map(mouseX, (width-WINDOW_WIDTH)/2.0, (width+WINDOW_WIDTH)/2.0, 0, w)), 0, w-1);
  float my_j = constrain(floor(map(mouseY, (height-WINDOW_HEIGHT)/2.0, (height+WINDOW_HEIGHT)/2.0, 0, h)), 0, h-1);

  noStroke();

  translate(-WINDOW_WIDTH/2, -WINDOW_HEIGHT/2);
  translate(WINDOW_WIDTH/w/2, WINDOW_HEIGHT/h/2);
  colorMode(HSB);
  for (int i = 0; i < w; i++) {
    for (int j = 0; j < h; j++) {
      float x = map(i, 0, w, 0, WINDOW_WIDTH);
      float y = map(j, 0, h, 0, WINDOW_HEIGHT);
      float hue = map(i, 0, w, 0, 255);
      float sat = map(j, 0, h, 255, 100);
      float bri = map(j, 0, h, 220, 100);
      color col = color(hue, sat, bri);
      fill(col);
      if (i == my_i && j == my_j) {
        GAME_COLOR = col;
        myRocket.setColor(GAME_COLOR);
      }
      rect(x, y, BOX_WIDTH, BOX_HEIGHT);
    }
  }
  float x = map(my_i, 0, w, 0, WINDOW_WIDTH);
  float y = map(my_j, 0, h, 0, WINDOW_HEIGHT);
  noFill();
  stroke(0);
  rect(x, y, BOX_WIDTH, BOX_HEIGHT);

  popStyle();
  popMatrix();
}
