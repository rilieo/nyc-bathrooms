//  ContentView.swift

import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    @State private var cameraPosition = MapCameraPosition.automatic
    @State private var searchText : String = ""
    @State private var mapResults = [MKMapItem]()
    @State private var mapSelection : MKMapItem? // ? is optional
    @State private var showDetails = false
    @State private var getDirections = false
    @State private var routeDisplaying = false
    @State private var route : MKRoute?
    @State private var routeDestination : MKMapItem?
    @State private var distance = 0.0
    @State private var travelTime = 0.0
    @State private var timeLabel : String = ""
    
    var body: some View {
        Map(position: $cameraPosition, selection: $mapSelection) {
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
            
            ForEach(mapResults, id: \.self) { item in
                if routeDisplaying {
                    if item == routeDestination {
                        Marker(item: item)
                    }
                }
                else{
                    Marker(item: item)
                }
            }
            
            if let route {
                MapPolyline(route.polyline)
                    .stroke(.blue, lineWidth: 7)
            }
        }
        .overlay(alignment: .top){
            TextField("Search for a place", text: $searchText)
                .font(.subheadline)
                .padding(12)
                .background(.white)
                .padding(8)
                .shadow(radius: 10)
        }
        .onSubmit(of: .text) {
            Task { await searchLocations() }
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
        .mapControls(){
            MapPitchToggle()
            MapUserLocationButton()
        }
        
    }
}

extension ContentView {
    
    func searchLocations() async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = .userRegion
        
        let search = try? await MKLocalSearch(request: request).start()
        self.mapResults = search?.mapItems ?? []
    }
    
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
                    cameraPosition = .rect(rect)
                }
            }
        }
    }
    
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
    
    func calculateTravelTime() {
        let time = route?.expectedTravelTime ?? 0.0
        var travelTime : Double
        
        // second(s)
        if time < 60 {
            travelTime = time
            
            if time == 1 {
                self.timeLabel = "sec"
            }
            else {
                self.timeLabel = "secs"
            }
        }
        // minute(s)
        else if time < 3600 {
            var minutes = time / 60.0
            minutes = round(minutes * 1000) / 1000
            travelTime = minutes
            
            if minutes == 1 {
                self.timeLabel = "min"
            }
            else {
                self.timeLabel = "mins"
            }
        }
        // hour(s)
        else {
            var hours = time / 3600.0
            hours = round(hours * 1000) / 1000
            travelTime = hours
            
            if hours == 1 {
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
        return .init(latitude: 29.557110, longitude: -95.421643)
    }
}

extension MKCoordinateRegion {
    static var userRegion : MKCoordinateRegion {
        return .init(center: .userLocation,
                     latitudinalMeters: 1000,
                     longitudinalMeters: 1000)
    }
}


#Preview {
    ContentView()
}
