//  RouteView.swift

import SwiftUI
import MapKit

struct RouteView: View {
    @Binding var selection : MKMapItem?
    @Binding var getDirections : Bool
    @Binding var routeDisplaying : Bool
    @Binding var route : MKRoute?
    @Binding var travelTime : Double
    @Binding var distance : Double
    @Binding var timeLabel : String
    
    var body: some View {
        HStack {
            HStack(spacing: 50) {
                VStack {
                    Text("XX:XX")
                        .font(.headline)
                    Text("arrival")
                        .font(.footnote)
                }
                
                VStack {
                    Text("\(travelTime, specifier: "%.2f")")
                        .font(.headline)
                    Text(timeLabel)
                        .font(.footnote)
                }
                
                VStack {
                    Text("\(distance, specifier: "%.2f")")
                        .font(.headline)
                    Text("mi")
                        .font(.footnote)
                }
                
                Button {
                    getDirections.toggle()
                    routeDisplaying.toggle()
                    selection = nil
                    route = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.gray)
                }
            }
        }
        .padding(.top, 25)

    }
}

#Preview {
    RouteView(selection: .constant(nil), getDirections: .constant(false), routeDisplaying: .constant(false), route:.constant(nil), travelTime: .constant(0.0), distance: .constant(0.0), timeLabel: .constant(""))
}
