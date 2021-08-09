PGraphics backgroundGraphics;
PShader neonShader;

void setupBackground() {
  backgroundGraphics = createGraphics(width, height, P2D);
  //backgroundGraphics.noSmooth();
  backgroundGraphics.beginDraw();
  backgroundGraphics.background(0); // for some reason this doesn't have an effect
  backgroundGraphics.endDraw();

  neonShader = loadShader("neon.glsl");
}

void drawBackground() {
  backgroundGraphics.beginDraw();

  if (frameCount==1)backgroundGraphics.background(0);

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
    backgroundGraphics.line(r.x, r.y, r.px, r.py);
  }
  backgroundGraphics.popMatrix();

  neonShader.set("WindowSize", float(backgroundGraphics.width), float(backgroundGraphics.height));
  neonShader.set("do1", frameCount % 8 == 0);
  neonShader.set("do2", random(1) > 0.5);
  neonShader.set("do3", frameCount % 3 == 0);
  backgroundGraphics.filter(neonShader);

  backgroundGraphics.endDraw();

  //backgroundGraphics.copy();
  //println(backgroundGraphics.copy());
  image(backgroundGraphics, 0, 0);
  //set(0, 0, backgroundGraphics);
}
