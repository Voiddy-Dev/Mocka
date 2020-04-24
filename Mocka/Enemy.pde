HashMap<Integer, Enemy> enemies = new HashMap();

void showEnemies() {
  for (Map.Entry entry : enemies.entrySet()) {
    Enemy enemy = (Enemy)entry.getValue();
    enemy.show();
  }
}

void updateEnemies() {
  for (Map.Entry entry : enemies.entrySet()) {
    Enemy enemy = (Enemy)entry.getValue();
    enemy.updatePosition();
  }
}

void removeEnemy(int ded_UUID) {
  Enemy ded = enemies.get(ded_UUID);
  if (ded == null) return;
  ded.kill();
  enemies.remove(ded_UUID);
}

byte packet_send_count;
DatagramPacket packet_send = new DatagramPacket(new byte[25], 25);
void informEnemies() {
  ByteBuffer buf = ByteBuffer.wrap(packet_send.getData());
  buf.put(packet_send_count++);
  Vec2 pos = box2d.getBodyPixelCoord(myRocket.body);
  buf.putFloat(pos.x);
  buf.putFloat(pos.y);
  float angle = myRocket.body.getAngle();
  buf.putFloat(angle);
  Vec2 vel = myRocket.body.getLinearVelocity();
  buf.putFloat(vel.x);
  buf.putFloat(vel.y);
  float angular_velocity = myRocket.body.getAngularVelocity();
  buf.putFloat(angular_velocity);
  for (Map.Entry entry : enemies.entrySet()) {
    Enemy enemy = (Enemy)entry.getValue();
    enemy.notify(packet_send);
  }
}

class Enemy extends Rocket {
  int UUID;
  DatagramSocket socket;
  SocketListenThread p;

  Enemy(int UUID, float x, float y) {
    super(x, y);
    this.UUID = UUID;
  }

  void kill() {
    if (socket != null) socket.close();
    if (p != null) p.interrupt();
    killBody();
  }

  void updatePosition() {
    if (latest_packet == null)return;
    ByteBuffer data = ByteBuffer.wrap(latest_packet.getData());
    byte old_time = latest_time;
    latest_time = data.get();
    if (latest_time - old_time < 0) return;

    Vec2 new_pos = box2d.coordPixelsToWorld(new PVector(data.getFloat(), data.getFloat()));
    this.body.setTransform(new_pos, data.getFloat());
    Vec2 new_vel = new Vec2(data.getFloat(), data.getFloat());
    this.body.setLinearVelocity(new_vel);
    this.body.setAngularVelocity(data.getFloat());

    latest_packet = null;
  }

  void setSocket(DatagramSocket socket) {
    this.socket = socket;
    println("Client: listening to "+UUID);
    println(socket);
    p = new SocketListenThread();
    p.start();
  }

  void notify(DatagramPacket packet) {
    if (socket != null) {
      try {
        socket.send(packet);
      }
      catch(Exception e) {
      }
    }
  }

  byte latest_time;
  DatagramPacket latest_packet;

  class SocketListenThread extends Thread {
    long minPrime;
    SocketListenThread() {
    }

    void run() {
      while (!socket.isClosed()) {
        try {
          DatagramPacket receive = new DatagramPacket(new byte[25], 25);
          socket.receive(receive);
          latest_packet = receive;
        }
        catch (Exception e) {
          println(latest_time+" "+e);
          try {
            Thread.sleep(1);
          } 
          catch(Exception e1) {
          }
        }
      }
    }
  }
}
