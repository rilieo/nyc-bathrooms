//  ViewModel.swift

import Foundation
import FirebaseFirestore
import MapKit

class ViewModel: ObservableObject {
    
//    @Published var list = [(MKMapItem, String)]()
    @Published var list = [MKMapItem]()
    
    func getLocations() {
        let db = Firestore.firestore()
        
        db.collection("coords").getDocuments { querySnapshot, error in
            
            if error == nil {
                
                if let querySnapshot = querySnapshot {
                    
                    DispatchQueue.main.async {
                        self.list = querySnapshot.documents.map { d in
                            let coordinate = CLLocationCoordinate2D(latitude: d["Latitude"] as? Double ?? 0.0, longitude: d["Longitude"] as? Double ?? 0.0)
                            let placemark = MKPlacemark(coordinate: coordinate)
                            let item = MKMapItem(placemark: placemark)
                            item.name = d["Name"] as? String ?? ""
//                            let title = d["Title"] as? String ?? ""
                            return item
                        }
                    }
                }
                else {
                    // handle error
                    self.list = [MKMapItem()]
                    
                }
            }
        }
    }
}
