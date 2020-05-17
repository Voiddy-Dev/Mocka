import processing.svg.*;

void loadAssets() {
  rocketShape = createRocketShape();
  targetShape = createTargetShape();
  angerShape = createAngerShape();
}

PShape angerShape;

PShape createAngerShape() {
  PShape anger = createShape(GROUP);
  int N = 6;
  for (int i = 0; i < N; i++) {
    float angle = map(i, 0, N, 0, TAU);
    PVector pos = (new PVector(0, 225)).rotate(angle);
    PShape l = createLigthning();
    l.translate(pos.x, pos.y);
    anger.addChild(l);
  }
  return anger;
}

PShape createLigthning() {
  PShape lightning = createShape();
  lightning.setStroke(false);
  //lightning.setFill(#F7F702);
  lightning.setFill(0);
  lightning.beginShape();
  lightning.vertex(0, 10);
  lightning.vertex(30, 80);
  lightning.vertex(-30, 5);
  lightning.vertex(0, -10);
  lightning.vertex(-30, -80);
  lightning.vertex(30, -5);
  lightning.endShape();
  return lightning;
}

PShape targetShape;

PShape createTargetShape() {
  PShape circle = createShape(ELLIPSE, 0, 0, 450, 450);
  circle.setFill(false);
  circle.setStroke(0);
  circle.setStrokeWeight(40);
  PShape lines = createShape();
  lines.setStroke(0);
  lines.setStrokeWeight(40);
  float r1 = 250;
  float r2 = 200; 
  lines.beginShape(LINES);
  lines.vertex(0, r1);
  lines.vertex(0, r2);
  lines.vertex(0, -r1);
  lines.vertex(0, -r2);
  lines.vertex(r1, 0);
  lines.vertex(r2, 0);
  lines.vertex(-r1, 0);
  lines.vertex(-r2, 0);
  lines.endShape();
  PShape group = createShape(GROUP);
  group.addChild(circle);
  group.addChild(lines);
  return group;
}

float ROCKET_ICON_SCALE = 0.15;
PShape rocketShape;
PShape rocketIcon;// = loadShape("rocket.svg");

PShape createRocketShape() {
  //Geometry of rocket body imported from talky.io JS
  float mult = 30.0 * (10.0 / 36);
  PShape shape = createShape();
  shape.beginShape();
  //shape.vertex( -.6 * mult, -1.3 * mult);
  shape.vertex( -.5 * mult, -1.5 * mult);
  shape.vertex(   0 * mult, -1.8 * mult);
  shape.vertex(  .5 * mult, -1.5 * mult);
  //shape.vertex(  .6 * mult, -1.3 * mult);
  shape.vertex( 1.2 * mult, .7   * mult);
  shape.vertex(  .9 * mult, 1.8  * mult);
  shape.vertex( -.9 * mult, 1.8  * mult);
  shape.vertex(-1.2 * mult, .7   * mult);
  shape.endShape(CLOSE);
  shape.scale(10);
  return shape;
}
