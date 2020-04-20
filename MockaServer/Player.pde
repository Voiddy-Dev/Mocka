import java.util.Map;

HashMap<Integer, Player> players = new HashMap<Integer, Player>();

int getFreeUUID() {
  int MAX_UUID = 256;
  int UUID;
  do {
    UUID = (int)random(MAX_UUID);
  } while (players.containsKey(UUID));
  return UUID;
}

void removeInactivePlayers() {  
  for (Map.Entry entry : players.entrySet()) {
    Player p = (Player)entry.getValue();
    if (!p.TCP_CLIENT.active()) {
      println("SERVER: player with UUID "+p.UUID+" is no longer active, disconnecting");
      players.remove(entry.getKey());
    }
  }
}

void updatePlayers() {
  for (Map.Entry entry : players.entrySet()) {
    Player p = (Player)entry.getValue();
  }
}

class Player {
  Client TCP_CLIENT;
  int UUID; 

  Player(Client client_, int UUID_) {
    TCP_CLIENT = client_;
    UUID = UUID_;
    println("SERVER: new TCP connection. ip: "+TCP_CLIENT.ip()+" UUID: "+UUID);
  }
}
