final int WIDTH = 1200;
final int HEIGHT = 790;

ArrayList<Platform> platforms;

static int SELECTED_TYPE = 0;

Platform selected_platform = null;

boolean WorH = false; // false = width, true = height

boolean hovering = false;

void setup() {
  size(1200, 790, FX2D);

  platforms = new ArrayList();

  // BORDERS
  platforms.add(new Rectangle(WIDTH/2, HEIGHT - 25, WIDTH, 50)); // base platform
  platforms.add(new Rectangle(1, HEIGHT/2, 2, HEIGHT)); // left 
  platforms.add(new Rectangle(WIDTH-1, HEIGHT/2, 2, HEIGHT)); // right
  platforms.add(new Rectangle(WIDTH/2, 1, WIDTH, 2)); // top 

  selected_platform = platforms.get(0);

  rectMode(CENTER);
}

void draw() {
  background(255);

  if (!hovering) {
    cursor(ARROW);
  } else {
    cursor(HAND);
  }

  for (Platform p : platforms) {
    if (selected_platform != null && p.onTop(mouseX, mouseY)) {
      p.hovered = true;
      selected_platform = p;
    } else {
      p.hovered = false;
    }
    p.show();
  }
}

void mouseWheel(MouseEvent event) {
  if (selected_platform != null) {
    float plus = event.getCount() * 3;
    if (selected_platform instanceof Circle) {
      ((Circle) selected_platform).r += plus;
    } else if (selected_platform instanceof Rectangle) {
      if (WorH)  ((Rectangle) selected_platform).h += plus;
      else ((Rectangle) selected_platform).w += plus;
    }
  }
}

void mousePressed() {
  if (!hovering) { 
    switch (SELECTED_TYPE) {
    case 0:
      platforms.add(new Rectangle(mouseX, mouseY, random(40, 100), random(40, 100)));
      break;
    case 1:
      platforms.add(new Circle(mouseX, mouseY, random(40, 100)));
      break;
    }
  }
}

void mouseDragged() {
  if (hovering) {
    selected_platform.x = mouseX;
    selected_platform.y = mouseY;
  }
}

void keyTyped() {
  if (key =='s') {
    SELECTED_TYPE++;
    if (SELECTED_TYPE > 1) SELECTED_TYPE = 0;
  }

  if (key == 'w') WorH = false;
  if (key == 'h') WorH = true;

  if (key == 'o') hovering = !hovering;
}
