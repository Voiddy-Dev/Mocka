HashMap<Integer, Enemy> enemies = new HashMap();

class Enemy extends Rocket {
  int UUID;

  Enemy(int UUID, float x, float y) {
    super(x, y);
  }
}
