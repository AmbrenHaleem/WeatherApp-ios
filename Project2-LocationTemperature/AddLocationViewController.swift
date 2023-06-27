//
//  ViewController.swift
//  Lab3-WeatherApp-ambreenHaleem
//
//  Created by Ambreen Haleem on 2023-03-10.
//

import UIKit
import CoreLocation

// protocol used for sending data back
protocol DataEnteredDelegate : AnyObject{
    func userDidEnterInformation(info: String, lat: Double, lon: Double, tempStr: String, symbolCode: Int, errCode : Int, errMessage : String)
}

class AddLocationViewController: UIViewController,UITextFieldDelegate{
    
    // making this a weak variable so that it won't create a strong reference cycle
    weak var delegate: DataEnteredDelegate? = nil
    
    @IBOutlet weak var locationLabel: UILabel!
    
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var weatherConditionImage: UIImageView!
    
    var temp_c : String?
    var temp_f : String?
    var lat : Double = 0.0
    var lon : Double = 0.0
    var tempStr : String = ""
    var symbolCode : Int = 0
    
    var errCode : Int = 0
    var errMessage : String = ""
    
    @IBAction func onCancelButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    @IBAction func onSaveButtonTapped(_ sender: UIBarButtonItem) {
     
        // call this method on whichever class implements our delegate protocol
        delegate?.userDidEnterInformation(info: locationLabel.text!, lat: lat, lon: lon, tempStr: tempStr, symbolCode: symbolCode, errCode: errCode, errMessage: errMessage)
                
        // go back to the previous view controller
        dismiss(animated: true)
    }
    @IBAction func temperatureMetricChange(_ sender: UISwitch) {
        if (sender.isOn){
            self.temperatureLabel.text = "\(temp_c ?? "")C"
        }
        else{
            self.temperatureLabel.text = "\(temp_f ?? "")F"
        }
    }
    @IBOutlet weak var temperatureMetric: UISwitch!
    struct WeatherResponse : Decodable{
        var location : Location
        var current : Weather
        var forecast : Forecast
    }
    struct Location : Decodable{
        let name : String
        let country : String
        let lat : Double
        let lon : Double
    }
    struct Weather : Decodable{
        let temp_c : Float
        let temp_f : Float
        let feelslike_c : Float
        let condition : WeatherCondition
    }
    struct WeatherCondition : Decodable{
        let text : String
        let code : Int
    }
    struct Forecast : Decodable{
        let forecastday : [ForecastDay]
    }
    struct ForecastDay : Decodable{
        let date : String
        let day : Day
    }
    struct Day : Decodable{
        let maxtemp_c : Float
        let mintemp_c : Float
        let avgtemp_c : Float
    }
    struct LocationResponse : Decodable{
        let lat : Double
        let lon : Double
        let city : String
        let country : String
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //displaySampleImageForDemo()
        searchTextField.delegate = self
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        loadWeather(search: searchTextField.text)
        return true
    }
    private func displaySampleImageForDemo(symbolName : String){
        let config = UIImage.SymbolConfiguration(paletteColors: [.systemBlue,.systemYellow,.systemFill])
        weatherConditionImage.preferredSymbolConfiguration = config
        weatherConditionImage.image = UIImage(systemName: symbolName)
    }
    
    private func loadWeather(search: String?){
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
            
            guard let data = data else{
                print("No data found")
                return
            }
            
            guard self.errorHandling(response: response) else {
                return
            }
            
            if let weatherResponse = self.parseJson(data: data){
                print(weatherResponse.current.condition.code)
                print(weatherResponse.current.condition.text)
                
                DispatchQueue.main.async { // return back to the main thread for execution
                    self.locationLabel.text = "\(weatherResponse.location.name)"
                    self.temperatureLabel.text = "\(weatherResponse.current.temp_c)C"
                    self.temperatureMetric.isOn = true
                    self.temp_c = "\(weatherResponse.current.temp_c)"
                    self.temp_f = "\(weatherResponse.current.temp_f)"
                    self.lat = weatherResponse.location.lat
                    self.lon = weatherResponse.location.lon
                    self.tempStr = "\(weatherResponse.current.temp_c)C (H:\(weatherResponse.forecast.forecastday[0].day.maxtemp_c) L:\(weatherResponse.forecast.forecastday[0].day.mintemp_c))"
                    self.symbolCode = weatherResponse.current.condition.code
                    self.setImage(code: weatherResponse.current.condition.code, text: weatherResponse.current.condition.text)
                }
            }
        }
        
        //step 4 : Start the task
        dataTask.resume()
    }
    private func errorHandling(response: URLResponse?) -> Bool{
        if let httpResponse = response as? HTTPURLResponse{  //cast the response
            let statusCode = httpResponse.statusCode
            
            print("Status Code : \(statusCode)")
            //print("Message : \(message)")
            //errCode = statusCode
            
            if statusCode != 200 {
                DispatchQueue.main.async {
                    self.displaySampleImageForDemo(symbolName: "exclamationmark.octagon")
                    self.errCode = statusCode
                  //  self.delegate?.userDidEnterInformation(info: self.locationLabel.text!, lat: self.lat, lon: self.lon, tempStr: self.tempStr, symbolCode: self.symbolCode, errCode: self.errCode, errMessage: self.errMessage)
                            
                }
            }
            else{
                return true
            }
        }
        return false
    }
    private func getURL(query: String) -> URL? {
        let baseUrl = "https://api.weatherapi.com/v1/"
        let currentEndpoint = "forecast.json"
        let apiKey = "b8b81854b9bd4b638a7401412321041"//"4190abd1e49c475aa1a134634232903"
        guard let url = "\(baseUrl)\(currentEndpoint)?key=\(apiKey)&q=\(query)&days=1"
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
    
    @IBAction func onSearchTapped(_ sender: Any) {
        loadWeather(search: searchTextField.text)
    }
    
    private func setImage(code : Int, text : String){
        
        switch code {
            
        case 1000 :
            //print("day : Sunny")
            displaySampleImageForDemo(symbolName: "sun.max.fill")
            return
        case 1003 :
            //print("Partly cloudy")
            displaySampleImageForDemo(symbolName: "cloud.sun.fill")
            return
        case 1006 :
            //print("Cloudy")
            displaySampleImageForDemo(symbolName: "cloud.fill")
            return
        case 1009 :
            //print("Overcast")
            displaySampleImageForDemo(symbolName: "smoke.fill")
            return
        case 1030 :
            //print("mist")
            displaySampleImageForDemo(symbolName: "cloud.fog.fill")
            return
        case 1063 :
            //print("Patchy rain possible")
            displaySampleImageForDemo(symbolName: "cloud.drizzle.fill")
            return
        case 1066 :
            //print("Patchy snow possible")
            displaySampleImageForDemo(symbolName: "cloud.hail.fill")
        case 1069 :
            //print("Patchy sleet possible")
            displaySampleImageForDemo(symbolName: "cloud.sleet.fill")
            return
        case 1072 :
            //print("Patchy freezing drizzle possible")
            displaySampleImageForDemo(symbolName: "cloud.hail.fill")
            return
        case 1087 :
            //print("Thundery outbreaks possible")
            displaySampleImageForDemo(symbolName: "cloud.bolt.rain.fill")
            return
        case 1114 :
            //print("Blowing snow")
            displaySampleImageForDemo(symbolName: "cloud.snow.fill")
            return
        case 1117 :
            //print("Blizzard")
            displaySampleImageForDemo(symbolName: "wind.snow")
            return
        case 1135 :
            //print("fog")
            displaySampleImageForDemo(symbolName: "cloud.fog.fill")
            return
        case 1147 :
            //print("Freezing fog")
            displaySampleImageForDemo(symbolName: "cloud.fog")
            return
        case 1150 :
            //print("Patchy light drizzle")
            displaySampleImageForDemo(symbolName: "cloud.drizzle.fill")
            return
        case 1153 :
            //print("Light drizzle")
            displaySampleImageForDemo(symbolName: "cloud.rain.fill")
            return
        default:
            displaySampleImageForDemo(symbolName: "cloud.sun.rain")
            print("cloud.sun.rain")
            return
        }
    }
}


