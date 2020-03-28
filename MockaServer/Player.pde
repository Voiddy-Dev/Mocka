ArrayList<Player> players;
int UUID_available = 0;

void updatePlayers() {  
  for (int i = players.size()-1; i >= 0; i--) {
    Player p = players.get(i);

    if (!p.client.active()) {
      players.remove(i);
    }
  }
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
