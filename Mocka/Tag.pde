void showTag() {
  pushMatrix();
  int num_entries = 1 + enemies.size();
  int rows = 2;
  int cols = max(1, (num_entries - 1) / rows);
  float w = min(200, float(width) / cols);
  float h = float(100) / rows;
  Iterator<Rocket> it = allRockets();
  int i = 0;
  int j = 0;
  int c = 0;
  textSize(20);
  strokeWeight(5);
  translate(0, height-100);
  while (it.hasNext()) {
    Rocket r = it.next();
    pushMatrix();
    translate(i*w, j*h);

    // Leaderboard
    fill(255);
    stroke(r.col);
    ellipse(h*0.5, h*0.5, h*0.75, h*0.75);



    // Name
    translate(h * 0.75, 0);

    pushMatrix();
    translate(h*0.9, h*0.5);

    fill(255);

    stroke(r.col);
    rect(0, 2, h * 1.2, h*0.5);
    fill(0);
    text(r.name, 0, 0, h * 1.5, h);
    popMatrix();
    // Score
    popMatrix();
    j++;
    if (j == rows) {
      j = 0;
      i++;
    }
  }
  popMatrix();
}
