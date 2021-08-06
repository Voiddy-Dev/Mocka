PGraphics backgroundGraphics;

void setupBackground() {
  backgroundGraphics = createGraphics(width, height);
  //backgroundGraphics.noSmooth();
  backgroundGraphics.beginDraw();
  backgroundGraphics.background(0);
  backgroundGraphics.endDraw();
}

void drawBackground() {
  backgroundGraphics.beginDraw();

  backgroundGraphics.blendMode(LIGHTEST);
  int fc = frameCount % 16;
  backgroundGraphics.tint(255);
  if (fc == 0)backgroundGraphics.image(backgroundGraphics, 0, 1);
  if (fc == 4)backgroundGraphics.image(backgroundGraphics, 0, -1);
  if (fc == 8)backgroundGraphics.image(backgroundGraphics, 1, 0);
  if (fc == 12)backgroundGraphics.image(backgroundGraphics, -1, 0);
  backgroundGraphics.blendMode(BLEND);

  float scale = min(float(width)/WIDTH, float(height)/HEIGHT);
  backgroundGraphics.pushMatrix();
  backgroundGraphics.translate(width/2, height/2);
  backgroundGraphics.scale(scale);
  backgroundGraphics.translate(-WIDTH/2, -HEIGHT/2);

  backgroundGraphics.strokeWeight(10);
  Iterator<Rocket> rockets = allRockets(); 
  while (rockets.hasNext()) {
    Rocket r = rockets.next();
    if (r.px == 0 || r.py == 0) continue;
    backgroundGraphics.stroke(r.col);
    backgroundGraphics.line (r.x, r.y, r.px, r.py);
  }
  backgroundGraphics.popMatrix();
  // Fade
  if (frameCount % 4 == 0) {
    backgroundGraphics.blendMode(SUBTRACT);
    backgroundGraphics.noStroke();
    backgroundGraphics.fill(1);
    backgroundGraphics.rect(0, 0, width, height);
    backgroundGraphics.blendMode(BLEND);
  }

  backgroundGraphics.endDraw();

  set(0, 0, backgroundGraphics);
  //image(backgroundGraphics, 0, 0);
}
