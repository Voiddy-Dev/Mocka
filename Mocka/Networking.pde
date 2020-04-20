import processing.net.*;
import java.nio.ByteBuffer;

int UUID = -1;

String SERVER_TCP_IP = "localhost"; //"lmhleetmcgang.ddns.net";
int SERVER_TCP_PORT = 25567;

HashMap<Integer, Enemy> enemies = new HashMap();

Client client;

void setupNetworking() {
  client = new Client(this, SERVER_TCP_IP, SERVER_TCP_PORT);
}

ByteBuffer network_data = ByteBuffer.allocate(0);

void updateNetwork() {
  readNetwork();
  interpretNetwork();
}

void interpretNetwork() {
  if (network_data.remaining()>0) {
    byte PACKET_ID = network_data.get();
    println("PACKET: "+PACKET_ID);
    if (PACKET_ID == 0) NOTIFY_NEW_PLAYER();
  }
}

void NOTIFY_NEW_PLAYER() {
  int new_UUID = network_data.getInt();
  println("client: new player notification, UUID: "+new_UUID);
}

void readNetwork() {
  if (client.available()>0) {
    println("client: Reading "+client.available()+" bytes from TCP server");
    // Processing's methods for reading from server is not great
    // I'm using nio.ByteBuffer instead.
    // My concern is that in one 'client.available' session, there could
    // be some leftover data for the next packet, which we don't want to
    // discard. So all the data goes into a global 'server_data' ByteBuffer,
    // to which data is added successively, here.
    byte[] data_from_network = new byte[client.available()];
    client.readBytes(data_from_network);
    byte[] data_from_buffer = network_data.array();
    byte[] data_combined = new byte[data_from_network.length + network_data.remaining()];
    System.arraycopy(data_from_buffer, 0, data_combined, 0, data_from_buffer.length);
    System.arraycopy(data_from_network, 0, data_combined, data_from_buffer.length, data_from_network.length);
    network_data = ByteBuffer.wrap(data_combined);
  }
}
