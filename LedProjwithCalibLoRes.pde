//TODO make sure there is no leak due to use of get()
//TODO stay in vumode until motion is detected then start rolling through different modes every once and a while (contour on, grid on, both on, vu meter ...), motion detection could be triggered if a large enough contour is found.


final boolean isPI = false;
//PIIN
//import gohai.glvideo.*;
//PIIN
//GLVideo video;
//PIOUT
import processing.video.*;
//PIOUT
Capture video;
//Movie video;

import gab.opencv.*;
import org.opencv.imgproc.Imgproc;
import org.opencv.core.Size;
import org.opencv.core.MatOfDouble;
import org.opencv.core.Mat;
import org.opencv.core.CvType;
import org.opencv.core.Core;
import org.opencv.video.BackgroundSubtractorMOG;
import ddf.minim.*;

mOpenCV opencv;
Minim minim;
AudioPlayer groove;
AudioInput mic;
AudioSource audioSource;
OPC opc;
AudioServer audioserver;
PGraphics pg,pgPlot;
ArrayList<PVector> points;
final int nBimgs = 13*2;//13*2;
Mat[] bImgsMat,bImgsMatR,bImgsMatG,bImgsMatB,bImgsMatGray;
Mat matToFilterIn,matToFilterOut,matToFilterGray;
PImage ROIImg;
MatOfDouble mean;
MatOfDouble std;
final int[] ROIRange = {0,2};
int [] bImgsEnergy;
float [] bImgsMean,meanForT,meanForCalib;
float currentMean;
int[] lowEdgeT,highEdgeT,bilatSigmaT,levelColor,idxHist;
final int numlevelColors = 6;
final int noContoursToTrigger = 10;
int noContours = 0;
float calibLvl;
PImage bimg,paintImg,edgeImg,contImg,diffImg,backImg,inputImg;
PImage [] calibImg;
boolean getsnapshot,isInit;
int initIdx,capturedImgIdx;
int lastGestureCheck; //ms
int lastGestureSwitch; //ms
int[] lastRippleCheck = new int[2]; //ms
int gestureState;
int gestureSweepCount;
int lastBorderCheck; //ms
int borderWidth,borderColor,numLedOn,ledIntensity,bilatColorSigma;
BackgroundSubtractorMOG backgroundSubtractor;

//min supported res (also multiple of OPC grid)
final int h = 180;
final int w = 120;
final int vw = 320; //640;
final int vh = 240; //360;
final int fRate = 20;
String ip;
final int port = 7890;
final int aport = 7891;
final int numStrips = 24;
final int numLedPerStrip = 60;
boolean autoThreshold = true;
//Flame
final color from = color(250, 0, 0);
final color to = color(250, 216, 0);
//final String songPath = "C:/Users/farid/Desktop/Karen Music/Al Stewart - On The Border.mp3";
String songPath = "C:/Users/farid/Desktop/Karen Music/Amy McDonald - This Is The Life.mp3";
String moviePath = "C:/Users/farid/Pictures/Camera Roll/WIN_20190911_21_38_17_Pro.mp4";
//final String songPath = "C:/Users/farid/Desktop/Karen Music/Manu Chao - Desaparecido.mp3";
//final String songPath = "C:/Users/farid/Desktop/Karen Music/Tarkan - Dudu.mp3";
String soundMode = "mic";//groove,mic,noSound
//final String soundMode = "groove";//groove,mic,noSound
boolean useColor = false;
boolean initOPCGrid = true;
boolean camMode = false;
boolean debugMode = false;
boolean debugBackground = false;
boolean enablePaint = true;
boolean enableContour = true;
boolean enableGrid = true;
boolean stopLoop = false;
boolean saveContour = false;
char prevDetectionAlg, detectionAlg = 't'; //(c)alibrate (e)dge (m)otion (d)iff (o)ff (v)uemeter (t)riggered
char vuAlg = '6';
boolean calibrate = false;
boolean blur = false;
boolean printThreshold = false;
boolean printSLvl = false;
boolean printEnergy = false;
boolean oneShotPrint = false;
boolean useMeanforBg = true;
boolean useWheelColor = false;

int lowThresh;
int highThresh;
int minContourSize = 3000;
int numContoursToDraw = 5;
float dynRangefactor = 100;
float audioGain = 1;
final boolean enableGesture = false;
final int gestureIdx1 = 0;
final int gestureIdx2 = numLedPerStrip*(numStrips-1);
final int gestureCheckRate = 1000; //ms
final int gestureTimeout = 5000; //ms
final int borderCheckRate = 500; //ms
char lastKey = 0;
char tuneMode = 0;
char channelMode = 0;
Size ksize = new Size(3,3);


/*****************************************************************/
//Strip settings for vumeter
int numLedPerStrip_HALF = (numLedPerStrip/2);
int PEAK_FALL = 2; //Rate of falling peak dot
int SAMPLES = 60;  // Length of buffer for dynamic level adjustment
int TOP = (numLedPerStrip + 2); // Allow dot to go slightly off scale
float SPEED = .20;       // Amount to increment RGB color by each cycle
float
    vol[] = new float[SAMPLES],       // Collection of prior volume samples
    minLvlAvg = 0,      // For dynamic adjustment of graph low & high
    maxLvlAvg = .5;//512;
float
  greenOffset = 30,
  blueOffset = 150;
int volCount  = 0,      // Frame counter for storing past volume data
    currentStrip  = numStrips/2;
float maxVal;
int peak = 16;      // Peak level of column; used for falling dots
int peaks[] = new int[numStrips];
int dotCount = 0;  //Frame counter for peak dot
//Ripple variables
int peakspersec = 0, peakcount = 0;
int step = -1;
int ripColour,center = 0,bgcol = 0;
float lastLvl=0, lastDiff = 0;

/*****************************************************************/

void settings(){
    if(isPI)
        size(w*2,h*2,P2D);
    else
        size(w,h,P2D);
    noSmooth();

}

void setup() {
    background(0);
    pg = createGraphics(w, h);
    //PIOUT
    video = new Capture(this, vw,vh);
    //video = new Movie(this,moviePath);
    //PIOUT
    video.start();
    //video.loop();
    //PIIN
    //video = new GLVideo(this, "v4l2src extra-controls=c,brightness=60 ! video/x-raw, width=(int)"+w+", height=(int)"+h+", framerate=20/1", GLVideo.NO_SYNC);
    //video = new GLVideo(this, "v4l2src extra-controls=c,brightness=60,auto_exposure=1,exposure_time_absolute=262,white_balance_auto_preset=1 ! video/x-raw, width=(int)"+w+", height=(int)"+h+", framerate=20/1", GLVideo.NO_SYNC);
    //video = new GLVideo(this, "v4l2src extra-controls=c,contrast=10,auto_exposure=1,exposure_time_absolute=300,white_balance_auto_preset=1 ! video/x-raw, width=(int)"+w+", height=(int)"+h+", framerate=20/1", GLVideo.NO_SYNC);

    //video = new GLVideo(this, "v4l2src ! video/x-raw, width=(int)"+w+", height=(int)"+h+", framerate=20/1", GLVideo.NO_SYNC);

    //PIIN
    //video.play();


    if(isPI){
        ip = "127.0.0.1";
    } else {

        ip = "193.168.16.29";
    }

    opencv = new mOpenCV(this, w, h);
    opc = new OPC(this, ip, port);
    opc.setInterpolation(false);
    frameRate(fRate);
    isInit = true;
    initIdx = 0;
    capturedImgIdx = -1;
    bimg = createImage(w,h,ARGB);
    paintImg = createImage(w,h,RGB);//createBlackImage(w,h);
    edgeImg = createImage(w,h,ARGB);
    diffImg  = createImage(w,h,ALPHA);
    backImg  = createImage(w,h,ALPHA);
    inputImg  = createImage(w,h,ARGB);
    ROIImg = createImage(w,ROIRange[1]-ROIRange[0],ARGB);
    mean = new MatOfDouble();
    std = new MatOfDouble();

    lastGestureCheck = millis();
    lastBorderCheck = millis();
    lastRippleCheck[0] = lastRippleCheck[1] = millis();
    gestureState = 0;
    lastGestureSwitch = lastGestureCheck;
    gestureSweepCount = 0;
    //Start audio
    minim = new Minim(this);
    if(soundMode.equals("mic")){
        mic = minim.getLineIn();
        audioSource = mic;
    } else if(soundMode.equals("groove")){
        groove = minim.loadFile(songPath);
        groove.loop();
        audioSource = groove;
    } else if(soundMode.equals("net")){
            audioserver = new AudioServer(aport);
            audioSource = null;
    }
    maxVal = 0;
    borderWidth = 0;
    borderColor = 250;
    //borderColor = 0;
    ledIntensity = 0;
    numLedOn = 0;
    levelColor = new int[numlevelColors];
    idxHist = new int[numlevelColors];
    for (int i=0; i<numlevelColors; i++){
        levelColor[i] = lerpColor(from, to,(float)i/numlevelColors);
        idxHist[i] = 0;
    }
    bilatColorSigma = 25;
}

void setOPCGrid(){
    float spacing = h / numLedPerStrip;
    opc.showLocations(false);
    opc.reset();
   // opc.ledGrid(0, numLedPerStrip,numStrips, (float)w/2, (float)h/2,
   //           spacing, spacing, HALF_PI,false,
   //             true);
    opc.ledGrid(0, numLedPerStrip,numStrips, (float)w/2, (float)h/2,
                spacing, spacing,-HALF_PI,false,
                true);

}

Mat getCurrentMat()
{
    if(opencv.getUseColor()){
        return opencv.matBGRA;
    } else{
        return opencv.matGray;
    }

}
void draw() {


   if(initOPCGrid) {
       setOPCGrid();
       initOPCGrid = false;
   }


   if(isInit){
       background(0);
       if(detectionAlg == 'm') {
           //opencv.startBackgroundSubtraction(15, 3, 0.5);
           backgroundSubtractor = new BackgroundSubtractorMOG(15, 3, .5);
           println("Init motion");
           isInit = false;
       } else if (detectionAlg == 'd'|| detectionAlg == 't'){
           initDiffAlgorithm();
           lowThresh = 20;
           highThresh = 40;
       } else if (detectionAlg == 'e'){
           resetCalibForEdge();
           lowThresh = 75;
           highThresh = 145;
           //matToFilter = mOpenCV.imitate(getCurrentMat());
           matToFilterIn =  new Mat(getCurrentMat().height(), getCurrentMat().width(),CvType.CV_8UC3);
           matToFilterOut = mOpenCV.imitate(matToFilterIn);
           matToFilterGray = mOpenCV.imitate(opencv.getGray());
           isInit = false;
       } else if (detectionAlg == 'c'){
           captureImgsforCalibration();
       } else {
           isInit = false;
       }
       if(borderWidth > 0) border('w');
       oneShotPrint = false;
       return;
    }


   float lvl;

    if(soundMode.equals("noSound")){
        lvl = 0;
    } else if(soundMode.equals("test")){
        lvl = random(0,1);
    } else if(soundMode.equals("net")){
        lvl = audioserver.get();
        dynRange(lvl);
    } else {
        lvl = audioSource.mix.level();
        dynRange(lvl);
    }

    if(detectionAlg == 'v') {
        background(0);
        runVuAlg(lvl);
        return;
    }

    getNextVideoFrame();
    if (camMode){
        disp(bimg);
        return;
    }
    if(capturedImgIdx < 0)
        opencv.loadImage(bimg);
    else{ //for calibration
        opencv.loadImage(calibImg[capturedImgIdx]);
    }
    if(detectionAlg == 'm')
        runMotionDetectionAlgorithm();
    else if (detectionAlg == 'e')
        runEdgeAlgorithm(lvl);
    else if (detectionAlg == 't'){
        //runTriggeredAlgorithm(lvl);
        if(runDiffAlgorithm(true)) {
            runVuAlg(lvl);
            if(borderWidth > 0) border('w');
            return;}
    }
    else if (detectionAlg == 'd'){
        runDiffAlgorithm(false);
    }
    else if (detectionAlg == 'c')
        calibrateLED();

    //  if(printSLvl)
    //    println("Sound lvl: ",lvl*audioGain);

    //image(opencv.getOutput(),0,0);
    //if(true) return;
    if(saveContour){
        PImage saveImg = opencv.getOutput();
        saveImg.save("data/initbackground");
        println("saved background");
        saveContour = false;
    }

    if(enableContour) contourAudio(lvl);
    if(numLedOn > 0) spread(numLedOn,ledIntensity,numLedPerStrip/3,0);
    if(borderWidth > 0) border('w');
    oneShotPrint = false;
}
void keyPressed() {
    delay(100);
    dispatch();
}

void resetCalibrateLED(){
    if(pgPlot == null){
        pgPlot = createGraphics(w, h);
    }
    pgPlot.beginDraw();
    pgPlot.background(0);
    pgPlot.stroke(250);
    pgPlot.strokeWeight(2);
    pgPlot.endDraw();
    println("resetCalibrateLED");

}

void insertPlotData()
{
    if(pgPlot == null)resetCalibrateLED();
    pgPlot.beginDraw();
    //float x = (float)numLedOn*w/((numStrips-1)*numLedPerStrip*2/3);
    float x = (float)ledIntensity*w/255;
    float y = currentMean*h/255;
    pgPlot.line(x,h,x,h-y);
    pgPlot.endDraw();
    println("numLedOn",numLedOn,"ledIntensity",ledIntensity,"currentMean",currentMean);
}
void calibrateLED() {
    //if(numLedOn > 0) spread(numLedOn,ledIntensity,numLedPerStrip/3,0);
    currentMean = (float)Core.mean(opencv.getGray()).val[0];
    if(debugMode){
        if(pgPlot == null)resetCalibrateLED();
        image(pgPlot,w,0);
    }



}

void runMotionDetectionAlgorithm(){
    //opencv.updateBackground();
        backgroundSubtractor.apply(opencv.getGray(), opencv.getGray(), 0.001);
        if(debugMode){
            image(opencv.getOutput().get(),w,0);
        }

}

//TODO unify code to calc mean, std,channels,and lookup for thresholds
//for diff and edge alg
//get mean,std of ROI
//get Idx closest

//void test(){
//    Core.meanStdDev(opencv.matGray.rowRange(ROIRange[0],ROIRange[1]),mean,std);
//    float fstd = (float)std.get(0,0)[0];
//    if(fstd > 10){
//        println((float)mean.get(0,0)[0],fstd);
//        return true;
//    }
//    int i =  getMeanIdx(opencv.matGray.rowRange(ROIRange[0],ROIRange[1]));
//
//    // copies specified channel to gray channel
//    // useChannel(channelMode);
//
//    //
//}

void runTriggeredAlgorithm(float lvl){
    runEdgeAlgorithm(lvl);
    if(noContours == noContoursToTrigger){
        runVuAlg(lvl);
    }
}
void runEdgeAlgorithm(float lvl){
    //Could use mean of whole image instead of ROI since calibration happens
    // with someone standing in front of screen. But wouldn't hurt trying
    //with ROI too
    if(useColor)
        opencv.useColor();
    else
        opencv.useGray();
    //getGray is empty if useColor is true when image is loaded into
    //opencv. Since we are always switching to gray before switching
    //to color, we're fine here.
    //TODO figure out if best is to use ROI mean or full image mean
    //currentMean = (float)Core.mean(opencv.getGray()).val[0];
    currentMean = (float)Core.mean(opencv.getGray().rowRange(ROIRange[0],ROIRange[1])).val[0];

    if(!calibrate && lowEdgeT.length != 0){
        int i = getMeanFloorIdx(currentMean,meanForT);
        //TODO if needed: interpolate between i and i+1 values of thresholds
        lowThresh = lowEdgeT[i];
        highThresh = highEdgeT[i];
        bilatColorSigma = bilatSigmaT[i];
        if(printThreshold) println(i,currentMean,meanForT[i],lowEdgeT[i],highEdgeT[i]);
    } else if(autoThreshold) {
        //from http://justin-liang.com/tutorials/canny/
        //highThreshold = max(max(im))*highThresholdRatio;
        //lowThreshold = highThreshold*lowThresholdRatio;
        // also https://www.quora.com/How-do-I-set-the-upper-and-lower-threshold-in-canny-edge-detection
        //https://docs.opencv.org/3.0-beta/doc/py_tutorials/py_imgproc/py_thresholding/py_thresholding.html
        //Perform OTSU segmentation on your image.
        //upperthresh=OTSU(inputgrayscaleimage)
        //lowerthresh=0.5*upperthresh
        //from:https://www.pyimagesearch.com/2015/04/06/zero-parameter-automatic-canny-edge-detection-with-python-and-opencv/
        //v = np.median(image)
        //sigma=0.33)
	//# apply automatic Canny edge detection using the computed median
	//lower = int(max(0, (1.0 - sigma) * v))
	//upper = int(min(255, (1.0 + sigma) * v))
	//edged = cv2.Canny(image, lower, upper)
        //opencv.findCannyEdges(lowThresh,(int)currentMean);
    } else {

    }
    if(blur && bilatColorSigma > 0){
        if(useColor){
            Imgproc.cvtColor(getCurrentMat(),matToFilterIn,Imgproc.COLOR_BGRA2BGR);
            Imgproc.bilateralFilter(matToFilterIn, matToFilterOut, -1,bilatColorSigma*3,5);
            Imgproc.cvtColor(matToFilterOut,getCurrentMat(),Imgproc.COLOR_BGR2BGRA);
        } else {
            opencv.getGray().copyTo(matToFilterGray);
            Imgproc.bilateralFilter(matToFilterGray, getCurrentMat(), -1,bilatColorSigma,5);
        }
    }

    if(debugMode){
        inputImg.copy(opencv.getOutput(),0,0,w,h,0,0,w,h);
        image(inputImg,w,0);
    }

    opencv.findCannyEdges(lowThresh,highThresh);
    if(oneShotPrint){
        println("mean",currentMean, "lowT",lowThresh,"highT",highThresh,"bilat (x3 for color)",bilatColorSigma);
    }
    opencv.useGray();
    opencv.dilate();
    //opencv.erode();
    if(debugMode){
        diffImg.copy(opencv.getOutput(),0,0,w,h,0,0,w,h);
        image(diffImg,0,h);
    }

    if(detectionAlg == 't' && noContours == noContoursToTrigger){
        return; //don't display as we are using display for vuAlg
    }

    if(enablePaint) paint();
    if(enableGrid) mapToGrid(opencv.getOutput(),edgeImg,lvl);
}

void resetCalibForEdge(){
    meanForT = new float[0];
    lowEdgeT = new int[0];
    highEdgeT = new int[0];
    bilatSigmaT = new int[0];
    println("Resetting Calib Arrays");
}

void insertAndSortCalibForEdge(){
    float[] tempM = meanForT;
    int[] tempL = lowEdgeT;
    int[] tempH = highEdgeT;
    int[] tempB = bilatSigmaT;
    meanForT = new float[tempM.length+1];
    lowEdgeT = new int[tempL.length+1];
    highEdgeT = new int[tempH.length+1];
    bilatSigmaT = new int[tempB.length+1];
    int i, j;
    float meanDiff;
    boolean notInsterted = true;
    for(i = 0, j = 0; i<tempM.length;i++,j++){
        if(notInsterted && (currentMean < tempM[i])){
            meanForT[j] = currentMean;
            lowEdgeT[j] = lowThresh;
            highEdgeT[j] = highThresh;
            bilatSigmaT[j] = bilatColorSigma;
            j++;
            notInsterted = false;
        }

        meanForT[j] = tempM[i];
        lowEdgeT[j] = tempL[i];
        highEdgeT[j] = tempH[i];
        bilatSigmaT[j] = tempB[i];
    }

    if(notInsterted) {//not inserted yet
        meanForT[j] = currentMean;
        lowEdgeT[j] = lowThresh;
        highEdgeT[j] = highThresh;
        bilatSigmaT[j] = bilatColorSigma;
    }
    printArray(meanForT);
    println("inserting ",currentMean,lowThresh,highThresh,bilatColorSigma);


}

void loadCalibForEdge(char alg){

    String fname;
    if(alg == 'e')
        fname = "edgeCalib.csv";
    else
        fname = "diffCalib.csv";

    Table table = loadTable(fname, "header");
    int numRows = table.getRowCount();
    meanForT = new float[numRows];
    lowEdgeT = new int[numRows];
    highEdgeT = new int[numRows];
    bilatSigmaT = new int[numRows];
    int i = 0;
    for (TableRow row : table.rows()) {
        meanForT[i] = row.getFloat("mean");
        lowEdgeT[i] = row.getInt("lowThresh");
        if(alg == 'e'){
            highEdgeT[i] = row.getInt("highThresh");
            bilatSigmaT[i] = row.getInt("bilatColorSigma");
        }
        i++;
    }
    println("Loaded data/"+fname);
    printArray(meanForT);
}

void saveCalibForEdge(char alg){
    String fname;
    if(alg == 'e')
        fname = "edgeCalib.csv";
    else
        fname = "diffCalib.csv";


    Table table = new Table();
    table.addColumn("mean");
    table.addColumn("lowThresh");
    if(alg == 'e'){
            table.addColumn("highThresh");
            table.addColumn("bilatColorSigma");
    }
    TableRow newRow;

    for( int i = 0; i<lowEdgeT.length;i++){
        newRow = table.addRow();
        newRow.setFloat("mean", meanForT[i]);
        newRow.setInt("lowThresh", lowEdgeT[i]);
        if(alg == 'e'){
            newRow.setInt("highThresh", highEdgeT[i]);
            newRow.setInt("bilatColorSigma", bilatSigmaT[i]);
        }
    }
    saveTable(table, "data/"+ fname);
    println("saving to data/"+ fname);
}

void printCalibForEdge(){
    println("mean lowThresh highThresh bilatColorSigma");
    for( int i = 0; i<lowEdgeT.length;i++){
        println(meanForT[i],lowEdgeT[i],highEdgeT[i],bilatSigmaT[i]);
    }
}


boolean runDiffAlgorithm(boolean isTriggered){

    int i,threshScale = 1;
    if(useMeanforBg){
        //First detect if intrusion in ROI area
        //if stddev increases on diff of ROI, intrusion is
        // detected, turn off processing until no more intrusion
        //TODO: absdiff ROI with last selected background ROI
        Core.meanStdDev(opencv.matGray.rowRange(ROIRange[0],ROIRange[1]),mean,std);
        float fstd = (float)std.get(0,0)[0];
        if(false && fstd > 10){
            println((float)mean.get(0,0)[0],fstd);
            return true;
        }
        Mat currentImg = opencv.matGray.rowRange(ROIRange[0],ROIRange[1]);
        currentMean = (float)Core.mean(currentImg).val[0];
        i = getMeanRoundIdx(currentMean,bImgsMean);
    } else
        i = getBackgroundEnergyIdx();
//    if(debugMode){
//      opencv.toPImage(opencv.matGray.rowRange(ROIRange[0],ROIRange[1]),ROIImg);
//      image(ROIImg,w,h);
//    }
    if(debugMode){
        inputImg.copy(opencv.getOutput(),0,0,w,h,0,0,w,h);
        image(inputImg,w,0);
    }

    if(channelMode == 'm'){
        threshScale = 2;
        if(blur){
            Imgproc.GaussianBlur(opencv.getR(), opencv.getR(), ksize, 2, 2);
            Imgproc.GaussianBlur(opencv.getG(), opencv.getG(), ksize, 2, 2);
            Imgproc.GaussianBlur(opencv.getB(), opencv.getB(), ksize, 2, 2);
        }
        mOpenCV.diff(opencv.getR(),bImgsMatR[i]);
        mOpenCV.diff(opencv.getG(),bImgsMatG[i]);
        mOpenCV.diff(opencv.getB(),bImgsMatB[i]);
        //Core.max(opencv.getR(),opencv.getG(),opencv.getGray());
        //Core.max(opencv.getGray(),opencv.getB(),opencv.getGray());
        Core.add(opencv.getR(),opencv.getG(),opencv.getGray());
        Core.add(opencv.getGray(),opencv.getB(),opencv.getGray());
    } else {
        switch(channelMode){
        case 'r':
            opencv.setGray(opencv.getR());
            //mOpenCV.diff(opencv.getGray(),bImgsMat[i]);
            break;
        case 'g':
            opencv.setGray(opencv.getG());
            break;
        case 'b':
            opencv.setGray(opencv.getB());
            break;
        }
        if(blur){
            Imgproc.GaussianBlur(opencv.getGray(), opencv.getGray(), ksize, 2, 2);
        }

        //bimg = bImgs[i];
        //opencv.diff(bimg);
        //    if(channelMode == 'o'){ //color
        //      mOpenCV.diff(opencv.matBGRA,bImgsMat[i]);
        //      //matBGRA holds the diff, convert to gray
        //      //TODO: possible instead of converting to gray just
        //      //diff and threshold on each channel independently
        //      //then merge the channels by adding the them,
        //      opencv.gray();
        //    } else
        mOpenCV.diff(opencv.getGray(),bImgsMat[i]);
    }
    if(debugMode){
        diffImg.copy(opencv.getOutput(),0,0,w,h,0,0,w,h);
        image(diffImg,0,h);
      }
    //opencv.gray();
    if(calibrate){
        opencv.threshold(lowThresh);
    }
    else if(autoThreshold) {
    //TODO cutoff should depend on luminosity
        highThresh = (int)opencv.thresholdret();
        if(printThreshold){
            println("Threshold lvl:  ",highThresh);
        }
        if (highThresh < lowThresh*threshScale) return true;
    } else if(lowEdgeT.length != 0){
        int j = getMeanFloorIdx(currentMean,meanForT);
        lowThresh = lowEdgeT[j];
        opencv.threshold(lowThresh);
    } else {
        //TODO: add getting thresholds from lookup table
        // based of mean of ROI (similar to edge detection)
        opencv.threshold(lowThresh);
    }


    if(false & oneShotPrint){
        println(lowThresh,currentMean);
    }

    if(debugMode){
        if(debugBackground){
            opencv.toPImage(bImgsMat[i],backImg);
            image(backImg,w,h);
        } else {
            image(opencv.getOutput(),w,h);
        }
    }
    opencv.dilate();
    opencv.erode();
    if(enablePaint) paint();
    return false;
}


void mapToGrid(PImage img){
    int picIdx,imgPicIdx,pixel;
    int numPixels = opc.pixelLocations.length;
    color c = color(255,0,0);
    loadPixels();
    img.loadPixels();
    for (int i = 0; i < numPixels; i++) {
        picIdx = opc.pixelLocations[i];
        imgPicIdx = picIdx-(width-img.width)*(picIdx/width);
        pixel = img.pixels[imgPicIdx];
        if(pixel == 0xFFFFFFFF)
            pixels[picIdx] = c;
    }
    updatePixels();
}
void mapToGrid(PImage imgSrc,PImage imgDest,float lvl){
    int picIdx,imgPicIdx,pixel;
    int circIdx = 0;
    int numPixels = opc.pixelLocations.length;
    setColorMode("RGB");
    color c = color(255,0,0);
    imgDest.loadPixels();
    imgSrc.loadPixels();
    //lvl = map(lvl, minLvlAvg,maxLvlAvg,0,numlevelColors);
    //lvl *= audioGain;
    //lvl = (int)round(constrain(lvl,0,numlevelColors));
    lvl *= audioGain;
    lvl = map(lvl, minLvlAvg,maxLvlAvg,30,150);

    //println(pixels.length,img.pixels.length);
    for (int i = 0; i < numPixels; i++) {
        picIdx = opc.pixelLocations[i];
        imgPicIdx = picIdx-(width-imgSrc.width)*(picIdx/width);
        pixel = imgSrc.pixels[imgPicIdx];
        if(pixel == 0xFFFFFFFF){
            //imgDest.pixels[imgPicIdx] = 0xFFAA0000;//levelColor[0];//0xFFFF0000;
            imgDest.pixels[imgPicIdx] = Wheel(lvl,map(lvl, 30,150,.4,1));//.6
            //for (int j=0; j<lvl ;j++) {
            //    int curIdx = (circIdx-j/2);
            //    if (curIdx < 0) curIdx += numlevelColors;
            //    int histIdx = idxHist[curIdx];
            //    imgDest.pixels[histIdx] = levelColor[j];

                //imgDest.pixels[idxHist[(circIdx-j)%numlevelColors]]
                //    = levelColor[j];
            //}

        } else {
              imgDest.pixels[imgPicIdx] = 0x00000000;
        }

        circIdx = (circIdx+1)%numlevelColors;
        idxHist[circIdx] = imgPicIdx;

    }
    imgDest.updatePixels();
    //TODO add switch to turn this on or off
    disp(imgDest);
}

void spread(int numLed, int intensity,int startRow, int startCol){
    int picIdx;
    int numPix = opc.pixelLocations.length;
    setColorMode("RGB");
    color c = color(intensity,0,0);
    loadPixels();
    int y = startRow;//numLedPerStrip/2;
    int x = startCol;
    for (int j = 0; j < numLed;j++)
        {
            //println(numPix,y,x,y + numLedPerStrip*x);

            picIdx = opc.pixelLocations[ y + numLedPerStrip*x];
            pixels[picIdx] = c; //color(intensity);
            if(++x ==  numStrips) {
                x = 0;
                y++;
            }
        }
    updatePixels();

}
void border(){
    border('r');
}
void border(char col){
    //if(true) return;
    //int now = millis();
    float spacing = h / numLedPerStrip;
    int picIdx = opc.pixelLocations[opc.pixelLocations.length-1];
    strokeWeight((2*borderWidth-1)*spacing+1); // 2-4,3-7,4-10

    if(col == 'r')
        stroke(borderColor, 0, 0);
    else
        stroke(borderColor, borderColor, borderColor);
    noFill();
    int xr = picIdx % w;
    int yr = picIdx / w;
    int wr = (int)spacing*(numStrips-1)+1;
    int hr = (int)spacing*(numLedPerStrip-1)+1;
    //circle(w/2,h/2,w/4);

    //rect(xr,yr,wr,hr);
    line(xr,yr,xr+wr,yr);
    //line(xr,yr+hr,xr+wr,yr+hr);
}
void paint(){
    setColorMode("HSB");
    PImage pic = opencv.getOutput();
    int pixel;
    pic.loadPixels();
    paintImg.loadPixels();
    float hue = (millis() * .1) % 360;
    color c = color(hue, 50,100);
    int numPixels = opc.pixelLocations.length;
    int picIdx;
    for (int i = 0; i < numPixels; i++) { //loop over grid instead of looping everything
        picIdx = opc.pixelLocations[i];
        picIdx = picIdx-(width-pic.width)*(picIdx/width);
        //picIdx = picIdx % width + pic.width*(picIdx / width);
        pixel = pic.pixels[picIdx];
        if(pixel == 0xFFFFFFFF) {
            pixel = c;
            //pixel = 0xFF00FFFF;
            if (enableGesture && (i == gestureIdx1 || i == gestureIdx2)) {
                checkGesture(i,true);
                pixel = 0xFFFFFFFF;
            }

        } else {
            pixel = paintImg.pixels[picIdx];
            if(brightness(pixel) != 0){
                pixel = color(hue(pixel),saturation(pixel),brightness(pixel)-5);
            }
            if (enableGesture && (i == gestureIdx1 || i == gestureIdx2)) {
                checkGesture(i,false);
                pixel = 0xFFFFFFFF;
            }
        }
        paintImg.pixels[picIdx] = pixel;
    }
    paintImg.updatePixels();
    disp(paintImg);
}

void checkGesture(int pixIdx,boolean pixelOn){
    int now = millis();
    if(now < lastGestureCheck + gestureCheckRate) return;
    if(pixIdx == gestureIdx2) lastGestureCheck = now;

    switch (gestureState) {
    case 0: // init
        if (pixIdx == gestureIdx1 && pixelOn){
            gestureState = 1;
            lastGestureSwitch = now;
            println(gestureState);
        }
        break;
    case 1:
        if (pixIdx == gestureIdx1 && !pixelOn){
            gestureState = 2;
            lastGestureSwitch = now;
            println(gestureState);
        }
        break;
    case 2:
        if (pixIdx == gestureIdx2 && pixelOn){
            gestureState = 3;
            lastGestureSwitch = now;
            println(gestureState);
        }
        break;
    case 3:
        if (pixIdx == gestureIdx2 && !pixelOn){
            gestureState = 0;
            if(gestureSweepCount++ == 3){
                gestureSweepCount = 0;
                enableContour = !enableContour;
                println("trigger");
            }
            println("count",gestureSweepCount);

        }
        break;
    default:
        break;
    }
    if(gestureState != 0 && now > lastGestureSwitch + gestureTimeout) {
        gestureState = 0;
        gestureSweepCount = 0;
        println("gesture timout");
    }
}
void contourAudio(float lvlArg) {
    float lvl;
    int colr;
    setColorMode("RGB");
    pg.beginDraw();
    pg.noFill();
    //pg.fill(255,0,0);
    getsnapshot = false;
    if(useWheelColor){
        lvl = map(lvlArg,minLvlAvg,maxLvlAvg,0.4,1);
        colr = Wheel(map(lvlArg,minLvlAvg,maxLvlAvg,30+50,150+50),lvl);
    } else {
        lvl = map(lvlArg,minLvlAvg,maxLvlAvg,0,1);
        colr = lerpColor(from, to,lvl);
    }

    lvl *= audioGain;
    if(lvl > 1) { //turn off for now
        pg.stroke(90,90,90);
        getsnapshot = true;
        useWheelColor = !useWheelColor;
        pg.strokeWeight(3);
    }
    else if(lvl < .2){
        pg.stroke(colr);
        //pg.stroke(250,0,0);
        pg.strokeWeight(3);
    }
    else{
        pg.stroke(colr);
        pg.strokeWeight(3+lvl*3);
    }


    pg.background(0,0);
    pg.tint(255, 250);
    if(contImg != null)
        pg.image(contImg,-3,-5,pg.width+7,pg.height+7);
    if(!getsnapshot) contImg = pg.get();//get img before current contour
    Mat tempMat = opencv.getGray();
    boolean hasContour = false;

    ArrayList<Contour> contours = opencv.findContours(false,true);
    for (int i = 0; i < contours.size(); i++ ) {
        if (i > numContoursToDraw) break;
        Contour contour = contours.get(i);
        if (contour.area() < minContourSize) break;
        points = contour.getPoints();
        pg.beginShape();
        for (PVector p : points) {
            pg.vertex(p.x, p.y);
        }
        pg.endShape(PConstants.CLOSE);
        hasContour = true;
    }

    pg.endDraw();
    if(getsnapshot) contImg = pg.get(); //get img after contour
    if(hasContour)
        noContours = 0;
    else if (noContours <  noContoursToTrigger) {
        noContours++;
    }

    if(detectionAlg == 't' && noContours == noContoursToTrigger){
        return; //don't display as we are using display for vuAlg
    }
    disp(contImg);
    disp(pg);
}

void setColorMode(String mode) {
    if(mode.equals("HSB")){
        colorMode(HSB, 360,100,500);
    } else {
        colorMode(RGB, 255,255,255);
    }
}

void disp(PImage vid) {
    //if(xflip)
    //      image(vid, 0, 0,width,height,width,0,0,height );
    //  else
    if(calibrate){
        image(vid,w,h);
    } else {
        image(vid,0,0);
    }
    //float dispScale = .9;
    //image(vid,w*(1-dispScale)/2,h*(1-dispScale)/2,w*dispScale,h*dispScale);
}

void getNextVideoFrame(){
    if (video.available() ) {
        background(0);
        video.read();
        //println(video.width,video.height);
        if(isPI) {
            bimg.copy(video,0,0,w,h,0,0,w,h);
        } else {
            int croppedW = w*vh/h;
            bimg.copy(video,(vw-croppedW)/2,0,croppedW,vh,0,0,w,h);
        }
    }
    //else {
    //      return;
    //}
}

void liveImg(){
    capturedImgIdx = -1;
    println("Live");
}
void prevImg(){
    if(calibImg == null){
        println("No captured images");
    } else {
        if(capturedImgIdx > 0){
            capturedImgIdx--;;
            println("frame",capturedImgIdx);
        }
        else
            println("reached beginning frames");
    }
}

void nextImg(){
    if(calibImg == null){
        println("No captured images");
    } else {
        if(capturedImgIdx < calibImg.length-1){
            capturedImgIdx++;
            println("frame",capturedImgIdx);
        }
        else
            println("reached end frames");
    }
}

void captureImgsforCalibration(){
    if (initIdx == 0){
        calibImg = new PImage[nBimgs];
        meanForCalib = new float[nBimgs];
        //always capture colored images
        opencv.useColor();
    } else if(initIdx == nBimgs) {
        detectionAlg = prevDetectionAlg;
        initIdx = 0;
        isInit = false;
        sortImgs(meanForCalib,calibImg);
        //revert to colormode
        if(!useColor) opencv.useGray();
        return;
    }

    delay(500);
    getNextVideoFrame();
    opencv.loadImage(bimg);
    Mat matGray = mOpenCV.gray(opencv.matBGRA);
    meanForCalib[initIdx] = (float)Core.mean(matGray.rowRange(ROIRange[0],ROIRange[1])).val[0];
    calibImg[initIdx] = bimg.get();
    if(debugMode){
        image(opencv.getOutput(),w,0);
    }
    spread((initIdx+1)*numStrips,100,numLedPerStrip/3,0);
    println("Capture",initIdx,"Mean",meanForCalib[initIdx]);
    initIdx++;
}
void initDiffAlgorithm(){
    if (!video.available() ){
        delay(10);
        return;
    }

    video.read();
    if(isPI) {
        bimg.copy(video,0,0,w,h,0,0,w,h);
    } else {
        int croppedW = w*vh/h;
        bimg.copy(video,(vw-croppedW)/2,0,croppedW,vh,0,0,w,h);
    }

    final int initCount = 10;
    //Ramping up picam to get the first image
    if (initIdx < initCount){
        initIdx++;
        delay(10);
        return;
    }

    if (initIdx == initCount){
        calibLvl = 0;
        resetCalibForEdge();
        lowThresh = 44;
        highThresh = 0;//not used here
        //get array of baseline backgrounds
        //with increasing luminosity
        bImgsEnergy = new int[nBimgs];
        bImgsMean = new float[nBimgs];
        bImgsMatR = new Mat[nBimgs];
        bImgsMatG = new Mat[nBimgs];
        bImgsMatB = new Mat[nBimgs];
        bImgsMatGray = new Mat[nBimgs];
        bImgsMat = bImgsMatGray;

    }

    if (initIdx < initCount + nBimgs) {
        int i = initIdx - initCount;


        initIdx++;
        /*********************************************
        spread((int)calibLvl,250,numLedPerStrip/2,0);
        //background(calibLvl);
        //borderWidth = (int)calibLvl;
        //if(borderWidth > 0) border('r');
        delay(500);
        opencv.loadImage(bimg);
        bImgsMatGray[i] = mOpenCV.imitate(opencv.getGray());
        opencv.getGray().assignTo(bImgsMatGray[i]);
        if(debugMode){
            image(opencv.getOutput().get(),w,h);
        }
        bImgsEnergy[i] = opc.getLEDEnergy();
        //bImgsMean[i] = (float)Core.mean(opencv.getGray()).val[0];
        //bImgsMean[i] = (float)Core.mean(new Mat(opencv.getGray(),ROI)).val[0];
        bImgsMean[i] = (float)Core.mean(opencv.matGray.rowRange(ROIRange[0],ROIRange[1])).val[0];
        println(bImgsEnergy[i],bImgsMean[i],calibLvl);
        calibLvl += numStrips;//10/nBimgs;
        if(true) return;

        /******************************************/
        PImage calibImg =loadImage("initbackground.tif");
        opencv.loadImage(calibImg);

        bImgsEnergy[i] = opc.getLEDEnergy();

        // last contour is not recorded
        // float l = map((float)i/(nBimgs-2),0,1,0,1.4);
        //contourAudio(.2+calibLvl);
        //calibLvl += .1;
        spread((int)calibLvl,220,numLedPerStrip/3,0);
        calibLvl += 24;
        delay(500);
        //Current camera snapshot corresponds to previous
        //contour update. Since LED screen is updated after draw function
        opencv.loadImage(bimg);
        //bImgsMean[i] = (float)Core.mean(opencv.getGray()).val[0];
        bImgsMean[i] = (float)Core.mean(opencv.matGray.rowRange(ROIRange[0],ROIRange[1])).val[0];
        println(bImgsMean[i]);
        //new Mat(m.height(), m.width(), m.type());
        bImgsMatR[i] = mOpenCV.imitate(opencv.getR());
        bImgsMatG[i] = mOpenCV.imitate(opencv.getG());
        bImgsMatB[i] = mOpenCV.imitate(opencv.getB());
        bImgsMatGray[i] = mOpenCV.imitate(opencv.getGray());
        if(blur){
            Imgproc.GaussianBlur(opencv.getR(), bImgsMatR[i], ksize, 2, 2);
            Imgproc.GaussianBlur(opencv.getG(), bImgsMatG[i], ksize, 2, 2);
            Imgproc.GaussianBlur(opencv.getB(), bImgsMatB[i], ksize, 2, 2);
            Imgproc.GaussianBlur(opencv.getGray(), bImgsMatGray[i], ksize, 2, 2);
        } else {
            opencv.getR().assignTo(bImgsMatR[i]);
            opencv.getG().assignTo(bImgsMatG[i]);
            opencv.getB().assignTo(bImgsMatB[i]);
            opencv.getGray().assignTo(bImgsMatGray[i]);
        }

        if(debugMode){
            image(opencv.getOutput().get(),w,h);
        }

        //bImgsMatBGRA[i] = mOpenCV.imitate(opencv.matBGRA);
        //opencv.matBGRA.assignTo(bImgsMatBGRA[i]);
        return;
    }
    //sort energy and mean levels and backgrounds
    sortImgs(bImgsMean,bImgsMatGray);
    initIdx = 0;
    isInit = false;
}

int getMeanFloorIdx(float meanVal,float [] meanArr){
    //Used for selecting thresholds of Edgedetector
    //pick the element that's below the meanVal (don't pick closest)
    //that's assuming that calibration started from low mean to high mean
    int i = 1;
    while(i < meanArr.length && meanVal > meanArr[i]){
        i++;
    }
    return i - 1;
}
int getMeanRoundIdx(float meanVal,float [] meanArr){
    int i = 1;

    while(meanVal > meanArr[i]){
        i++;
        if(i == meanArr.length) {
            if(oneShotPrint){int idx = i-1; println(meanVal +" "+(meanArr[idx]-meanVal)+ " " + idx +" " + meanArr[idx]);}
            // println(meanVal,i-1);
            return i-1;
        }
    }
    if((meanArr[i]-meanVal) > (meanVal - meanArr[i-1])){
        //println(meanVal,i-1);
        if(oneShotPrint){int idx = i-1; println(meanVal +" "+ (meanArr[idx]-meanVal)+ " " + idx +" " + meanArr[idx] + " " +meanArr[i]);}

        return i-1;
    } else {
        //println(meanVal,i);
        if(oneShotPrint){int idx = i; println(meanVal +" "+ (meanArr[idx]-meanVal)+ " " + idx +" " + meanArr[idx-1] + " " +meanArr[idx]);}
        return i;
    }
}

int getBackgroundEnergyIdx(){
    int currentEnergy = opc.getLEDEnergy();
    int i = 1;

    while(currentEnergy > bImgsEnergy[i]){
        i++;
        if(i == bImgsEnergy.length) {
            if(printEnergy){int idx = i-1; println(currentEnergy +" "+(bImgsEnergy[idx]-opc.getLEDEnergy())+ " " + idx +" " + bImgsEnergy[idx]);}
            // println(currentEnergy,i-1);
            return i-1;
        }
    }
    if((bImgsEnergy[i]-currentEnergy) > (currentEnergy - bImgsEnergy[i-1])){
        //println(currentEnergy,i-1);
        if(printEnergy){int idx = i-1; println(currentEnergy +" "+ (bImgsEnergy[idx]-opc.getLEDEnergy())+ " " + idx +" " + bImgsEnergy[idx] + " " +bImgsEnergy[i]);}

        return i-1;
    } else {
        //println(currentEnergy,i);
        if(printEnergy){int idx = i; println(currentEnergy +" "+ (bImgsEnergy[idx]-opc.getLEDEnergy())+ " " + idx +" " + bImgsEnergy[idx-1] + " " +bImgsEnergy[idx]);}
        return i;
    }
}

public  class mOpenCV extends OpenCV{
    public mOpenCV(PApplet theParent, int width, int height) {
      super( theParent, width, height);
    }
    public float thresholdret() {
    return (float)(Imgproc.threshold(matGray, matGray, 0, 255, Imgproc.THRESH_BINARY | Imgproc.THRESH_OTSU));
    }
    public void findCannyEdges(int lowThreshold, int highThreshold){
        Imgproc.Canny(getCurrentMat(), getGray(), lowThreshold, highThreshold);
    }
}
void getChannel(PImage in, PImage out, int mask){

    //bimg = createImage(in.width,in.height,RGB);

    in.loadPixels();
    out.loadPixels();
     for (int i = 0; i < in.pixels.length; i++) {
         out.pixels[i] = in.pixels[i] & mask;//& 0x0000FF;
    }
     out.updatePixels();

}

void sortImgs(float[] meanArr, Mat[] matArr){

    // Sort int bImgsEnergy ,float meanArr, Mat matArr
    float tempMean;
    Mat tempImgs;
    if(useMeanforBg) { // else sort by energy
        for(int i = 1; i < meanArr.length; i++){
            for (int j = i; j > 0; j --){
                if(meanArr[j] < meanArr[j-1]){
                    //swap
                    tempMean = meanArr[j];
                    meanArr[j] = meanArr[j-1];
                    meanArr[j-1] = tempMean;
                    tempImgs = matArr[j];
                    matArr[j] = matArr[j-1];
                    matArr[j-1] = tempImgs;

                }
            }
        }
    }
}
void sortImgs(float[] meanArr, PImage[] imgArr){

    // Sort int bImgsEnergy ,float meanArr, Mat matArr
    float tempMean;
    PImage tempImgs;
    if(useMeanforBg) { // else sort by energy
        for(int i = 1; i < meanArr.length; i++){
            for (int j = i; j > 0; j --){
                if(meanArr[j] < meanArr[j-1]){
                    //swap
                    tempMean = meanArr[j];
                    meanArr[j] = meanArr[j-1];
                    meanArr[j-1] = tempMean;
                    tempImgs = imgArr[j];
                    imgArr[j] = imgArr[j-1];
                    imgArr[j-1] = tempImgs;

                }
            }
        }
    }
}

void runVuAlg(float lvl){
    switch(vuAlg) {
    case '1':
        vuOPC(lvl);
        break;
    case '2':
        vu1OPC(lvl);
        break;
    case '3':
        vu3OPC(lvl);
        break;
    case '4':
        waveOPC();
        break;
    case '5':
        wave();
        break;
    case '6':
        vu3mOPC(lvl);
        break;
    case '7':
        vuRipple(lvl);
        break;
    }
}

void waveOPC(){
    if(audioSource == null) return;
    int pixIdx,x;
    final int xOffset = numStrips/2;
    final int bufSamplingDivisor = 8;
    final float a = 50;
    float ratio,bufVal,valCol, maxlvl=0;
    loadPixels();
    for(int i=0; i<numLedPerStrip; i++) {
        //only sampling part of the buffer since sampling the whole buf will
        //produce too many antialiasing effects
        int bufIdx = (int)map(i,0,numLedPerStrip*bufSamplingDivisor,0,audioSource.bufferSize());
        bufVal = audioSource.mix.get(bufIdx);
        maxlvl = max(maxlvl,abs(bufVal));
        bufVal = bufVal*dynRangefactor*audioGain;
        x = xOffset+int(bufVal);
        x = constrain(x,0,numStrips-1);
        pixIdx = opc.pixelLocations[ i + numLedPerStrip*x];
        valCol = map(abs(bufVal),0,xOffset,30,150);
        if(valCol > 200) valCol = 200;
        pixels[pixIdx] = Wheel(valCol);
    }
    updatePixels();
    ratio = xOffset/(maxlvl*2);
    if(ratio > 2000) ratio = 2000;
    dynRangefactor = (dynRangefactor*(a-1) + ratio)/a;
    if(oneShotPrint){
        println("dynrangefac",dynRangefactor);
    }

}

void wave(){
    if(audioSource == null) return;
    stroke(0, 0, 255);
    strokeWeight(4);
    int bufIdx,bufIdxPrev = 0,iPrev = 0;
    final int xOffset = w/2;
    final float a = 50;
    float ratio;
    float val,maxlvl=0;
    for(int i = 0; i < h; i+=2){
        bufIdx = (int)map(i,0,h,0,audioSource.bufferSize()-1);
        val = audioSource.mix.get(bufIdx);
        maxlvl = max(maxlvl,abs(val));
        line(xOffset+audioSource.mix.get(bufIdxPrev)*dynRangefactor*audioGain, iPrev, xOffset+val*dynRangefactor*audioGain,i);
        bufIdxPrev = bufIdx;
        iPrev = i;
    }
    ratio = xOffset/maxlvl;
    if(ratio > 2000) ratio = 2000;
    dynRangefactor = (dynRangefactor*(a-1) + ratio)/a;
    if(oneShotPrint){
        println("dynrangefac",dynRangefactor);
    }
    //dynRangefactor = (xOffset*a)/(dynRangefactor * (a-1) + maxlvl);
    //rect( 0, 0, audioSource.mix.level()*width, 100 );

}
void vuOPC(float lvl) {
    int i,idx;
    int height;
    int x = numStrips/2;
    height = int(map(lvl, minLvlAvg,maxLvlAvg,0,TOP-10)*audioGain);
    if(height > peak)     peak = height; // Keep 'peak' dot at top
    loadPixels();
    // Color pixels based on rainbow gradient
    for(i=0; i<numLedPerStrip; i++) {
        idx = opc.pixelLocations[ i + numLedPerStrip*x];
        if(i >= height)
            pixels[idx] = 0;
        else
            pixels[idx] = Wheel(map(i,0,numLedPerStrip-1,30,150));
    }

    // Draw peak dot
    if(peak > 0 && peak <= numLedPerStrip-1){
        idx = opc.pixelLocations[ peak + numLedPerStrip*x];
        pixels[idx] = Wheel(map(peak,0,numLedPerStrip-1,30,150));
    }

    updatePixels();
    // Every few frames, make the peak pixel drop by 1:
    if(++dotCount >= PEAK_FALL) { //fall rate
        if(peak > 0) peak--;
        dotCount = 0;
    }
}

void vu1OPC(float lvl) {
    int i,colr,idx;
    int height;
    int x = numStrips/2;
    height = int(map(lvl, minLvlAvg,maxLvlAvg,0,TOP-10)*audioGain);
    if(height > peak)     peak = height; // Keep 'peak' dot at top
    loadPixels();
    // Color pixels based on rainbow gradient
    for(i=0; i<numLedPerStrip_HALF; i++) {
        if(i >= height) {
            idx = opc.pixelLocations[numLedPerStrip_HALF-i-1 + numLedPerStrip*x];
            pixels[idx] = 0;
            idx = opc.pixelLocations[numLedPerStrip_HALF+i + numLedPerStrip*x];
            pixels[idx] = 0;
        }
        else {
            colr = Wheel(map(i,0,numLedPerStrip_HALF-1,30,150));
            idx = opc.pixelLocations[numLedPerStrip_HALF-i-1 + numLedPerStrip*x];
            pixels[idx] = colr;
            idx = opc.pixelLocations[numLedPerStrip_HALF+i + numLedPerStrip*x];
            pixels[idx] = colr;
        }

    }

    // Draw peak dot
    if(peak > 0 && peak <= numLedPerStrip_HALF-1) {
        colr = Wheel(map(peak,0,numLedPerStrip_HALF-1,30,150));
        idx = opc.pixelLocations[numLedPerStrip_HALF-peak-1 + numLedPerStrip*x];
        pixels[idx] = colr;
        idx = opc.pixelLocations[numLedPerStrip_HALF+peak + numLedPerStrip*x];
        pixels[idx] = colr;
    }

    updatePixels();
    // Every few frames, make the peak pixel drop by 1:
    if(++dotCount >= PEAK_FALL) { //fall rate

        if(peak > 0) peak--;
        dotCount = 0;
    }
}

void vu3OPC(float lvl) {
    int i,colr,idx;
    int height;
    int x = numStrips/2;
    height = int(map(lvl, minLvlAvg,maxLvlAvg,0,TOP-10)*audioGain);
    if (height > peak)     peak   = height; // Keep 'peak' dot at top
    loadPixels();
    greenOffset += SPEED;
    blueOffset += SPEED;
    if (greenOffset >= 255) greenOffset = 0;
    if (blueOffset >= 255) blueOffset = 0;
    // Color pixels based on rainbow gradient
    for(i=0; i<numLedPerStrip; i++) {
        idx = opc.pixelLocations[ i + numLedPerStrip*x];
        if(i >= height)
            pixels[idx] = 0;
        else
            pixels[idx] = Wheel(map(i,0,numLedPerStrip-1,(int)greenOffset, (int)blueOffset));
    }

    // Draw peak dot
    if(peak > 0 && peak <= numLedPerStrip-1){
        idx = opc.pixelLocations[ peak + numLedPerStrip*x];
        pixels[idx] = Wheel(map(peak,0,numLedPerStrip-1,30,150));
    }
    updatePixels();

    // Every few frames, make the peak pixel drop by 1:

    if(++dotCount >= PEAK_FALL) { //fall rate

        if(peak > 0) peak--;
        dotCount = 0;
    }
}
void vu3mOPC(float lvl) {
    int i,colr,idx;
    int height;
    height = int(map(lvl, minLvlAvg,maxLvlAvg,0,TOP-10)*audioGain);
    if(height > TOP+3) height = TOP+3;
    if (height > peak) {
        peak   = height; // Keep 'peak' dot at top
        currentStrip = (int)random(0,numStrips-1);
        peaks[currentStrip] = peak;
    }
    int x = currentStrip;
    loadPixels();
    greenOffset += SPEED;
    blueOffset += SPEED;
    if (greenOffset >= 255) greenOffset = 0;
    if (blueOffset >= 255) blueOffset = 0;
    // Color pixels based on rainbow gradient
    for(i=0; i<numLedPerStrip; i++) {
        idx = opc.pixelLocations[ i + numLedPerStrip*x];
        if(i >= height)
            pixels[idx] = 0;
        else
            pixels[idx] = Wheel(map(i,0,numLedPerStrip-1,(int)greenOffset, (int)blueOffset));
    }

    for(int j=0;j<numStrips;j++){
        // Draw peak dot
        if(peaks[j] > 0 && peaks[j] <= numLedPerStrip-1){
            idx = opc.pixelLocations[ peaks[j] + numLedPerStrip*j];
            pixels[idx] = Wheel(map(peaks[j],0,numLedPerStrip-1,30,150));
        }
    }
    updatePixels();
    // Every few frames, make the peak pixel drop by 1:
    if(++dotCount >= PEAK_FALL) { //fall rate
        for(int j=0;j<numStrips;j++)
            if(peaks[j] > 0) peaks[j]--;
        if(peak > 0) peak--;
        dotCount = 0;
    }
}


void vuRipple(float lvl){
    int now = millis();
    float diff = lvl-lastLvl;
    if(diff  < 0 && lastDiff > 0){
        peakcount++;
        step = -1;
    }
    lastDiff = diff;
    lastLvl = lvl;

    if(now - lastRippleCheck[0] > 1000){
        lastRippleCheck[0] = now;
        peakspersec = peakcount; // Count the peaks per second. This value will become the foreground hue.
        peakcount = 0;   // Reset the counter every second.
        println(peakspersec);
    }

    if(now - lastRippleCheck[1] > 20){
        lastRippleCheck[1] = now;
        ripple();
    }
}

void ripple(){
    int idx;
    int x = numStrips/2;
    loadPixels();
    for (int i = 0; i < numLedPerStrip; i++){
        idx = opc.pixelLocations[ i + numLedPerStrip*x];
        pixels[idx] = color(bgcol, 255, int(maxLvlAvg*100));  // Set the background colour.
    }

    switch (step) {

    case -1:                                                          // Initialize ripple variables.
        center  = (int)random(numLedPerStrip-1);
        ripColour = (peakspersec*10) % 255;                                             // More peaks/s = higher the hue colour.
        step = 0;
        bgcol = (bgcol+8)%255;
        break;

    case 0:
        idx = opc.pixelLocations[ center + numLedPerStrip*x];
        pixels[idx] = color(ripColour, 255, 255);                          // Display the first pixel of the ripple.
        step ++;
        break;

    case 16:                                                    // At the end of the ripples.
      // step = -1;
      break;

    default:                                                             // Middle of the ripples.

        idx = opc.pixelLocations[ (center + step + numLedPerStrip) % numLedPerStrip + numLedPerStrip*x];
        pixels[idx] += color(ripColour, 255, 255/step*2);       // Simple wrap from Marc Miller.
        idx = opc.pixelLocations[ (center - step + numLedPerStrip) % numLedPerStrip + numLedPerStrip*x];
        pixels[idx] += color(ripColour, 255, 255/step*2);
        step ++;                                                         // Next step.
        break;
    } // switch step
    updatePixels();

}

void dynRange(float n){
    int i;
    float minLvl, maxLvl;
    vol[volCount] = n;                      // Save sample for dynamic leveling
    if(++volCount >= SAMPLES) volCount = 0; // Advance/rollover sample counter

    // Get volume range of prior frames
    minLvl = maxLvl = vol[0];
    for(i=1; i<SAMPLES; i++) {
        if(vol[i] < minLvl)      minLvl = vol[i];
        else if(vol[i] > maxLvl) maxLvl = vol[i];
    }
    // minLvl and maxLvl indicate the volume range over prior frames, used
    // for vertically scaling the output graph (so it looks interesting
    // regardless of volume level).  If they're too close together though
    // (e.g. at very low volume levels) the graph becomes super coarse
    // and 'jumpy'...so keep some minimum distance between them (this
    // also lets the graph go to zero when no sound is playing):
    // if((maxLvl - minLvl) < TOP*12) maxLvl = minLvl + TOP*12;
    if((maxLvl - minLvl) < 1e-3 ) maxLvl = minLvl + 1e-3;
    //minLvlAvg = (minLvlAvg * 63 + minLvl) >>> 6; // Dampen min/max levels
    //maxLvlAvg = (maxLvlAvg * 63 + maxLvl) >>> 6; // (fake rolling average)
    minLvlAvg = (minLvlAvg * 63 + minLvl)/64; // Dampen min/max levels
    maxLvlAvg = (maxLvlAvg * 63 + maxLvl)/64; // (fake rolling average)
    //if(volCount == 0)println(n,minLvl,maxLvl,minLvlAvg,maxLvlAvg,(maxLvl - minLvl));
}

int Wheel(float WheelPos) {
    return Wheel(WheelPos,1);
}
// Input a value 0 to 255 to get a color value.
// The colors are a transition r - g - b - back to r.
int Wheel(float WheelPos,float brightness) {
    float r,g,b;
    if(WheelPos < 85) {
        r  = WheelPos * 3; g =  255 - WheelPos * 3; b = 0;
    } else if(WheelPos < 170) {
        WheelPos -= 85;
        r = 255 - WheelPos * 3; g =  0; b = WheelPos * 3;
    } else {
        WheelPos -= 170;
        r = 0; g = WheelPos * 3; b = 255 - WheelPos * 3;
    }
    r *= brightness;
    g *= brightness;
    b *= brightness;
    return color((int)r,(int)g,(int)b);
}
