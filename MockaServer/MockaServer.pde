import processing.net.*;

void setup() {
  size(0, 0); 

  serverTCP = new Server(this, 25567);
  serverUDP = new UDP(this, 16440);
  //udp.log(true); // lets log everything for now
  serverUDP.listen(true);
  println("Starting server");
  players = new ArrayList<Player>(0);
}

void draw() {
  if (!serverTCP.active()) {
    println("Trouble! Server is no longer processing-active. Stopping.");
    serverTCP.stop();
    stop();
  }
  updatePlayers();
}

Server serverTCP;

void serverEvent(Server serv, Client myClient) {
  Player myPlayer = new Player(myClient);
  players.add(myPlayer);

  myPlayer.client.write(myPlayer.UUID);

  println("New Client with IP: " + myClient.ip() + " - UUID: " + myPlayer.UUID);
}

// ClientEvent message is generated when a client disconnects.
void disconnectEvent(Client someClient) {
  int safeKeep = -1;
  for (int i = players.size()-1; i >= 0; i--) {
    Player p = players.get(i);

    if (p.client.equals(someClient)) {
      players.remove(i);
      safeKeep = i;
      println("Client with UUID " + p.UUID + " disconnected");
    }
  }

  if (safeKeep != -1) { // problem if someone connects and disconnects at the same time
    serverTCP.write(safeKeep); // tell everyone who disconnected
  }
}
