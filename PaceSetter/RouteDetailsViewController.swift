//
//  RouteDetailsViewController.swift
//  PaceSetter
//
//  Created by JessicaChen on 4/13/16.
//  Copyright © 2016 JessicaChen. All rights reserved.
//

import UIKit
import MapKit
import CoreData
import CoreLocation

class RouteDetailsViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var followButton: UIBarButtonItem!
    
    var managedObjectContext: NSManagedObjectContext!
    var distance: Double = 0
    var duration: TimeInterval = 0
    var speed: Double = 0
    var points = [CLLocationCoordinate2D]()
    var locations: NSOrderedSet?
    var routeToDisplay: Route? {
        didSet {
            if let route = routeToDisplay {
                distance = route.distance
                duration = route.duration
                speed = route.speed
                locations = route.locations
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if let locations = locations {
            for item in locations {
                let location = item as! Location
                let point = CLLocationCoordinate2DMake(location.latitude, location.longitude)
                points.append(point)
            }
        } else {
            followButton.isEnabled = false
        }
        
        if points.count == 0 || distance == 0 {
            followButton.isEnabled = false
        }
        
        distanceLabel.text = String(format: "%.1f", distance) + "m"
        
        var durationDescritor = ""
        let hour = Int(duration / 3600)
        if hour < 100 {
            durationDescritor += String(format: "%02d", hour) + ":"
        } else {
            durationDescritor += hour.description + ":"
        }
        let minute = Int((duration - Double(hour) * 3600) / 60)
        durationDescritor += String(format: "%02d", minute) + ":"
        let second = Int(duration -  Double(hour) * 3600 - Double(minute) * 60)
        durationDescritor += String(format: "%02d", second)
        durationLabel.text = durationDescritor
        
        speedLabel.text = String(format: "%.1f", speed) + "m/s"
        
        displayRoute()
    }
    
    func displayRoute() {
        if points.count == 0 {
            let alertController = UIAlertController(title: "No locations", message: "Locations have not been recorded", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: .default,handler: nil))
            self.present(alertController, animated: true, completion: nil)
        } else {
            
            let startPointAnnotation = MKPointAnnotation()
            startPointAnnotation.coordinate = points[0]
            startPointAnnotation.title = "Start location"
            mapView.addAnnotation(startPointAnnotation)
            
            let polyline = MKPolyline(coordinates: &points, count: points.count)
            mapView.add(polyline)
            
            var topLeftCoord = CLLocationCoordinate2D(latitude: -90, longitude: 180)
            var bottomRightCoord = CLLocationCoordinate2DMake(90, -180)
            
            for point in points {
                topLeftCoord.latitude = max(topLeftCoord.latitude, point.latitude)
                topLeftCoord.longitude = min(topLeftCoord.longitude, point.longitude)
                bottomRightCoord.latitude = min(bottomRightCoord.latitude, point.latitude)
                bottomRightCoord.longitude = max(bottomRightCoord.longitude, point.longitude)
            }
            
            let center = CLLocationCoordinate2D(latitude: topLeftCoord.latitude - (topLeftCoord.latitude - bottomRightCoord.latitude) / 2, longitude: topLeftCoord.longitude - (topLeftCoord.longitude - bottomRightCoord.longitude) / 2)
            
            let extraSpace = 1.1
            var latitudeDelta = abs(topLeftCoord.latitude - bottomRightCoord.latitude) * extraSpace
            var longitudeDelta = abs(topLeftCoord.longitude - bottomRightCoord.longitude) * extraSpace
            // When only one same locations are recorded
            if routeToDisplay!.distance == 0 {
                latitudeDelta = 0.0045
                longitudeDelta = 0.0045
            }
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            let region = MKCoordinateRegion(center: center, span: span)
            mapView.setRegion(region, animated: true)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "FollowRoute" {
            let controller = segue.destination as! FollowRouteViewController
            controller.routeToDisplay = routeToDisplay
            controller.walkingPoints = points
        }
    }
    
    // MARK: - MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer! {
        if overlay is MKPolyline {
            let polylineRenderer = MKPolylineRenderer(overlay: overlay)
            polylineRenderer.strokeColor = UIColor.blue
            polylineRenderer.lineWidth = 5
            return polylineRenderer
        }
        return nil
    }

}
