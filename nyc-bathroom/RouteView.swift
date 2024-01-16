//  RouteView.swift

import SwiftUI
import MapKit

struct RouteView: View {
    @Binding var getDirections : Bool
    @Binding var routeDisplaying : Bool
    @Binding var route : MKRoute?

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
                    Text("Time")
                        .font(.headline)
                    Text("hrs")
                        .font(.footnote)
                }
                
                VStack {
                    Text("Distance")
                        .font(.headline)
                    Text("mi")
                        .font(.footnote)
                }
                
                Button {
                    getDirections.toggle()
                    routeDisplaying.toggle()
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
    RouteView(getDirections: .constant(false), routeDisplaying: .constant(false), route: .constant(nil))
}
