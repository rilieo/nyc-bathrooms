//  ContentView.swift

import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    @State private var searchText : String = ""
    @State private var mapResults = [MKMapItem]()
    @State private var mapSelection : MKMapItem?
    @State private var showDetails = false
    @State private var getDirections = false
    @State private var routeDisplaying = false
    @State private var route : MKRoute?
    @State private var routeDestination : MKMapItem?
    @State private var distance : Double = 0.0
    @State private var travelTime : Double = 0.0
    @State private var timeLabel : String = ""
    
    @ObservedObject var model = ViewModel()
    
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        Map(position: $locationManager.region, selection: $mapSelection) {
            
            Annotation("My Location", coordinate: .userLocation) {
                ZStack {
                    Circle()
                        .frame(width: 40, height: 40)
                        .foregroundStyle(.blue.opacity(0.25))
                    
                    Circle()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(.white)
                    
                    Circle()
                        .frame(width: 15, height: 15)
                        .foregroundStyle(.blue)
                        
                }
            }
            
            // create markers for each location
            ForEach(model.list, id: \.self) { item in
                if routeDisplaying {
                    if item == routeDestination {
                        Marker(item: item)
                    }
                }
                else {
                    Marker(item: item)
                }
                
            }
            
            // generate route outline
            if let route {
                MapPolyline(route.polyline)
                    .stroke(.blue, lineWidth: 7)
            }
        }
        .overlay(alignment: .topLeading){
            Link(destination: URL(string: "https://github.com/rilieo/nyc-bathrooms/issues")!) {
                Image(systemName: "plus.app.fill")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(.gray)
            }
            .padding()

        }
        .onChange(of: mapSelection, { oldValue, newValue in
            showDetails = newValue != nil
        })
        .onChange(of: getDirections, { oldValue, newValue in
            if newValue {
                fetchRoute()
            }
        })
        .sheet(isPresented: $showDetails, content: {
            LocationDetailsView(mapSelection: $mapSelection, show: $showDetails, getDirections: $getDirections)
                .presentationDetents([.height(400)])
                .presentationBackgroundInteraction(.enabled(upThrough: .height(400)))
                .presentationCornerRadius(12)
        })
        .sheet(isPresented: $getDirections, content: {
            RouteView(selection: $mapSelection, getDirections: $getDirections, routeDisplaying: $routeDisplaying, route: $route, travelTime: $travelTime, distance: $distance, timeLabel: $timeLabel)
                .presentationDetents([.height(50)])
                .presentationBackgroundInteraction(.enabled(upThrough: .height(50)))
                .presentationCornerRadius(12)
            
        })
        .onAppear {
            locationManager.checkIfLocationIsEnabled()
        }
        .mapControls(){
            MapPitchToggle()
            MapUserLocationButton()
        }
    }
    
    init() {
        model.getLocations()
    }
}

extension ContentView {
    
    // generate route to destination
    func fetchRoute() {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: .init(coordinate: .userLocation))
        request.destination = mapSelection
        request.transportType = .walking
        
        Task {
            // calculate route
            let result = try? await MKDirections(request: request).calculate()
            route = result?.routes.first
            routeDestination = mapSelection
            
            calculateDistance()
            calculateTravelTime()
            
            withAnimation(.snappy) {
                routeDisplaying = true
                showDetails = false
                
                // adjust camera position to fit whole route
                if let rect = route?.polyline.boundingMapRect, routeDisplaying {
                    locationManager.region = .rect(rect)
                }
            }
        }
    }
    
    // calculate distance between two points
    func calculateDistance() {
        
        let latitude1 = routeDestination?.placemark.coordinate.latitude
        let longitude1 = routeDestination?.placemark.coordinate.longitude
        let latitude2 = MKMapItem(placemark: .init(coordinate: .userLocation)).placemark.coordinate.latitude
        let longitude2 = MKMapItem(placemark: .init(coordinate: .userLocation)).placemark.coordinate.longitude
        
        let location1 = CLLocation(latitude: latitude1 ?? 0.0, longitude: longitude1 ?? 0.0)
        let location2 = CLLocation(latitude: latitude2, longitude: longitude2)
        
        // convert to miles
        self.distance = location1.distance(from: location2) / 1609
        
    }
    
    // calculate travel time to destination
    func calculateTravelTime() {
        let time = route?.expectedTravelTime ?? 0.0
        var travelTime : Double
        
        // convert to second(s)
        if (time < 60) {
            travelTime = time
            
            if time == 1 {
                self.timeLabel = "sec"
            }
            else {
                self.timeLabel = "secs"
            }
        }
        // convert to minute(s)
        else if (time < 3600) {
            var minutes = time / 60.0
            minutes = round(minutes * 1000) / 1000
            travelTime = minutes
            
            if (minutes == 1) {
                self.timeLabel = "min"
            }
            else {
                self.timeLabel = "mins"
            }
        }
        // convert to hour(s)
        else {
            var hours = time / 3600.0
            hours = round(hours * 1000) / 1000
            travelTime = hours
            
            if (hours == 1) {
                self.timeLabel = "hr"
            }
            else {
                self.timeLabel = "hrs"
            }
        }
        
        self.travelTime = travelTime
    }

}

extension CLLocationCoordinate2D {
    static var userLocation : CLLocationCoordinate2D {
        return .init(latitude: 40.69428652509099, longitude: -73.9864184163171)
    }
}

extension MKCoordinateRegion {
    static var userRegion : MKCoordinateRegion {
        return .init(center: .userLocation,
                     latitudinalMeters: 1000,
                     longitudinalMeters: 1000)
    }
}

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var region = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.694479714906905, longitude: -73.98657742163459),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )
    
    var locationManager : CLLocationManager?
    
    func checkIfLocationIsEnabled() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager = CLLocationManager()
            locationManager!.delegate = self
        }
        else {
            print("Location services not enabled")
        }
    }
    
    private func checkLocationAuthorization() {
        guard let locationManager = self.locationManager else { return }
        
        switch locationManager.authorizationStatus {
            
        case .notDetermined :
            locationManager.requestWhenInUseAuthorization()
        case .restricted :
            print("Location Restricted")
            
        case .denied :
            print("Location Denied")
        
        case .authorizedWhenInUse, .authorizedAlways :
            region = MapCameraPosition.region(
                MKCoordinateRegion(
                    center: locationManager.location?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0),
                    span:
                        MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                )
            )
        @unknown default :
            break
            
        }
        
    }
}


#Preview {
    ContentView()
}
