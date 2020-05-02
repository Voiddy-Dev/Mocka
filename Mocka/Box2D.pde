import shiffman.box2d.*;
import org.jbox2d.collision.shapes.*;
import org.jbox2d.common.*;
import org.jbox2d.dynamics.*;
import org.jbox2d.dynamics.contacts.*;

// A reference to our box2d world
Box2DProcessing box2d;

void setupBox2D() {
  // Initialize box2d physics and create the world
  box2d = new Box2DProcessing(this);
  box2d.createWorld();
  box2d.setGravity(0, -30);
  box2d.listenForCollisions();
}

void beginContact(Contact cp) {
  println();
  print("BOX2D: contact ");
  //if (myRocket.state != STATE_IS_IT) return;
  // Get both fixtures
  Fixture f1 = cp.getFixtureA();
  Fixture f2 = cp.getFixtureB();
  // Get both bodies
  Body b1 = f1.getBody();
  Body b2 = f2.getBody();

  // Get our objects that reference these bodies
  Object o1 = b1.getUserData();
  Object o2 = b2.getUserData();
  print(o1);
  print(" ");
  print(o2);
  print(" ");
  if (o1 != myRocket && o2 != myRocket) return;
  EnemyRocket enemy;
  if (o1 instanceof EnemyRocket) enemy = (EnemyRocket) o1;
  else if (o2 instanceof EnemyRocket) enemy = (EnemyRocket) o2;
  else return;
  println(enemy.UUID);
  if (myRocket.state == STATE_IS_IT) NOTIFY_TAGGED_OTHER(enemy.UUID); 
  else if (enemy.state == STATE_IS_IT) NOTIFY_CAPITULATE();
}
