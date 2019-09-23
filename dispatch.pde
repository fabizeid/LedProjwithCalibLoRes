char menuState = 't'; // (t)op level, (s)ound, (v)ideo

void dispatch2() {

    switch(menuState){
    case 't':
        println("t");
        break;
    }

}

void dispatch() {

    if(detectionAlg == 'v'){ //vu meters
        switch(key) {
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
            setColorMode("RGB");
            vuAlg = key;
            lastKey = 0;
            return;
        case '7':
            setColorMode("HSB");
            vuAlg = key;
            lastKey = 0;
            return;
        }

    }
    if(calibrate && (detectionAlg == 'e' || detectionAlg == 'd')){
        switch(key) {
        case 'l': //load to array
            loadCalibForEdge(detectionAlg);
            lastKey = 0;
            return;
        case 's': //save to file
            saveCalibForEdge(detectionAlg);
            lastKey = 0;
            return;
        case 'i': //insert to array
            insertAndSortCalibForEdge();
            lastKey = 0;
            return;
        case 'r': //reset calibration array
            resetCalibForEdge();
            lastKey = 0;
            return;
        case '-':
            bilatColorSigma -= 1;
            lastKey = 0;
            println("bilatColorSigma :", bilatColorSigma);
            return;
        case '=':
            bilatColorSigma += 1;
            lastKey = 0;
            println("bilatColorSigma :", bilatColorSigma);
            return;
        case ';':
            highThresh -= 5;
            lastKey = 0;
            println("highThresh :", highThresh);
            return;
        case '.':
            lowThresh -= 5;
            lastKey = 0;
            println("lowThresh :", lowThresh);
            return;
        case '\'':
            highThresh += 5;
            lastKey = 0;
            println("highThresh :", highThresh);
            return;
        case '/':
            lowThresh += 5;
            lastKey = 0;
            println("lowThresh :", lowThresh);
            return;
        case 'j':
            if(numLedOn >= numStrips) numLedOn -= numStrips;
            println("numLedOn:", numLedOn);
            lastKey = 0;
            return;
        case 'n':
            if(ledIntensity >= 10) ledIntensity -= 10;
            println("Led intensity:", ledIntensity);
            lastKey = 0;
            return;
        case 'k':
            if(numLedOn < (numStrips-1)*numLedPerStrip*2/3) numLedOn += numStrips;
            println("numLedOn:", numLedOn);
            lastKey = 0;
            return;
        case 'm':
            if(ledIntensity < 245) ledIntensity += 10;
            println("Led intensity:", ledIntensity);
            lastKey = 0;
            return;
        case 'o':
            oneShotPrint = true;
            lastKey = 0;
            return;
        case 'c': //capture
            prevDetectionAlg = detectionAlg;
            detectionAlg = 'c';
            isInit = true;
            lastKey = 0;
            return;
        case '1': //go back a frame
            prevImg();
            lastKey = 0;
            return;
        case '2': //go back a frame
            nextImg();
            lastKey = 0;
            return;
        case '3': //live feed
            liveImg();
            lastKey = 0;
            return;

        }

    }

    if(lastKey == 'p'){
        switch(key) {
        case 't':
            printThreshold = !printThreshold;
            println("printThreshold",printThreshold?"On":"Off");
            break;
        case 's':
            printSLvl = !printSLvl;
            println("printSLvl",printSLvl?"On":"Off");
            break;
        case 'e':
            printEnergy = !printEnergy;
            break;
        case 'o':
            oneShotPrint = true;
            break;
        case 'c':
            printCalibForEdge();
        }

        lastKey = 0;
        key = 0;
        return;
    }


    if(lastKey == 'v'){
        switch(key) {
        case 'k':
            debugBackground = !debugBackground;
            println("debug background");
            break;
        case 'm':
            camMode = !camMode;
            break;
        case 'c':
            enableContour = !enableContour;
            println("Contour",enableContour?"On":"Off");
            break;
        case 'g':
            enableGrid = !enableGrid;
            println("enableGrid",enableGrid?"On":"Off");
            break;
        case 'p':
            enablePaint = !enablePaint;
            println("Paint",enablePaint?"On":"Off");
            break;
        case 't':
            detectionAlg = 't';
            vuAlg = '6';
            isInit = true;
            break;
        case 'n': //motion
            detectionAlg = 'm';
            isInit = true;
            break;
        case 'e': //edge
            detectionAlg = 'e';
            isInit = true;
            break;
        case 'd': //diff
            detectionAlg = 'd';
            isInit = true;
            break;
        case 'o': //off
            detectionAlg = 'o';
            break;
        case 'v': //vumeter
            detectionAlg = 'v';
            println("make sure audiosource enabled");
            println("vue meter: (1-5)");
            isInit = true;
            break;
        case 'b': //calibrate
            if(calibrate) {
                calibrate = false;
                println("Calibration Off");
            } else if(detectionAlg != 'e' && detectionAlg != 'd')
                println("Need to be in edge or diff mode for calibration");
            else {
                calibrate = true;
                debugMode = true;
                if(!isPI){
                    surface.setSize(w*2, h*2);
                    initOPCGrid = true;
                }
                println("Calibration On");
                println("Calibration : (i)nsert, (r)eset, (l)oad, (s)ave");
                println("Calibration : (c)apture, (1)previous, (2)next, (3)live");
                println("(-,=) bilat,(;,') high thresh, (.,/) high thresh");
                println("(j,k) num of LED, (n,m) LED intensity");

            }
            break;
        }
        lastKey = 0;
        key = 0;
        return;
    }

    if(lastKey == 's'){
        if(audioserver != null)
            audioserver.stopThread();
        switch(key) {
        case 'o':
            minim.stop();
            audioSource = null;
            soundMode = "noSound";
            println("Sound Off");
            break;
        case 't':
            minim.stop();
            audioSource = null;
            soundMode = "test";
            break;
        case 'g':
            minim.stop();
            soundMode = "groove";
            groove = minim.loadFile(songPath);
            groove.loop();
            audioSource = groove;
            println("Music On");
            delay(2000);
            break;
        case 'm':
            minim.stop();
            soundMode = "mic";
            mic = minim.getLineIn(Minim.MONO);
            audioSource = mic;
            println("Mic On");
            delay(2000);
            break;
        case 'n':
            minim.stop();
            audioSource = null;
            soundMode = "net";
            audioserver = new AudioServer(aport);
            println("Net On");
            delay(2000);
            break;
        }

        lastKey = 0;
        key = 0;
        return;
    }


    if(lastKey == 'a'){ //adjust
        switch(key) {
        case 'c':
            tuneMode = 'c';
            println("Adjust Contour Size");
            break;
        case 'n':
            tuneMode = 'n';
            println("Adjust Num Contours");
            break;
        case 's':
            tuneMode = 's'; //adjust sound
            println("Adjust sound");
            break;
        case 'w':
            tuneMode = 'w'; //adjust sound
            println("Adjust border width");
            break;
        case 'l':
            tuneMode = 'l'; //adjust sound
            println("Adjust border light");
            break;
        case 'h':
            tuneMode = 'h'; //adjust sound
            println("Adjust highThresh");
            break;
        case 't':
            tuneMode = 't'; //adjust sound
            println("Adjust lowThresh/thresh");
            break;
        case 'r':
        case 'g':
        case 'b':
        case 'y':
        case 'm':
            channelMode = key;
            if(key == 'r')
                bImgsMat = bImgsMatR;
            else if(key == 'g')
                bImgsMat = bImgsMatG;
            else if(key == 'b')
                bImgsMat = bImgsMatB;
            else if(key == 'y')
                bImgsMat = bImgsMatGray;
            println("Channel Mode " + key);
            break;
        }
        lastKey = 0;
        key = 0;
        return;
    }


    switch(key) {
    case 'c':
        useColor = !useColor;
        println("useColor",useColor?"On":"Off");
        break;
    case 'i':
        println("Init");
        delay(4000);
        isInit = true;
        break;
    case 'd':
        debugMode = !debugMode;
        if(!isPI){
            if(debugMode){
                surface.setSize(w*2, h*2);
                initOPCGrid = true;
            } else {
                surface.setSize(w, h);
                initOPCGrid = true;
            }
        }
        break;
    case 'a':
        println("Adjust levels: (s)ound, (c)ontour, (t)hreshold, (h)ighedgethres, (w)borderWidth, (l)borderLight ");
        println("Use channel: (r)ed,(g)reen,(b)lue,(y)gray,(m)ax ");


        break;
    case 'p':
        println("Print: (s)ound lvl, (t)hreshold, (e)nergy, (o)neShotPrint, (c)alibration data ");
        break;
    case 'v':
        println("Video: (m)onitor, (p)aint, (c)ontour, (g)rid, (t)riggeredMode, , motio(n) detection mode, (e)dge detection, cali(b)rate, (d)iff, (o)ff ");
        println("debug bac(k)ground, (v)uemeter");

        break;
    case 'u':
        printThreshold = false;
        printSLvl = false;
        printEnergy = false;
        println("Stop printing");
        break;
    case 's':
        println("Sound: (o)ff, (g)roove, (m)ic, (n)et, (t)est ");
        break;
    case 'x':
        //saveContour = true;
        break;
    case 'b':
        blur = !blur;
        println("Blur ",blur?"On":"Off");
        if(detectionAlg == 'd') isInit = true;
        break;
    case 't':
            autoThreshold = !autoThreshold;
            println("autoThreshold",autoThreshold?"On":"Off");
        break;
    case '[':
        switch(tuneMode){
        case 'h':
            highThresh -= 5;
            println("highThresh :", highThresh);
            break;
        case 't':
            lowThresh -= 5;
            println("lowThresh :", lowThresh);
            break;
        case 'c':
            minContourSize -= 500;
            println("minContourSize :", minContourSize);
            break;
        case 'n':
            if(numContoursToDraw > 0)
                numContoursToDraw -= 1;
            println("numContoursToDraw :", numContoursToDraw);
            break;
        case 's':
            audioGain -= .1;
            println("audioGain :", audioGain);
            break;
        case 'w':
            if(borderWidth > 0) borderWidth -= 1;
            println("border width:", borderWidth);
            break;
        case 'l':
            if(borderColor > 0) borderColor -= 1;
            println("border color:", borderColor);
            break;
        }
        //tuneMode = 0;
        break;
    case ']':
        switch(tuneMode){
        case 'h':
            highThresh += 5;
            println("highThresh :", highThresh);
            break;
        case 't':
            lowThresh += 5;
            println("lowThresh :", lowThresh);
            break;
        case 'c':
            minContourSize += 500;
            println("minContourSize :", minContourSize);
            break;
        case 'n':
            numContoursToDraw += 1;
            println("numContoursToDraw :", numContoursToDraw);
            break;
        case 's':
            audioGain += .1;
            println("audioGain :", audioGain);
            break;
        case 'w':
            borderWidth += 1;
            println("border :", borderWidth);
            break;
        case 'l':
            //if(borderColor < 255) borderColor += 10;
            borderColor += 1;
            println("border color:", borderColor);
            break;
        }
        //tuneMode = 0;
        break;
    case 'q':
        background(0);
        exit();
    case 'z':
        stopLoop = !stopLoop;
        if(stopLoop){
            noLoop();
            background(0);
        } else {
            loop();
        }
        break;
       default:
        println("(a)djust, (b)lur, ([)decrease, (])increase,(p)rint, (u)nprint, (x)save");
        println("(i)nit, (d)ebug, (s)ound, (v)ideo");
        println("(t)hreshold mode, (z)stop, (q)uit");

        if(calibrate) {
            println("Calibration : (i)nsert, (r)eset");
        }
        break;
    }
    lastKey = key;
    key = 0;
}
