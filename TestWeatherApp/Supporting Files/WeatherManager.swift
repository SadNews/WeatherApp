//
//  WeatherManager.swift
//  TestWeatherApp
//
//  Created by Андрей Ушаков on 20.08.2020.
//  Copyright © 2020 Андрей Ушаков. All rights reserved.
//

import Foundation
import CoreData

class WeatherManager: NSObject {
    static let shared = WeatherManager()
    var currentWeather: WeatherDataModel?
    var context = ContextSingltone.shared.context
    
    func getDataWith(city: String, isNewCity: Bool, completion: @escaping (Result<String>) -> Void) {
        let fullUrl =
            ("\(Constans.shared.weatherURL)\(Constans.shared.currentWeather)\(city)\(Constans.shared.apiKey)\(Constans.shared.units)")
        
        guard let url = URL(string: fullUrl) else {return}
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {return}
            let decoder = JSONDecoder()
            if city != "" {
                
                do {
                    let currentWeather = try decoder.decode(WeatherDataModel.self, from: data)
                    self.currentWeather = currentWeather
                    if isNewCity {
                        self.addNewCity(city: city)
                        
                    } else {
                        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "WeatherData")
                        do {
                            let results = try self.context?.fetch(request)
                            self.updateWeather(city: city, results: results!)
                            
                        } catch {
                            return completion(.Error(error.localizedDescription))
                        }
                    }
                    completion(.Success(""))
                } catch {
                    return completion(.Error(error.localizedDescription))
                }
            } else {
                return completion(.Error("Неверное название города"))
            }
        }.resume()
        
    }

    func addNewCity (city: String) {
        guard let entity = NSEntityDescription.entity(forEntityName: "WeatherData", in: context!) else {return}
        let cityEntity = NSManagedObject(entity: entity, insertInto: context)
        saveToDB(entity: cityEntity, city: city)
        
    }
    
    func updateWeather (city: String, results: [Any]) {
        for result in results as! [NSManagedObject] {
            let cityResult = result.value(forKey: "city") as? String
            if cityResult == city {
                
                saveToDB(entity: result, city: city)
            }
        }
    }
    func saveToDB(entity: NSManagedObject, city: String) {
        entity.setValue(city, forKey: "city")
        entity.setValue(currentWeather?.main.temp, forKey: "temperature")
        entity.setValue(currentWeather?.main.feelsLike, forKey: "feelsLike")
        entity.setValue(currentWeather?.main.humidity, forKey: "humidity")
        entity.setValue(currentWeather?.main.pressure, forKey: "pressure")
        entity.setValue(currentWeather?.weather[0].id, forKey: "id")
        try? context?.save()
    }
}
enum Result<T> {
    case Success(T)
    case Error(String)
}