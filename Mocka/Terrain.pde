ArrayList<Platform> platforms = new ArrayList();

void setupTerrain() {
  // setup terrain values
  terrain_values[0] = 0;
  terrain_values[1] = height-50;
  terrain_values[2] = width;
  terrain_values[3] = 100;
}

void showTerrain() {
  noStroke();
  fill(GAME_COLOR);

  rectMode(CORNER);
  // Simple small rectangle at the bottom of the screen
  rect(terrain_values[0], terrain_values[1], terrain_values[2], terrain_values[3]);

  strokeWeight(5);
  stroke(0);
  //line(ppmouseX, ppmouseY, mouseX, mouseY);
}

public class Platform {
  // coordinates and used var
  int x, y, used, w;

  // constant that corresponds the necessary wait time
  // to make a platform disappear
  int NECESSARY_FRAMES = 20;
  int HEIGHT = 20;

  // constructor and initialize the platform
  public Platform(int x, int y) {
    this.x = x;
    this.y = y;
    this.w = (int) random(70, 170);

    this.used = NECESSARY_FRAMES;
  }

  // reduce the used variable if possible otherwise return false
  public boolean reduceUsed() {
    if (used <= 0) return false;

    used--;
    return true;
  }

  // returns true if something is touching the platform
  public boolean isTouching(int inX, int inY) {
    return (inX <= x + w/2) && (inX >= x - w/2) && (inY <= y + HEIGHT/2) && (inY >= y - HEIGHT/2);
  }

  // display the platform
  public void show() {
    rectMode(CENTER);
    noStroke();
    fill(GAME_COLOR);
    rect(x, y, w, HEIGHT);

    // display units
    fill(255);
    strokeWeight(2);
    textAlign(CENTER, CENTER);
    textSize(18);
    text(String.valueOf(used), x, y-3);
  }
}
