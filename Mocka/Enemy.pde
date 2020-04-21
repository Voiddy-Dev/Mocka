HashMap<Integer, Enemy> enemies = new HashMap();

void showEnemies() {
  for (Map.Entry entry : enemies.entrySet()) {
    Enemy enemy = (Enemy)entry.getValue();
    enemy.show();
  }
}

class Enemy extends Rocket {
  int UUID;

  Enemy(int UUID, float x, float y) {
    super(x, y);
  }
}
