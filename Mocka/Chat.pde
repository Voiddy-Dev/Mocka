final int BOTTOM_BORDER = 100;

String[] chat_lines;

String chat_txt_entry = "";

void drawChat() {
  drawGame();

  pushStyle();
  pushMatrix();

  translate(0, height - BOTTOM_BORDER);
  textAlign(LEFT, BOTTOM);
  rectMode(CORNER);

  final float LINE_HEIGHT = 20;
  textSize(20);

  float w = max(100, textWidth(chat_txt_entry));
  fill(128, 180);
  rect(0, -LINE_HEIGHT, w+6, LINE_HEIGHT);
  fill(0);
  text(chat_txt_entry, 3, 0);

  popStyle();
  popMatrix();
}

void drawChatHistory() {
}

void addToChatHistory(String msg) {
}

void keyTyped_CHAT() {
  //if (key == ESC || keyCode == 567890987) setScene(Scene.game);
  //else 
  if (key == BACKSPACE || int(key) == 65535) {
    if (chat_txt_entry.length() > 0) chat_txt_entry = chat_txt_entry.substring(0, chat_txt_entry.length()-1);
  } else if (key == ENTER || key == RETURN) {
    NOTIFY_CHAT(chat_txt_entry);
    setScene(Scene.game);
  } else if (char_allowed(key)) {
    chat_txt_entry += key;
  }
}

// Probably find a better thing for valid chars
boolean char_allowed(char c) {
  //if (c >= 'a' && c <= 'z') return true;
  //if (c >= 'A' && c <= 'Z') return true;
  //if (c == ' ') return true;
  //if (c == '/') return true;
  if (key >= 32 && key <= 126) return true;
  return false;
}
