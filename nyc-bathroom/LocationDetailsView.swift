//  LocationDetailsView.swift

import SwiftUI
import MapKit

struct LocationDetailsView: View {
    @Binding var mapSelection : MKMapItem?
    @Binding var show : Bool
    @State private var lookAroundScene : MKLookAroundScene?
    @Binding var getDirections : Bool
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    HStack(spacing: 220){
                        Text(mapSelection?.placemark.name ?? "")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Button() {
                            show.toggle()
                            mapSelection = nil
                        } label : {
                            Image(systemName: "xmark.circle.fill")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Text(mapSelection?.placemark.title ?? "")
                        .font(.footnote)
                        .foregroundStyle(.gray)
                }
                .padding()
            }
            
            if let scene = lookAroundScene {
                LookAroundPreview(initialScene: scene)
                    .frame(height: 200)
                    .cornerRadius(12)
                    .padding()
            }
            else {
                ContentUnavailableView("No Preview Available", systemImage: "eye.slash")
            }
            
            HStack() {
                Button {
                    getDirections = true
                    show = false
                } label : {
                    Text("Get Directions")
                        .frame(width: 140, height: 48)
                        .foregroundStyle(.white)
                        .background(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .onAppear {
            fetchScene()
        }
        .onChange(of: mapSelection, { oldValue, newValue in
            fetchScene()
        })
    }
}

extension LocationDetailsView {
    // fetch look around preview
    func fetchScene() {
        // if user selects map, then fetch scene
        if let mapSelection {
            lookAroundScene = nil
            Task {
                let request = MKLookAroundSceneRequest(mapItem: mapSelection)
                lookAroundScene = try? await request.scene
            }
        }
    }
}

#Preview {
    LocationDetailsView(mapSelection: .constant(nil), show: .constant(false), getDirections: .constant(false))
}
