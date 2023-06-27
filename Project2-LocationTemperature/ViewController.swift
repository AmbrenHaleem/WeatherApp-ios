//
//  ViewController.swift
//  Project2-LocationTemperature
//
//  Created by Ambreen Haleem on 2023-03-27.
//

import UIKit
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate, DataEnteredDelegate {
   
    @IBOutlet weak var mapView: MKMapView!
    private let locationManager = CLLocationManager()
    private var city : String?
    private var country : String?
    
    private let segueScreenAddLocation = "goToAddLocationScreen"
    private let segueScreenWeatherDetails = "goToDetailsScreen"
    
    private var items: [ListItem] = []  
    
    @IBOutlet weak var locationTableView: UITableView!
    private var selectedIndex: IndexPath!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        
        locationTableView.dataSource = self
        locationTableView.delegate = self
        
        LoadErrorListData()
       
    }
    
    func LoadErrorListData(){
        guard let dataPath = getDataPath() else {
            return
        }
        
        let decoder = PropertyListDecoder()
        do {
            let data = try Data(contentsOf: dataPath)
            let decodedData = try
            decoder.decode([ItemError].self, from: data)
            
            for errorItem in decodedData {
                let item = ListItem(title: getErrorMessage(code: errorItem.code), code: errorItem.code, icon: UIImage(systemName: getErrorImage(code: errorItem.code))!)
                
                self.items.append(item)
                self.locationTableView.reloadData()
                }
            }
            catch {
                print("Error decoding \(error)")
            }
        
    }
    
    @IBAction func onBarItemTapped(_ sender: UIBarButtonItem) {
        print("Bar Item tapped \(sender.tag)")
        performSegue(withIdentifier: "goToAddLocationScreen", sender: self)
    }
    
    private func addAnnotation(location: CLLocation, tempInCelcius: String, title : String, subTitle: String, code: Int){
        
        // set annotation title, subtitle and glyph text
        let annotation = MyAnnotation(coordinate: location.coordinate,
                                      title: title,
                                      subtitle: subTitle,
                                      glyphText: tempInCelcius,
                                      code: code)
        mapView.addAnnotation(annotation)
    }
    
    private func setupMap(location: CLLocation){
        
        //set delegate
        mapView.delegate = self
        
        //get current location
       
        let radiusInMeters: CLLocationDistance = 1000
        
        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: radiusInMeters, longitudinalMeters: radiusInMeters)
        mapView.setRegion(region, animated: true)
        
        //camera boundaries
        let cameraBoundary = MKMapView.CameraBoundary(coordinateRegion: region)
        mapView.setCameraBoundary(cameraBoundary, animated: true)
        
        //control zooming
        let zoomRange = MKMapView.CameraZoomRange(maxCenterCoordinateDistance: 100000)
        mapView.setCameraZoomRange(zoomRange, animated: true)
    }
    
    private func loadWeather(search: String?, location: CLLocation) {
        
        guard let search = search else {
            return
        }
        //step 1 : get url
        guard let url = getURL(query: search) else {
            print("Could not get URL")
            return
        }
        //step 2 : create url session
        let session = URLSession.shared
        
        //step 3 : create task for session
        let dataTask = session.dataTask(with: url) { data, response, error in
            //network call finished
            print("Network call complete")
            
            guard error == nil else
            {
                print("Received error")
                return
            }
            
            guard let data=data else{
                print("No data found")
                return
            }
            
            if let weatherResponse = self.parseJson(data: data){
//                print(weatherResponse.current.condition.code)
//                print(weatherResponse.current.condition.text)
                
                DispatchQueue.main.async { [self] in
                  
                    self.city = weatherResponse.location.name
                    self.country = weatherResponse.location.country
                    print("Title : \(weatherResponse.current.condition.text), Subtitle : \(weatherResponse.current.temp_c)C, Feels Like \(weatherResponse.current.feelslike_c)C, code : \(weatherResponse.current.condition.code)")
                    
                    self.addAnnotation(location: location,
                                       tempInCelcius: "\(weatherResponse.current.temp_c)C",
                                       title: weatherResponse.current.condition.text,
                                       subTitle: "\(weatherResponse.current.temp_c)C, Feels Like \(weatherResponse.current.feelslike_c)C",
                                       code: weatherResponse.current.condition.code )
                   
                }
            }
        }
        
        //step 4 : Start the task
        dataTask.resume()
    }
    
    private func getURL(query: String) -> URL? {
        let baseUrl = "https://api.weatherapi.com/v1/"
        let currentEndpoint = "current.json"
        let apiKey = "4190abd1e49c475aa1a134634232903"
        guard let url = "\(baseUrl)\(currentEndpoint)?key=\(apiKey)&q=\(query)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else
        {
            return nil
        }
        
        return URL(string: url)
    }
    
    private func parseJson(data : Data) -> WeatherResponse?{
        let decoder = JSONDecoder()
        var weather : WeatherResponse?
        
        do{
            weather = try decoder.decode(WeatherResponse.self, from: data)
            
        }catch{
            print("Error decoding")
        }
        return weather
    }
    
    private func getAnnotationColor(temperature: String) -> UIColor{
        let temp = Int(temperature) ?? 0
        var color : UIColor = UIColor.purple
        
        if temp < 0
        {
            color = UIColor.purple
        }
        if temp >= 0 && temp <= 11
        {
            color = UIColor.blue
        }
        if temp >= 12 && temp <= 16
        {
            color = UIColor.cyan
        }
        if temp >= 17 && temp <= 24
        {
            color = UIColor.yellow
        }
        if temp >= 25 && temp <= 30
        {
            color = UIColor.orange
        }
        if temp > 35
        {
            color = UIColor.red
        }
        return color
    }
    private func getErrorImage(code: Int) -> String{
        var symbolName: String = ""
        print("errorCode : \(code)")
        switch code {
            
        case 403 :
            symbolName = "key.fill"
        case 400 :
            symbolName = "location.magnifyingglass"
        default:
            symbolName = "xmark.octagon"
            
        }
        return symbolName
    }
    private func getErrorMessage(code: Int) -> String{
        var message: String = ""
        print("errorCode : \(code)")
        switch code {
            
        case 403 :
            message = "Error message when API key is invalid"
        case 400 :
            message = "Error message when city is not found"
        default:
            message = "Another error message"
        }
        return message
    }
    private func getAnnotationImage(code: Int) -> String{
        var symbolName: String = ""
        print("symbolCode : \(code)")
        switch code {
            
        case 1000 :
            //print("day : Sunny")
            symbolName = "sun.max.fill"
            
        case 1003 :
            //print("Partly cloudy")
            symbolName = "cloud.sun.fill"
            
        case 1006 :
            //print("Cloudy")
            symbolName =  "cloud.fill"
            
        case 1009 :
            //print("Overcast")
            symbolName = "smoke.fill"
            
        case 1030 :
            //print("mist")
            symbolName = "cloud.fog.fill"
            
        case 1063 :
            //print("Patchy rain possible")
            symbolName = "cloud.drizzle.fill"
            
        case 1066 :
            //print("Patchy snow possible")
            symbolName = "cloud.hail.fill"
        case 1069 :
            //print("Patchy sleet possible")
            symbolName = "cloud.sleet.fill"
            
        case 1072 :
            //print("Patchy freezing drizzle possible")
            symbolName = "cloud.hail.fill"
            
        case 1087 :
            //print("Thundery outbreaks possible")
            symbolName = "cloud.bolt.rain.fill"
            
        case 1114 :
            //print("Blowing snow")
            symbolName = "cloud.snow.fill"
            
        case 1117 :
            //print("Blizzard")
            symbolName = "wind.snow"
            
        case 1135 :
            //print("fog")
            symbolName = "cloud.fog.fill"
            
        case 1147 :
            //print("Freezing fog")
            symbolName = "cloud.fog"
            
        case 1150 :
            //print("Patchy light drizzle")
            symbolName = "cloud.drizzle.fill"
            
        case 1153 :
            //print("Light drizzle")
            symbolName = "cloud.rain.fill"
            
        default:
            symbolName = "cloud.sun.rain"
            
        }
        return symbolName
    }
    
    struct WeatherResponse : Decodable{
        var location : Location
        var current : weather
    }
    struct Location : Decodable{
        let name : String
        let country : String
    }
    struct weather : Decodable{
        let temp_c : Float
        let temp_f : Float
        let feelslike_c : Float
        let condition : WeatherCondition
    }
    struct WeatherCondition : Decodable{
        let text : String
        let code : Int
    }
    struct LocationResponse : Decodable{
        var lat : Double
        var lon : Double
        var city : String
        var country : String
    }
    struct ListItem  {
        let title: String
        let code : Int
        /* let latitude: Double
        let longitude: Double
        let subTitle: String
        let symbolCode: Int */
        let icon : UIImage
    }
    struct ItemError : Codable {
        let title: String
        let code: Int
        //let image: UIImage
    }
}

extension ViewController: MKMapViewDelegate {
   
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "myIdentifier"
        var view: MKMarkerAnnotationView
        
        // check to see if we have a view we can reuse
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView {
            // get updated annotation
            dequeuedView.annotation = annotation
            // use our reusable view
            view = dequeuedView
        }else {
            
            view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.canShowCallout = true
            
            // set the position of the callout
            view.calloutOffset = CGPoint(x: 0, y: 10)
            
            // add a button to the right side of the callout
            let button = UIButton(type: .detailDisclosure)
            button.tag = 100
            view.rightCalloutAccessoryView = button
            
            // add an image to the left side of callout
            let image = UIImage(systemName: "graduationcap.circle.fill")
            view.leftCalloutAccessoryView = UIImageView(image: image)
            
            // change colour of pin/marker
            view.markerTintColor = UIColor.purple
            
            // change color of accessories
            view.tintColor = UIColor.systemRed
            
            if let myAnnotation = annotation as? MyAnnotation {
                view.glyphText = myAnnotation.glyphText
                
                let temp = myAnnotation.glyphText!.components(separatedBy: "C")
                print("Glyph Text : \(temp[0])")
                // Get color for annotation
                let color = getAnnotationColor(temperature: temp[0])
                view.markerTintColor = color
                view.tintColor = color
                // get image for annotation
                let annotationImage = getAnnotationImage(code: myAnnotation.code ?? 0)
                // add an image to the left side of callout
                let image = UIImage(systemName: annotationImage)
                view.leftCalloutAccessoryView = UIImageView(image: image)
            }
        }
        return view
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        print("Button Clicked \(control.tag)")
        performSegue(withIdentifier: "goToDetailsScreen", sender: self)
        /*
        guard let coordinates = view.annotation?.coordinate else {
            return
        }
        let launchOptions = [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
        ]
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinates))
        mapItem.openInMaps(launchOptions: launchOptions) */
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == segueScreenWeatherDetails{
            let viewController = segue.destination as! DetailsViewController
            viewController.city = self.city
            viewController.country = self.country
            print("country : \(self.country ?? "")")
        }
        if segue.identifier == segueScreenAddLocation {
            let viewController = segue.destination as! AddLocationViewController
            viewController.delegate = self
        }
    }
    func userDidEnterInformation(info: String, lat: Double, lon: Double, tempStr: String, symbolCode: Int, errCode: Int, errMessage: String) {
            print("data from weather Screen : \(info), \(lat), \(lon), \(tempStr), \(symbolCode), \(errCode)")
        //add item to the list
        //let item = ListItem(title: info, latitude: lat, longitude: lon, subTitle: tempStr, symbolCode: symbolCode, //icon: UIImage(systemName: getAnnotationImage(code: symbolCode))!)
        let item = ListItem(title: getErrorMessage(code: errCode), code: errCode, icon: UIImage(systemName: getErrorImage(code: errCode))!)
        
        self.items.append(item)
        self.locationTableView.reloadData()
        
        saveDataInPList(title : title ?? "", errCode : errCode);
    }
    
    func getDataPath() -> URL?{
        let dataPath = FileManager.default.urls(for: .documentDirectory, in:.userDomainMask).first?.appendingPathComponent("ErrorList.plist")
        return dataPath
    }
   
    func saveDataInPList(title : String, errCode: Int){
        //get file path
        guard let dataPath = getDataPath() else {
            print("Error in datapath")
            return
        }
        print(dataPath)
        let image = UIImage(systemName: getErrorImage(code: errCode))!
        let error = [ItemError(title: title, code: errCode)]
        let encoder = PropertyListEncoder()
        do {
            let data = try encoder.encode(error)
            try data.write(to: dataPath)
        } catch {
            print("Error encoding: \(error)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
       // print("Got Location")
        if let location = locations.last {
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            print("Lat,Lon\(latitude) \(longitude)")
            //let loc  = loadUserCurrentLocation()
            setupMap(location: CLLocation(latitude: latitude, longitude: longitude))
            loadWeather(search: "\(location.coordinate.latitude),\(location.coordinate.longitude)",location: CLLocation(latitude: latitude, longitude: longitude))
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "locationCell",for: indexPath)
        let item = items[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = "Code : \(item.code)"
        content.secondaryText = item.title
        content.image = item.icon
        cell.contentConfiguration = content
        return cell
    }
}

extension ViewController: UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // print("row selected : \(indexPath)")
        
        let isChecked = tableView.cellForRow(at: indexPath)?.accessoryType == .checkmark
        let item = items[indexPath.row]
        if self.selectedIndex != nil {
            tableView.cellForRow(at: self.selectedIndex)?.accessoryType = .none
        }
        if (isChecked) {
            tableView.cellForRow(at: indexPath)?.accessoryType = .none
        } else {
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
            self.selectedIndex = indexPath
            // setup map
          //  print("Lat,Lon\(item.latitude) \(item.longitude)")
            
         //  setupMap(location: CLLocation(latitude: item.latitude, longitude: item.longitude))
          //  loadWeather(search:"\(item.latitude),\(item.longitude)",location: CLLocation(latitude: item.latitude, longitude: item.longitude))
        }
    }
}




