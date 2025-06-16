import processing.net.*;
import hypermedia.net.*;   
import java.util.Queue;
import java.util.LinkedList;

Client myClient; 
String inString;
int currentTime;

// Para la recepción de los Watches
int previousStimulusCode = 0;
int previousPhaseInSequence = 0;
UDP udp;

Queue<Integer> cola = new LinkedList<Integer>(); // cola para StimulusCode
Queue<Integer> colaType = new LinkedList<Integer>();// cola para StimulusType

boolean pruebaEnMarcha = false;
boolean[] solicitudEstimulo; // true si BCI2000 ha solicitado un estímulo deseado;
int[] siguienteInstanteEstimulo; // Para el control de la temporización de los estímulos
boolean[] solicitudEstimuloIgual; // true si BCI2000 ha solicitado un estímulo deseado igual al anterior
int[] siguienteInstanteEstimuloIgual; // Para el control de la temporización de los estímulos
int StimulusCodeIgual = 0;

boolean solicitudEstimulo2 = false; // true si BCI2000 ha solicitado un estímulo 0;
int siguienteInstanteEstimulo2; // Para el control de la temporización de los estímulos 0

boolean SolicitudSelected = false;

int mStimulusCodeS = 0;  // Para ponerle el valor a StimulusCode 
int mStimulusCodeSAnt = 0; 
int mStimulusTypeS = 0;  // Para ponerle el valor a StimulusType 
int mPhaseInSequenceS = 0;  // Para ponerle el valor a PhaseInSequence 
int ContRes = 0; // contador para saber el numero 
int StimulusCodeResAnt = 0; // el estimulo anterior de StimulusCodeRes 

int mSelectedStimulus = 0;
int StimulusCodeAnt = 0;//Para que no vuelva a recibirlo en recieve

String NumeroEst = ""; // Para recivir el número de estimulos que se usaran
boolean EstRecibido = false;
int Estimulos; 

boolean Clasificador = true;// Poner aqui true si esta en modo Calibración, false si es modo Online
boolean MuestraEst = true;// Para que saque por pantalla el Numero a seguir para el clasificador
int Cont = 0;
int[] EstimuloClas;

int numImagenes = 6;
PImage[] imagenes;
boolean verbose = false;
void setup() {
  size(600, 600);
  background(127);

  myClient = new Client(this, "127.0.0.1", 3999); // Para enviar a BCI2000 vía la conexión por defecto el cambio en eventos definidos por el usuario; en nuestro caso "TriggerFrom Processing"

  udp = new UDP(this, 12345); // Para recibir los Wtches de BCI2000 por UDP
  udp.listen(true);

  background(0);
  textSize(30);
  imagenes = new PImage[numImagenes];
  for (int i = 0; i<numImagenes; i++) {
    imagenes[i] = loadImage((i+1)+".bmp");
  }
}      


void draw() {

  if (!EstRecibido) { //Para preguntar el numero de estimulos
    background(20);
    text("Ingrese el número de estimulos:", 10, 50);
    text(NumeroEst, 20, 100);
  } else {
    if(Clasificador && MuestraEst && mPhaseInSequenceS == 1){
      text("Piense en el siguiente estímulo", 10, 50);
      image(imagenes[Cont], 0, 60, width, height);
      Cont ++;
      MuestraEst = false;
    }
    currentTime = millis();
    if (pruebaEnMarcha) {
      for (int i_channel = 0; i_channel < Estimulos; i_channel++ ) { //Depende del num Estimulos
        if ( solicitudEstimulo[i_channel] && currentTime >= siguienteInstanteEstimulo[i_channel]) {
          if (mStimulusCodeS != 0) {
            //myClient.write("set state TriggerFromProcessing 1 \r\n");        // He cambiado set state por Pulse event
            //myClient.write("set state StimulusBegin 1 \r\n");        // Pongo a 1 a StimulusBegin
            // myClient.write("set state StimulusCode " + Code + " \r\n");        // Pongo el valor de StimulusCode que viene de BCI2000
            //myClient.write("set state StimulusType " + Type + " \r\n");        // Pongo el valor de StimulusType que viene de BCI2000
            //  myClient.write("set states TriggerFromProcessing 1 StimulusBegin 1 StimulusCode " + Code + " StimulusType " + Type + " PhaseInSequence 2 \r\n");        // Pongo el valor de PhaseInSequence a 2 retrasado el mismo tiempo que StimulusCode 
            int margenMilisegEntreEstimulos = 100;
            if(!solicitudEstimulo2 && currentTime >= siguienteInstanteEstimulo2+margenMilisegEntreEstimulos){//Para que no coincidan los estimulos
            int Code = desencola();
            int Type = desencolaType();                         
            myClient.write("set states StimulusCode " + Code + " StimulusType " + Type + " StimulusBegin 1 PhaseInSequence 2 TriggerFromProcessing 1 \r\n");        //Pruebo a cambiar el orden             
            solicitudEstimulo[i_channel] = false;

            if (solicitudEstimuloIgual[i_channel] != false && siguienteInstanteEstimulo[i_channel] != 0) {
              solicitudEstimulo[i_channel] = solicitudEstimuloIgual[i_channel];
              siguienteInstanteEstimulo[i_channel] = siguienteInstanteEstimuloIgual[i_channel];

              solicitudEstimuloIgual[i_channel] = false;
              siguienteInstanteEstimuloIgual[i_channel] = 0;
            }

            image(imagenes[i_channel], 0, 0, width, height);
            if (verbose) println("Estímulo: "+ (i_channel+1));
            if (verbose) println("----");

            solicitudEstimulo2 = true; 
            int duracionEstimulo = 200;
            siguienteInstanteEstimulo2 = millis()+duracionEstimulo;

            if (verbose) println("Enviando a BCI2000: set state StimulusCode " + mStimulusCodeS);
            }
          } else {
            println("mStimulusCodeS == 0 ! ");
          }
        }
      }
      if (solicitudEstimulo2 && currentTime >= siguienteInstanteEstimulo2) {
        myClient.write("set states StimulusCode 0 StimulusType 0 \r\n");        // Pongo el valor de StimulusCode a 0
        solicitudEstimulo2 = false;
        background(127); // Cambiamos el color de fondo para indicar,como pista,que ocurre la estimulación
        //text("Estímulo: 0", 50, height/2);
      }
      if (SolicitudSelected && !Clasificador) {
        background(200, 200, 200);
        text("Resultado estímulo:", 10, 50);
        image(imagenes[mSelectedStimulus - 1], 0, 60, width, height);
        SolicitudSelected = false;
      }
    } else {
      background(20); 
      text("Número de estímulos: "+Estimulos, 50, height/2);
    }
  }
}

void keyPressed() {
  if (!EstRecibido) {
    if (key >= '0' && key <= '9') {
      NumeroEst += key;
    } else if (key == BACKSPACE && NumeroEst.length() > 0) {
      NumeroEst = NumeroEst.substring(0, NumeroEst.length() - 1); // Para borrar
    } else if (key == ENTER || key == RETURN) {
      if (NumeroEst.length() > 0) {
        Estimulos = int(NumeroEst);
        EstRecibido = true;
        // 
        solicitudEstimulo = new boolean[Estimulos];
        siguienteInstanteEstimulo = new int[Estimulos];
        solicitudEstimuloIgual = new boolean[Estimulos];
        siguienteInstanteEstimuloIgual = new int[Estimulos];
        EstimuloClas = new int[Estimulos];
        for (int i = 0; i < Estimulos; i++) {
          solicitudEstimulo[i] = false; 
          siguienteInstanteEstimulo[i] = 0;
          solicitudEstimuloIgual[i] = false; 
          siguienteInstanteEstimuloIgual[i] = 0;
          EstimuloClas[i] = i + 1;
        }
      }
    }
  }
}

void receive(byte[] data) {

  // The data sent will consist of a single UDP packet with a single line in ASCII format, terminated with a CRLF sequence.
  // The line consists of tab-separated data fields, which contain the current values of the expressions specified when creating the watch.
  // In addition, the first field contains a time stamp in the same time base as the SourceTime state
  // Es decir, si hemos añadido 3 watches, llegarán separados por el tab (ascii 9).
  // AL principio se añade unos bytes indicando el timeStamp.
  // ¡OJO! Aquí varía la versión última de BCI2000, en las anteriores se añadía menos bytes, por lo que la lectura dell dat incialmente propuesta por Álvaro fallaba al cambiar a la última versión
  // Como lo de separarlos por ascii 9 sí es constante entre versiones, lo utilizaremos para tener compatibilidad con todas las versiones.
  // Watches añadidos: StimulusCodeCop StimulusTypeCop PhaseInSequenceCop StimulusCodeRes SelectedStimulus

  int[] posTab = new int[5];
  int indexPosTab = 0;
  int PhaseInSequence = 0;
  int StimulusCode = 0;
  int StimulusType = 0; 
  int StimulusCodeRes = 0; 
  int SelectedStimulus = 0;

  //println("received: " + data.length);
  for (int i=0; i<data.length; i++) {
    //print( char(data[i]) );
    if (data[i] == 9) {
      if (indexPosTab < posTab.length) { 
        posTab[indexPosTab] = i;
        indexPosTab++;
      }
    }
  }

  byte[] stim = subset(data, posTab[0]+1, (posTab[1] - posTab[0] - 1) ) ;
  String stimStr = new String(stim);
  StimulusCode = int(stimStr); 

  byte[] stimType = subset(data, posTab[1] + 1, (posTab[2] - posTab[1] - 1)); 
  String stimTypeStr = new String(stimType);
  StimulusType = int(stimTypeStr); 

  PhaseInSequence = int( char(data[ posTab[2]+1 ]) ) - 48;

  byte[] stimRes = subset(data, posTab[3] + 1, (posTab[4] - posTab[3] - 1));
  String stimResStr = new String(stimRes);  
  StimulusCodeRes = int(stimResStr.trim());
  if (StimulusCodeRes != 0) println("stimResStr: '" + stimResStr + "'");

  byte[] selectedStim = subset(data, posTab[4] + 1, data.length - posTab[4] - 1);
  String selectedStimStr = new String(selectedStim); 
  SelectedStimulus = int(selectedStimStr.trim());

  if (SelectedStimulus != 0) {
    println("SelectedStimulus: " + SelectedStimulus);
    mSelectedStimulus = SelectedStimulus;
    SolicitudSelected = true;
  }

  if (int(stimStr) != StimulusCodeAnt) {
    if (StimulusCode != 0) {
      if (verbose) println("Solicitud recibida de estímuloCode: "+StimulusCode ); // Solicitud desde BCI2000 de presentar el estímulo "StimulusCode"

      int retrasoEstimulo = int(random(300, 1000));
      //int retrasoEstimulo = 700;
      if (StimulusCodeIgual == StimulusCode && solicitudEstimulo[StimulusCode-1] == true) { // para solucionar dos iguales rapido
        solicitudEstimuloIgual[StimulusCode-1] = true;
        siguienteInstanteEstimuloIgual[StimulusCode-1] = millis()+retrasoEstimulo; // Como primera prueba, pongamos que Processing pone el estímulo 1 segundo despué de recibir la solicitud CAMBIAR RETRASO AQUI
      } else {
        solicitudEstimulo[StimulusCode-1] = true;
        siguienteInstanteEstimulo[StimulusCode-1] = millis()+retrasoEstimulo;
      }
      mStimulusCodeS = StimulusCode;  // El valor de StimulusCode que viene de BCI2000
      encola(StimulusCode);// Guarda en la cola stimulusCode
      StimulusCodeIgual = StimulusCode;

      if (StimulusType == 1) {// Si son iguales se debe poner Stimulus Type a 1
        if (verbose) println("Solicitud recibida de estímuloType: "+StimulusType ); // Solicitud desde BCI2000 de presentar el estímulo "StimulusType"
        mStimulusTypeS = StimulusType;  // El valor de StimulusType que viene de BCI2000
        encolaType(StimulusType);
      } else {
        mStimulusTypeS = 0;
        encolaType(0);
      }
    }
    StimulusCodeAnt = int(stimStr);
  }

  //if (verbose) println("StimulusCodeResAnt: "+StimulusCodeResAnt );
  if (verbose)  println("estímuloStimulusCodeRes: "+StimulusCodeRes );
  if (StimulusCodeResAnt != StimulusCodeRes) {//Es necesario
    if (StimulusCodeRes != 0) {

      ContRes++;
      if (verbose) println("ContRes: "+ContRes );
      if (ContRes == Estimulos) {
        myClient.write("set state PhaseInSequence 3 \r\n");        //Pongo a 3 a PhaseInSequence
        MuestraEst = true; //Para que pueda volver a salir el valor que se busca en el clasificador
        ContRes = 0;
      }
    }
    StimulusCodeResAnt = StimulusCodeRes;
  }


  if (PhaseInSequence != previousPhaseInSequence) {
    switch(PhaseInSequence) {
    case 1:    
      if (previousPhaseInSequence == 0) {
        // comienza la prueba
        pruebaEnMarcha = true;
        println("Comienza la prueba");
      } else {
        // comienza una sequence
        //pruebaEnMarcha = true;
        println("Empieza  seq");
      }
      mPhaseInSequenceS = 1;
      myClient.write("set state PhaseInSequence 1 \r\n");        //Pongo a 1 a PhaseInSequence
      break;
    case 2:
      // comienza la estimulación
      mPhaseInSequenceS = 2;
      break;
    case 3:
      // termina la sequence
      //pruebaEnMarcha = false;
      println("Termina seq");
      mPhaseInSequenceS = 3;
      break;
    case 0:
      // fin de la prueba
      println("Fin de la prueba");
      mPhaseInSequenceS = 0;
      myClient.write("set state PhaseInSequence 0 \r\n");        //Pongo a 0 a PhaseInSequence
      exit();
      break;
    }
    previousPhaseInSequence = PhaseInSequence;
  }
}

void encola(int v) {//Para guardar en cola stimulusCode
  cola.add(v);
}

void encolaType(int v) {//Para guardar en la cola stimulusType
  colaType.add(v);
}

Integer desencola() { //Para devoolver el primer valor
  if (!cola.isEmpty()) {
    return cola.remove();
  }
  return null;
}

Integer desencolaType() { //Para devolver el primer valor
  if (!colaType.isEmpty()) {
    return colaType.remove();
  }
  return null;
}
