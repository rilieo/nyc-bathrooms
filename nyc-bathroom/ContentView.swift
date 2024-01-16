//  ContentView.swift

import SwiftUI
import MapKit

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

    var body: some View {
        Map(position: $cameraPosition, selection: $mapSelection) {
            Marker("My Location", coordinate: .userLocation)
            
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
            RouteView(getDirections: $getDirections, routeDisplaying: $routeDisplaying, route: $route)
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
        
//        if mapResults != [] {
//            let rect = boundingMapR
//        }
    }
    
    func fetchRoute() {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: .init(coordinate: .userLocation))
        request.destination = mapSelection
        
        Task {
            // calculate route
            let result = try? await MKDirections(request: request).calculate()
            route = result?.routes.first
            routeDestination = mapSelection
            
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
