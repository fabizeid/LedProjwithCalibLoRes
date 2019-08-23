import java.net.*;
import ddf.minim.*;
import java.nio.ByteBuffer;
Minim minim;
AudioPlayer groove;
AudioInput mic;
AudioSource audioSource;
AudioClient audioclient;
//String aip = "169.254.220.113";
//String aip = "192.168.0.111";
//String aip = "192.168.16.20";
String aip = "127.0.0.1";
final int aport = 7891;

String songPath = "C:/Users/farid/Desktop/Karen Music/Amy McDonald - This Is The Life.mp3";
String soundMode = "mic";//groove,mic,noSound

void setup() {
    minim = new Minim(this);
    if(soundMode.equals("mic")){
        mic = minim.getLineIn();
        audioSource = mic;
    } else if(soundMode.equals("groove")){
        groove = minim.loadFile(songPath);
        groove.loop();
        audioSource = groove;
    }
    audioclient = new AudioClient(aip,aport);
}

void draw() {
    //audioclient.send((byte)(audioSource.mix.level()*255));
    audioclient.send(audioSource.mix.level());
    delay(100);
}

public class AudioClient {

    int port;
    String ip;
    DatagramSocket socket;
    DatagramPacket packet;
    byte[] buf;

    AudioClient(String ip,int port){
        this.port = port;
        this.ip = ip;
        this.buf = new byte[4];
        // get a datagram socket
        try{
            this.socket = new DatagramSocket();
            InetAddress address = InetAddress.getByName(ip);
            this.packet = new DatagramPacket(buf, buf.length, address, port);
        } catch (SocketException e) {
            println("Socket Error");
        } catch (UnknownHostException e) {
            println("UnknownHostException");
        }
    }

//    void send(byte lvl){
//        buf[0] = lvl;
//        try{
//            socket.send(packet);
//        } catch (IOException e) {
//            println("IO Error");
//        }
//    }
    void send(float lvl){
        ByteBuffer.wrap(buf).putFloat(lvl);
        try{
            socket.send(packet);
        } catch (IOException e) {
            println("IO Error");
        }
    }
}
