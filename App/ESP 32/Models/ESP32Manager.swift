//
//  Bluetooth Manager.swift
//  ESP 32
//
//  Created by Miquel Sitges Nicolau on 7/5/22.
//

//
//  Bluetooth Manager.swift
//  ESP 32
//
//  Created by Miquel Sitges Nicolau on 7/5/22.
//


import CoreBluetooth
import Network
import SwiftUI
import Foundation



@MainActor class ESP32Manager: NSObject,ObservableObject {
    
    //Bluetooth
    private var centralManager: CBCentralManager!
    var myPeripheral :CBPeripheral!
    let serviceUUID = CBUUID(string: "4FAFC201-1FB5-459E-8FCC-C5C9C331914B")
    let characteristicUUID = CBUUID(string: "BEB5483E-36E1-4688-B7F5-EA07361B26A8")
    var characteristica: CBCharacteristic!
    
    //WiFi
    var Ip=""
    var realIP:String = ""
    @Published var conectado=false
    @Published var configuracionRealizada=false
    
    //Robot
    @Published var medida="Inicializa"
    @AppStorage("dirrecionIp") var dirrecionIp: String = ""
    @Published var barridoMedidas:[Int] = [0,0]
    
    @Published var msg:String="a"
    @Published var sigueLineas:Bool = false
    @Published var esquivaObstaculos:Bool = false
    
    
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        centralManager.delegate = self
    }
    
    func write(value: Data) {
        
        myPeripheral.writeValue(value, for: characteristica, type: .withoutResponse)
    }
    func read ()
    {
        myPeripheral.readValue(for: characteristica)
        
    }
    func startScan() {
        centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
    }
    func desconectar()
    {
        centralManager.cancelPeripheralConnection(myPeripheral)
    }
    func stop()
    {
        centralManager.stopScan()
    }
    
    
    func urlSend(url:String) async -> String
    {
        do{
            let (data, _) = try await URLSession.shared.data(from: URL(string:url)!)
            return String(decoding: data, as: Unicode.ASCII.self)
        } catch{
            
        }
        return "Error"
    }
    
    
    func debug() async{
        if( Ip != "")
        {
            realIP=Ip
            UserDefaults.standard.set(realIP, forKey: "dirrecionIp")
        }
        await msg=urlSend(url: "http://"+Ip+":120/debug")
    print(Ip+"aqui2")
        if(msg=="prueba")
        {
            configuracionRealizada=true
            desconectar()
            
        }else{
            configuracionRealizada=false
        }
        
    }
    
    func servo(angulo:Int) async
    {
        let Angulo=String(180-angulo)
        
        await msg=urlSend(url: "http://"+Ip+":120/servo?angulo="+Angulo)
        
    }
    
    func creacionSimbolo(matriz:[Int],efecto:Int,velocidad:Int) async
    {
        
        let n = matriz.map(String.init)
        await msg=urlSend(url: "http://"+Ip+":120/creacionSimbolo?0="+n[0]+"&1="+n[1]+"&2="+n[2]+"&3="+n[3]+"&4="+n[4]+"&5="+n[5]+"&6="+n[6]+"&7="+n[7]+"&efecto="+String(efecto)+"&vel="+String(velocidad))
        
        
    }
    
    func medir() async
    {
        
        await msg=urlSend(url: "http://"+Ip+":120/medida")
        
        if(msg=="0")
        {
            msg="Error"
        }
        medida=msg
    }
    
    func Rgb(color: Color, derecho:Bool) async
    {
        var red = String(Int( UIColor(color).cgColor.components![0]*255))
        
        var green=String( Int (UIColor(color).cgColor.components![2]*255))
        
        var blue = String( Int (UIColor(color).cgColor.components![1]*255))
        
        var rgb=[red,green,blue]
        
        var aux:String
        if derecho
        {
            aux="1";//ojo derecho
        }else
        {
            aux="0";
        }
        
        let url=String("http://"+realIP+":120/ojos?rojo="+rgb[0]+"&verde="+rgb[1]+"&azul="+rgb[2]+"&derecho="+aux)
        
        await msg = urlSend(url: url)
    }
    func SeguirLineas() async
    {
        let url=String("http://"+realIP+":120/linea")
        await msg = urlSend(url: url)
        if(msg == "on")
        {
            sigueLineas=true
        }
        else if (msg == "off")
        {
            sigueLineas=false
        }
    }
    func EsquivaObstaculos() async
    {
        let url=String("http://"+realIP+":120/obstaculo")
        await msg = urlSend(url: url)
        if(msg == "on")
        {
            esquivaObstaculos=true
        }
        else if (msg == "off")
        {
            esquivaObstaculos=false
        }
    }
    
    func MandarMovimiento(x:String,y:String,dist:String) async
    {
        let url=String("http://"+realIP+":120/movimiento?x="+x+"&y="+y+"&dist="+dist)
        await msg = urlSend(url: url)
    }
    func parametrosSiguelinea(vel:String,k:String,k_der:String) async
    {
   
        let url=String("http://"+realIP+":120/parametrosSiguelinea?vel="+vel+"&ganancia="+k+"&gananciaD="+k_der)
        await msg = urlSend(url: url)
    }
    func parametrosObstaculos(vel:String,dist:String) async
    {

        let url=String("http://"+realIP+":120/parametrosObstaculos?vel="+vel+"&dist="+dist)
        await msg = urlSend(url: url)
    }
    func MandarMensaje(mensaje:String,scroll:String, velocidad:Int) async
    {
        
        var url=String("http://"+realIP+":120/mensajePantalla?mensaje="+mensaje+"&scroll="+scroll+"&velocidad="+String(velocidad))
        var urlString = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)//Elimina espacios del mensaje
        await msg = urlSend(url: urlString!)
    }
    func MandarSimbolo(simbolo:String) async
    {
        let url=String("http://"+realIP+":120/pantalla?simbolo="+simbolo)
        await msg = urlSend(url: url)
        
    }
    
    func barrido() async
    {
        let url=String("http://"+realIP+":120/barrido")
        await msg = urlSend(url: url)
        var stringMedidas = msg.components(separatedBy: "/")
        barridoMedidas = stringMedidas.compactMap { Int($0) }
       
        
    }
}


extension ESP32Manager :CBCentralManagerDelegate
{
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            startScan()
            print("encendido")
            
        case .poweredOff:
            // Alert user to turn on Bluetooth
            print("enciende ")
        case .resetting:
            // Wait for next state update and consider logging interruption of Bluetooth service
            print("reiniciando ")
        case .unauthorized:
            // Alert user to enable Bluetooth permission in app Settings
            print("no permiso ")
        case .unsupported:
            // Alert user their device does not support Bluetooth and app will not work as expected
            print("no soportado ")
        case .unknown:
            // Wait for next state updat
            print("error desconocido ")
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber)
    {
        if let pname = peripheral.name {
         
            
            if pname == "ESP32-BLE-Server" {
                self.centralManager.stopScan()
                self.myPeripheral = peripheral
                self.myPeripheral.delegate = self
                self.centralManager.connect(peripheral, options: nil)
                print("\(pname) is connected")
                
            }
        }
    }
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            // Handle error
            
            return
        }
        print("Desconectado")
        conectado=false
        // Successfully disconnected
    }
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.myPeripheral = peripheral
        peripheral.delegate = self
        myPeripheral.discoverServices(nil)
    }
}

extension ESP32Manager : CBPeripheralDelegate{
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            print(service)
            myPeripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            print(characteristic)
            if characteristic.properties.contains(.read) {
                characteristica=characteristic
                print("\(characteristic.uuid): properties contains .read")
                conectado=true
                
            }
            if characteristic.properties.contains(.write) {
                print("\(characteristic.uuid): properties contains .write")
                
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?
    ) {
        guard let data = characteristic.value else {
            // no data transmitted, handle if needed
            return
        }
        
        if characteristic.uuid == characteristicUUID {
            // Decode data and map it to your model object
            Ip=String(decoding: data, as: UTF8.self)
        }
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        if let error = error {
            // Handle error
            print(error)
            return
        }
    
    }
}
