import Combine
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    
    private let locationManager: CLLocationManager = CLLocationManager()
    private let locationSubject: CurrentValueSubject<CLLocationCoordinate2D?, Error> = .init(nil)
    
    var location$: AnyPublisher<CLLocationCoordinate2D?, Error> {
        locationSubject.eraseToAnyPublisher()
    }
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
           if let location = locations.first {
               locationManager.stopUpdatingLocation()
               self.locationSubject.send(location.coordinate)
           }
       }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
       print("Error requesting location: \(error.localizedDescription)")
       self.locationSubject.send(completion: .failure(error))
    }
}
