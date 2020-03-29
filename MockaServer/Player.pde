ArrayList<Player> players;
int UUID_available = 0;

void updatePlayers() {  
  for (int i = players.size()-1; i >= 0; i--) {
    Player p = players.get(i);

    if (!p.client.active()) {
      players.remove(i);
    }
  }

  // Display connect UUID
  StringBuilder str = new StringBuilder();

  for (Player p : players) {
    str.append("Connected Client: ").append(p.client.ip());
    str.append(" - UUID: ").append(p.UUID);
    str.append("\n");
  }

  textSize(25);
  fill(0);
  text(str.toString(), 50, 50, width - 50, height - 50);
}

class Player {
  Client client;
  int UUID;

  Player(Client client_) {
    client = client_;
    UUID = UUID_available;
    UUID_available++;
  }

  void update() {
  }
}
