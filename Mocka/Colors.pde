color GAME_COLOR_; // Color, before a change is confirmed - used if change is not confirmed

color[][] color_matrix = new color[][] {
  new color[]{#F23F3C, #F5A250, #F6CD56}, 
  new color[]{#6C081B, #B173D2, #FC28FC}, 
  new color[]{#022246, #4290F4, #29E2E1}, 
  new color[]{#0D6C61, #56CE67, #21D626}
};

void drawColors() {
  drawGame();

  pushStyle();
  pushMatrix();
  translate(WIDTH/2, HEIGHT/2);
  rectMode(CENTER);

  int w = color_matrix.length;
  int h = color_matrix[0].length;

  final float BOX_SIZE = 150;
  final float WINDOW_WIDTH = BOX_SIZE * w;
  final float WINDOW_HEIGHT = BOX_SIZE * h;

  strokeWeight(3);
  stroke(0);

  fill(128, 200);
  rect(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT);

  final float BOX_WIDTH = (WINDOW_WIDTH / w) * 1.0;
  final float BOX_HEIGHT = (WINDOW_HEIGHT / h) * 1.0;

  float my_i = constrain(floor(map(MOUSEX, (WIDTH-WINDOW_WIDTH)/2.0, (WIDTH+WINDOW_WIDTH)/2.0, 0, w)), 0, w-1);
  float my_j = constrain(floor(map(MOUSEY, (HEIGHT-WINDOW_HEIGHT)/2.0, (HEIGHT+WINDOW_HEIGHT)/2.0, 0, h)), 0, h-1);

  noStroke();

  translate(-WINDOW_WIDTH/2, -WINDOW_HEIGHT/2);
  translate(WINDOW_WIDTH/w/2, WINDOW_HEIGHT/h/2);
  for (int i = 0; i < w; i++) {
    for (int j = 0; j < h; j++) {
      float x = map(i, 0, w, 0, WINDOW_WIDTH);
      float y = map(j, 0, h, 0, WINDOW_HEIGHT);
      color col = color_matrix[i][j];
      fill(col);
      if (i == my_i && j == my_j) myRocket.col = col;
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
