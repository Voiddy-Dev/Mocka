import java.util.Map;
import java.util.Iterator;

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
  Iterator<Map.Entry<Integer, Player>> iter = players.entrySet().iterator();
  while (iter.hasNext()) {
    Map.Entry<Integer, Player> entry = iter.next();
    Player p = entry.getValue();
    if (!p.TCP_CLIENT.active()) {
      iter.remove();
      println("SERVER: player with UUID "+p.UUID+" is no longer active, disconnecting");
    }
  }
  //for (Map.Entry entry : players.entrySet()) {
  //  Player p = (Player)entry.getValue();
  //  if (!p.TCP_CLIENT.active()) {
  //    println("SERVER: player with UUID "+p.UUID+" is no longer active, disconnecting");
  //    players.remove(entry.getKey());
  //  }
  //}
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

    // Notify this new player about all existing players
    for (Map.Entry entry : players.entrySet()) {
      Player p = (Player)entry.getValue();
      if (p.UUID != UUID) TCP_SEND(NOTIFY_NEW_PLAYER(p.UUID));
    }
  }

  void TCP_SEND(ByteBuffer buf) {
    TCP_CLIENT.write(buf.array());
  }

  ByteBuffer network_data = ByteBuffer.allocate(0);

  void updateNetwork() {
    readNetwork();
    interpretNetwork();
  }

  void interpretNetwork() {
    if (network_data.remaining()>0) {
      byte PACKET_ID = network_data.get();
      println("SERVER: Reading packet from "+UUID+" PACKET: "+PACKET_ID);
    }
  }

  void readNetwork() {
    if (TCP_CLIENT.available()>0) {
      println("client: Reading "+TCP_CLIENT.available()+" bytes from TCP server");
      // Processing's methods for reading from server is not great
      // I'm using nio.ByteBuffer instead.
      // My concern is that in one 'client.available' session, there could
      // be some leftover data for the next packet, which we don't want to
      // discard. So all the data goes into a global 'server_data' ByteBuffer,
      // to which data is added successively, here.
      byte[] data_from_network = new byte[TCP_CLIENT.available()];
      TCP_CLIENT.readBytes(data_from_network);
      byte[] data_from_buffer = network_data.array();
      byte[] data_combined = new byte[data_from_network.length + network_data.remaining()];
      System.arraycopy(data_from_buffer, 0, data_combined, 0, data_from_buffer.length);
      System.arraycopy(data_from_network, 0, data_combined, data_from_buffer.length, data_from_network.length);
      network_data = ByteBuffer.wrap(data_combined);
    }
  }
}
