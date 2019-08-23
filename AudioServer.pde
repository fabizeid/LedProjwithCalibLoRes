import java.net.*;
import java.nio.ByteBuffer;

public class AudioServer implements Runnable
{
    Thread thread;
    DatagramSocket socket;
    int port;
    byte[] buf;
    DatagramPacket packet;
    boolean listen;
    AudioServer(int port){
        this.port = port;
        this.socket = null;
        this.buf = new byte[4];
        listen = true;
        // receive request
        try{
            this.socket = new DatagramSocket(port);
        } catch (SocketException e) {
            println("Socket Error");
            return;
        }
        this.packet = new DatagramPacket(buf, buf.length);
        thread = new Thread(this);
        thread.start();
    }
    void dispose()
    {
        println("disposed socket");
        socket = null;
    }
    public float get(){
        //return (int)buf[0] & 0xFF;
        return ByteBuffer.wrap(buf).getFloat();
    }
    public void stopThread(){
        if(listen){
            listen = false; 
            socket.close();
        }
    }
    public void run() {
        while(listen){
            try {
                socket.receive(packet);
                //println(buf);
            }  catch (IOException e) {
                dispose();
            }
        }
        if(socket != null)
            socket.close();
    }
}

    
