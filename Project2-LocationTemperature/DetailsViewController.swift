//
//  DetailsViewController.swift
//  Project2-LocationTemperature
//
//  Created by Ambreen Zahid on 2023-03-28.
//

import UIKit

class DetailsViewController: UIViewController {

    var city : String?
    var country : String?
    private var items: [weatherDetail] = []
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var weatherDetailLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        loadWeatherForecast(search: "\(city ?? "") \(country ?? "")")
        tableView.dataSource = self
    }
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        dismiss(animated: true)
    }
    private func loadWeatherForecast(search: String?) {
        print("search: \(search ?? "")")
        let days = 7;
        guard let search = search else {
            return
        }
        //step 1 : get url
        guard let url = getURL(query: search, day: days) else {
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
                
                DispatchQueue.main.async {
                    let locationName = "\(self.city ?? ""), \(self.country ?? "")"
                    let currentTemp = "\(weatherResponse.current.temp_c)C"
                    let currentWeatherCondition = weatherResponse.current.condition.text
                    let highTemp = weatherResponse.forecast.forecastday[0].day.maxtemp_c
                    let lowtemp = weatherResponse.forecast.forecastday[0].day.mintemp_c
                    
                    self.weatherDetailLabel.text = """
                    \(locationName)
                    \(currentTemp)
                    \(currentWeatherCondition)
                    High : \(highTemp)
                    Low : \(lowtemp)
                    """
//                    print("Title : \(weatherResponse.current.condition.text), Subtitle : \(weatherResponse.current.temp_c)C, Feels Like \(weatherResponse.current.feelslike_c)C, code : \(weatherResponse.current.condition.code)")
                    self.loadList(forecastDay: weatherResponse.forecast, code: weatherResponse.current.condition.code)
                   
                }
            }
        }
        
        //step 4 : Start the task
        dataTask.resume()
    }
    
    private func getURL(query: String, day: Int) -> URL? {
        let baseUrl = "https://api.weatherapi.com/v1/"
        let currentEndpoint = "forecast.json"
        let apiKey = "Add your api key"
        guard let url = "\(baseUrl)\(currentEndpoint)?key=\(apiKey)&q=\(query)&days=\(day)"
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
    
    private func loadList(forecastDay: Forecast, code: Int){
        let days = forecastDay.forecastday
        for item in days{
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dayDate = dateFormatter.date(from: item.date)  // Jan 10 2020
            dateFormatter.dateFormat = "cccc"
            let weekday = dateFormatter.string(from: dayDate!)
            let image = getAnnotationImage(code: code)
            items.append(weatherDetail(dayOfWeek: weekday, temperature: "\(item.day.avgtemp_c)C", icon: UIImage(systemName: image)))
        }
        self.tableView.reloadData()
    }
    
    private func getAnnotationImage(code: Int) -> String{
        var symbolName: String = ""
        
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
        var current : Weather
        var forecast : Forecast
    }
    struct Location : Decodable{
        let name : String
        let country : String
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
    
    struct weatherDetail{
        let dayOfWeek : String
        let temperature : String
        let icon: UIImage?
    }
}

extension DetailsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "weatherDetailCell",for: indexPath)
        let item = items[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = item.dayOfWeek
        content.secondaryText = item.temperature
        content.image = item.icon
        cell.contentConfiguration = content
        return cell
    }
}
