#include <BLEDevice.h> //Bluetooth y WiFi
#include <BLEUtils.h>
#include <BLEServer.h>
#include <WiFi.h>
#include <WebServer.h>

// See the following for generating UUIDs:
// https://www.uuidgenerator.net/

#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"
 // WiFi
String ssid = "";
String password = "";
bool primera = true;
bool fin = false;

WebServer server(120);

//Ojos RGB
#define IVERDE 19
#define IROJO 16
#define IAZUL 25

#define IVerdeChannel 10
#define IRojoChannel 11
#define IAzulChannel 12

#define DVERDE 27
#define DROJO 0
#define DAZUL 2

#define DVerdeChannel 13
#define DRojoChannel 14
#define DAzulChannel 9

const int freq = 500;
const int resolution = 8;

//Motores

#define DIN1 13
#define DIN2 12
#define IIN1 15
#define IIN2 14

#define motorDChannelA 5
#define motorIChannelA 6

#define motorDChannelB 7
#define motorIChannelB 8

#define max_vel 100
#define min_vel -100
int x;
int y;
int dist;

//Servomotor
#include "ESP32_Servo.h"
const int servo_pin = 4;
Servo myServo;
int angulo;

//EsquivaObstaculos
bool esquivaobstaculos = false;

int vel_ref_obst = 35;
int dist_obst = 400;
int bucles = 0;

//Siguelineas
bool siguelineas=false;
const int pinesTCRT5000[] = {33,32,35,34,39,36}; //Derecha a izq
const int numPinTCRT5000 = 6;
int lecturas[numPinTCRT5000];


long error = 0;
long correcion=0;
long integral = 0;
long derivada = 0;
long error_anterior=0;


int vel_ref= 30;
float ganancia = 0.04;
float ganancia_der = 0.004;



//Lidar
#include "Adafruit_VL53L0X.h"
Adafruit_VL53L0X lidar = Adafruit_VL53L0X();



//Display Mad72xx
#include <MD_Parola.h>
#include <MD_MAX72XX.h>
#include <SPI.h>

#define HARDWARE_TYPE MD_MAX72XX::FC16_HW
#define MAX_DEVICES 1
//CS GPIO 5  DIN GPIO23  CLK GPIO18
#define CS_PIN 5
MD_Parola Display = MD_Parola(HARDWARE_TYPE, CS_PIN, MAX_DEVICES);
String mensaje;

const uint8_t face[] = {8, 60, 66, 145, 161, 161, 145, 66, 60,};
const uint8_t arrow_d[] = {8, 24, 24, 24, 24, 255, 126, 60, 24,};
const uint8_t rayo[] = {8, 0, 16, 24, 28, 222, 119, 51, 16, };
 uint8_t simbolo[] = {8, 0, 0, 0, 0, 0, 0, 0, 0,};


class MyCallbacks: public BLECharacteristicCallbacks
{ //Obtiene la WiFi por bluetooth
    void onWrite(BLECharacteristic *pCharacteristic)
    {
      std::string value = pCharacteristic->getValue();
      if (primera == true)
      {
        primera = false;
        ssid = value.c_str();

      }
      else {
        password = value.c_str();
        fin = true;

      }
    }
};

void setup()
{


  //Inicializa el  display
  Display.begin();
  Display.setIntensity(1);
  Display.displayClear();
  Display.displayScroll("Conectate con el dispositivo", PA_CENTER, PA_SCROLL_LEFT, 150);
  Display.addChar('&', face);
  Display.addChar('~', arrow_d);
  Display.addChar('@', rayo);
   Display.setTextAlignment(PA_RIGHT);
 
  
  //Inicializa Bluetooth
  BLEDevice::init("ESP32-BLE-Server");
  BLEServer *pServer = BLEDevice::createServer();
  BLEService *pService = pServer->createService(SERVICE_UUID);
  BLECharacteristic *pCharacteristic = pService->createCharacteristic(
                                         CHARACTERISTIC_UUID,
                                         BLECharacteristic::PROPERTY_READ |
                                         BLECharacteristic::PROPERTY_WRITE_NR
                                       );

  pCharacteristic->setCallbacks(new MyCallbacks());
  pCharacteristic->setValue("Hello World");
  pService->start();
  BLEAdvertising *pAdvertising = pServer->getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);  // functions that help with iPhone connections issue
  pAdvertising->setMinPreferred(0x12);
  pAdvertising->start();

  Display.displayScroll("Bluetooth Encendido", PA_CENTER, PA_SCROLL_LEFT, 150);
  
  while (!fin)
  {
    if (Display.displayAnimate())
    {
      Display.displayReset();

    }
    delay(10);
  }
  
  //Conecta al WiFi y arranca el servidor
  Display.displayScroll("Conectando la wifi", PA_CENTER, PA_SCROLL_LEFT, 150);

  delay(100);
  char ssid_buf[40] = {};
  ssid.toCharArray(ssid_buf, ssid.length() + 1);
  char password_buf[40] = {};
  password.toCharArray(password_buf, password.length() + 1);
  const char* ssid_wifi = ssid_buf;
  const char* password_wifi = password_buf;
  WiFi.begin(ssid_wifi, password_wifi);
  while (WiFi.status() != WL_CONNECTED)
  {
    if (Display.displayAnimate())
    {
      Display.displayReset();
    }
  }
  
  Display.displayScroll("WiFi conectada", PA_CENTER, PA_SCROLL_LEFT, 150);
  pCharacteristic->setValue(WiFi.localIP().toString().c_str());

  server.on("/servo", servo);
  server.on("/ojos", rgb);
  server.on("/debug", debug);
  server.on("/linea", linea);
  server.on("/obstaculo", obstaculo);
  server.on("/medida", medida);
  server.on("/movimiento", movimiento);
  server.on("/barrido", barrido);
  server.on("/mensajePantalla",mensajePantalla);
  server.on("/pantalla",pantalla);
  server.on("/parametrosSiguelinea",parametrosSiguelinea);
  server.on("/parametrosObstaculos",parametrosObstaculos);
  server.on("/creacionSimbolo",creacionSimbolo);
  server.begin();

  // Configura los led de los ojos
  ledcAttachPin(IVERDE, IVerdeChannel);
  ledcSetup(IVerdeChannel, freq, resolution);

  ledcAttachPin(IROJO, IRojoChannel);
  ledcSetup(IRojoChannel, freq, resolution);

  ledcAttachPin(IAZUL, IAzulChannel);
  ledcSetup(IAzulChannel, freq, resolution);

  pinMode(IVERDE, OUTPUT);
  pinMode(IROJO, OUTPUT);
  pinMode(IAZUL, OUTPUT);

  // attach the channel to the GPIO to be controlled
  ledcAttachPin(DVERDE, DVerdeChannel);
  ledcSetup(DVerdeChannel, freq, resolution);

  ledcAttachPin(DROJO, DRojoChannel);
  ledcSetup(DRojoChannel, freq, resolution);

  ledcAttachPin(DAZUL, DAzulChannel);
  ledcSetup(DAzulChannel, freq, resolution);

  pinMode(DVERDE, OUTPUT);
  pinMode(DROJO, OUTPUT);
  pinMode(DAZUL, OUTPUT);

  //Configura el servo y centra la cara
  myServo.attach(servo_pin);
  myServo.write(80);

  //Siguelineas
  for (int i = 0; i < numPinTCRT5000; i++)
  {
    pinMode(pinesTCRT5000[i], INPUT);
    lecturas[i] = 0;
  }

  //Lidar
  lidar.begin();
  lidar.configSensor(Adafruit_VL53L0X::VL53L0X_SENSE_LONG_RANGE);

  //Motores
  // attach the channel to the GPIO to be controlled
  ledcAttachPin(DIN1, motorDChannelA);
  ledcSetup(motorDChannelA, freq, resolution);
  ledcAttachPin(DIN2, motorDChannelB);
  ledcSetup(motorDChannelB, freq, resolution);

  ledcAttachPin(IIN1, motorIChannelA);
  ledcSetup(motorIChannelA, freq, resolution);
  ledcAttachPin(IIN2, motorIChannelB);
  ledcSetup(motorIChannelB, freq, resolution);

  pinMode(DIN1, OUTPUT);
  pinMode(IIN1, OUTPUT);
  pinMode(DIN2, OUTPUT);
  pinMode(IIN2, OUTPUT);
  motorD(0);
  motorI(0);


}

void loop()
{
  server.handleClient();
  if (Display.displayAnimate())
  {
    Display.displayReset();

  }
  if (siguelineas)
    SigueLineas();
  if (esquivaobstaculos)
    EsquivaObstaculos();
 
  
   
}

void SigueLineas ()
{
  int max = 0, pos;
 for (int i = 0; i < numPinTCRT5000; i++)
  {


    lecturas[i]=analogRead(pinesTCRT5000[i]);
      if(lecturas[i]>max && lecturas[i]>1000)
      {
        max=lecturas[i];
        pos = i;
      }

  }


  if(max>1000) //Detecta linea
  {
  
  error=-3*lecturas[0]-2*lecturas[1]-lecturas[2]+lecturas[3]+2*lecturas[4]+3*lecturas[5];

  
  derivada=error-error_anterior;
  error_anterior=error;

    //Error con PD Demostro ser el mas efectivo
    correcion=ganancia*error+derivada*ganancia_der;
  int vel_izq=vel_ref-correcion;

  int vel_der=vel_ref+correcion;
  if(vel_izq<0)
    vel_izq=0;
   if(vel_der<0)
    vel_der = 0;
  motorD(vel_der);
  motorI(vel_izq);
  }else //No hay linea, buscamos por donde nos hemos salido
  { 

      if(pos<3)
      {
        motorD(60);
        motorI(5);
      }else{
             motorI(60);
        motorD(5);

      }
      }
    
 }


void EsquivaObstaculos()
{
VL53L0X_RangingMeasurementData_t measure;
  int dist = unaMedida();

  if (dist > dist_obst)
  {

    motorD(vel_ref_obst);
    motorI(vel_ref_obst);
    bucles = 0;
    
  }
  else
  {
    motorD(0);
    motorI(0);
    int* vector_medidas = new int[4];
    int pos_max = 0, valor_max;
    bucles++;
    myServo.write(0);
    delay(200);
    vector_medidas[0] = unaMedida();
    delay(200);
    myServo.write(45);
    vector_medidas[1]  = unaMedida();
    myServo.write(135);
    delay(200);
    vector_medidas[2] = unaMedida();
    delay(200);
    myServo.write(180);
    vector_medidas[3]  = unaMedida();

    myServo.write(80);
    delay(200);

    for (int i = 0; i < 4; i++)
    {
      if (vector_medidas[i] > valor_max)
      {
        valor_max = vector_medidas[i];
        pos_max = i;
      }
    }

    if (pos_max == 0)
    {
      motorD(-50);
      motorI(vel_ref_obst);
      delay(200);

    } else if (pos_max == 1)
    {
      motorD(-40);
      motorI(vel_ref_obst);
      delay(120);
    } else if (pos_max == 2)
    {
      motorI(-40);
      motorD(vel_ref_obst);
      delay(120);
    } else if (pos_max == 3)
    {
      motorI(-50);
      motorD(vel_ref_obst);
      delay(200);
    }

    delete[] vector_medidas;
  }
  if (bucles > 1)
  {
    motorD(-80);
    motorI(0);
    delay(100);
  }
}

void creacionSimbolo()
{
  simbolo[0] = 8;
    for(int i =0; i<8; i++)
    {
         simbolo[i+1] = server.arg(String(i)).toInt();  
    }
  int efecto = server.arg("efecto").toInt();
  int velocidad = server.arg("vel").toInt();
  Display.addChar('&', simbolo);

textEffect_t  effect[] =
{
  PA_NO_EFFECT,
  PA_PRINT,
  PA_SCROLL_UP,
  PA_SCROLL_DOWN,
  PA_SCROLL_LEFT,
  PA_SCROLL_RIGHT ,
  PA_SLICE,
  PA_MESH,
  PA_FADE,
  PA_DISSOLVE,
  PA_BLINDS,
  PA_RANDOM,
  PA_WIPE,
  PA_WIPE_CURSOR,
  PA_SCAN_HORIZ,
  PA_SCAN_HORIZX,
  PA_SCAN_VERT,
  PA_SCAN_VERTX,
  PA_OPENING,
  PA_OPENING_CURSOR,
  PA_CLOSING,
  PA_CLOSING_CURSOR,
  PA_SCROLL_UP_LEFT,
  PA_SCROLL_UP_RIGHT,
  PA_SCROLL_DOWN_LEFT,
  PA_SCROLL_DOWN_RIGHT,
  PA_GROW_UP,
  PA_GROW_DOWN
};
    Display.displayClear();
   Display.displayScroll("&", PA_CENTER,effect[efecto], velocidad);    
    server.send(200, "text/plain", "recibido" );
}


void rgb()
{

  int rojo = server.arg("rojo").toInt();
  int verde = server.arg("verde").toInt();
  int azul = server.arg("azul").toInt();
  int derecho = server.arg("derecho").toInt();
  if (derecho)
  {
    ledcWrite(DRojoChannel, rojo);
    ledcWrite(DVerdeChannel, verde);
    ledcWrite(DAzulChannel, azul);
  } else if (!derecho)
  {
    ledcWrite(IRojoChannel, rojo);
    ledcWrite(IVerdeChannel, verde);
    ledcWrite(IAzulChannel, azul);
  }
  server.send(200, "text/plain", "recibido" );
}

void debug()
{
  server.send(200, "text/plain", "prueba" );
  delay(100);
}

void servo()
{
  server.send(200, "text/plain", "servo" );
  angulo = server.arg("angulo").toInt();

  myServo.write(angulo);
  delay(100);
}
void parametrosObstaculos()
{
 
  server.send(200, "text/plain", "recibido" );
  vel_ref_obst = server.arg("vel").toInt();
  dist_obst = server.arg("dist").toInt();
}
void parametrosSiguelinea()
{
  server.send(200, "text/plain", "recibido" );
  vel_ref = server.arg("vel").toInt();
  ganancia = server.arg("ganancia").toDouble();
  ganancia_der = server.arg("gananciaD").toDouble();

}
void pantalla()
{
  Display.setTextAlignment(PA_CENTER);
  String simbolo = server.arg("simbolo");
    Display.displayClear();
    delay(100);
     if(simbolo=="Flecha_d")
          Display.displayScroll("~", PA_CENTER, PA_NO_EFFECT, 100); 
    else if(simbolo == "Cara")
           Display.displayScroll("&", PA_CENTER,PA_FADE, 1000);  
    else if(simbolo == "Rayo")
           Display.displayScroll("@", PA_CENTER, PA_GROW_DOWN, 100);    
   
  server.send(200, "text/plain", "recibido" );
  delay(10);
}
          

void mensajePantalla()
{
  server.send(200, "text/plain", "mensaje recibido" );
  mensaje = server.arg("mensaje");
  String scroll = server.arg("scroll");
  int velocidad = server.arg("velocidad").toInt();
  if(velocidad<1)
    velocidad=150;
  Display.displayClear();
  if(scroll == "Izquierda")
    Display.displayScroll(mensaje.c_str(), PA_CENTER, PA_SCROLL_LEFT, velocidad);
  else if(scroll == "Derecha")
    Display.displayScroll(mensaje.c_str(), PA_CENTER, PA_SCROLL_RIGHT, velocidad);

}

void linea()
{
  if (siguelineas == false)
  {
    server.send(200, "text/plain", "on" );
    siguelineas = true;
  }
  else
  {
    server.send(200, "text/plain", "off" );
    siguelineas = false;
    motorD(0);
    motorI(0);
  }
}

void obstaculo()
{
  if (esquivaobstaculos == false)
  {
    server.send(200, "text/plain", "on" );
    esquivaobstaculos = true;
  }
  else
  {
    server.send(200, "text/plain", "off" );
    esquivaobstaculos = false;
      motorD(0);
    motorI(0);
    myServo.write(80);
  }
}

void medida()
{
  VL53L0X_RangingMeasurementData_t measure;
  lidar.rangingTest(&measure, false);
  if (measure.RangeStatus != 4)
  {

    server.send(200, "text/plain", (String)measure.RangeMilliMeter );
  }
  else
  {
    //Error
    server.send(200, "text/plain", "0" );
  }
}



//Motores

void movimiento()
{
  server.send(200, "text/plain", "movimiento" );
  x = server.arg("x").toInt();
  y = server.arg("y").toInt();
  dist = server.arg("dist").toInt();


  if (x == 0 && y == 0)
  {
    motorI(0);
    motorD(0);
  }
  if (x >= 0) {
    motorD(y);
    if (y > 0)
      motorI(dist);
    else
      motorI(-dist);
  }
  if (x < 0) {
    motorI(y);
    if (y > 0)
      motorD(dist);
    else
      motorD(-dist);
  }
}

void barrido()
{
  String medidas = "";
  myServo.write(10);
  delay(500);
  for (angulo = 10; angulo < 180; angulo = angulo + 5)
  {
    VL53L0X_RangingMeasurementData_t measure;
    myServo.write(angulo);
    delay(200);
    lidar.rangingTest(&measure, false);
    delay(50);
    if (measure.RangeStatus != 4 && measure.RangeMilliMeter < 1200)
    {
      medidas = medidas + String(measure.RangeMilliMeter) + "/";

    }
    else
    {
      medidas = medidas + String(1200) + "/";
    }
  }
  myServo.write(80);

  server.send(200, "text/plain", medidas );
}

void motorD(int vel)
{
  if(vel>max_vel)
    vel=max_vel;
   else if(vel<min_vel)
      vel=min_vel; 
   if(vel==0)
   {
       ledcWrite(motorDChannelA,0);
     ledcWrite(motorDChannelB,0);
   }
    else if(vel>0)
{
    int velocidad=map(vel,0,max_vel,0,256);
     ledcWrite(motorDChannelA,velocidad);
     ledcWrite(motorDChannelB,0);
}else if(vel<0)
{
   
  int velocidad=map(vel,0,min_vel,0,256);
     ledcWrite(motorDChannelB,velocidad);
     ledcWrite(motorDChannelA,0);
}
}
void motorI(int vel)
{
  if(vel>max_vel)
    vel=max_vel;
   else if(vel<min_vel)
      vel=min_vel; 
   if(vel==0)
   {
       ledcWrite(motorIChannelA,0);
     ledcWrite(motorIChannelB,0);
   }
    else if(vel>0)
{
    int velocidad=map(vel,0,max_vel,0,256);
     ledcWrite(motorIChannelA,velocidad);
     ledcWrite(motorIChannelB,0);
}else if(vel<0)
{
 
  int velocidad=map(vel,0,min_vel,0,256);

     ledcWrite(motorIChannelB,velocidad);
     ledcWrite(motorIChannelA,0);
}
}


int unaMedida ()
{
  VL53L0X_RangingMeasurementData_t measure;
  int dist = 0;
  lidar.rangingTest(&measure, false);
  delay(30);
 
  if (measure.RangeStatus != 4 && measure.RangeMilliMeter < 8000)
  {
    dist = measure.RangeMilliMeter;
  }
  else
  {
    dist = 1000;
  }

  return dist;
}
