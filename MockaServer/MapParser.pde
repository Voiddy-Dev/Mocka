void keyPressed() {
  selectInput("Select a level file:", "levelFileSelected");
}

void parseMap(String file_path) {
}

void levelFileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    println("User selected " + selection.getAbsolutePath());

    parseMap(selection.getAbsolutePath());
  }
}
