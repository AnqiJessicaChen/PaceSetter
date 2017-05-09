//
//  WalkingViewController.swift
//  PaceSetter
//
//  Created by JessicaChen on 3/18/16.
//  Copyright © 2016 JessicaChen. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class WalkingViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    
    let locationManager = CLLocationManager()
    var points = [CLLocationCoordinate2D]()
    var lastLocation: CLLocation?
    var distance: Double = 0
    var date = Date()
    var timer = Timer()
    
    var managedObjectContext: NSManagedObjectContext!
    var route: Route!
    
    @IBAction func startWalking(_ sender: AnyObject) {
        let authStatus = CLLocationManager.authorizationStatus()
        
        if authStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            return
        }
        
        if authStatus == .denied || authStatus == .restricted {
            showLocationServicesDeniedAlert()
            return
        }
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        points.removeAll()
        lastLocation = nil
        distance = 0
        date = Date()
        
        startButton.isEnabled = false
        stopButton.isEnabled = true
        distanceLabel.text = distance.description + "m"
        speedLabel.text = "0.0m/s"
        durationLabel.text = "00:00:00"
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(WalkingViewController.updateTime), userInfo: nil, repeats: true)
        let overlays = mapView.overlays
        mapView.removeOverlays(overlays)
        
        let region = MKCoordinateRegionMakeWithDistance(mapView.userLocation.coordinate, 100, 100)
        mapView.setRegion(region, animated: true)
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.startUpdatingLocation()
        
        let routeEntity = NSEntityDescription.entity(forEntityName: "Route", in: managedObjectContext)
        route = Route(entity: routeEntity!, insertInto: managedObjectContext)
        route.date = date
        //locations = route.locations!.mutableCopy() as! NSMutableOrderedSet

    }
    @IBAction func stopWalking(_ sender: AnyObject) {
        UIApplication.shared.isIdleTimerDisabled = false
        locationManager.stopUpdatingLocation()
        stopButton.isEnabled = false
        startButton.isEnabled = true
        
        route.distance = distance
        route.duration = Date().timeIntervalSince(date)
        route.speed = route.distance / route.duration
        timer.invalidate()
        
        distanceLabel.text = String(format: "%.1f", distance) + "m"
        speedLabel.text = String(format: "%.1f", route.speed) + "m/s"
        
        do {
            try managedObjectContext.save()
        } catch {
            fatalError("Error: \(error)")
        }
    }
    
    func showLocationServicesDeniedAlert() {
        let alert = UIAlertController(title: "Location Services Disabled", message: "Please enable location services for this app in Settings.", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    func updateTime() {
        let currentTime = Date()
        var elapsedTime: TimeInterval = currentTime.timeIntervalSince(date)
        let hour = Int(elapsedTime / 3600)
        elapsedTime = elapsedTime - Double(hour) * 3600
        let minute = Int(elapsedTime / 60)
        elapsedTime = elapsedTime - Double(minute) * 60
        let second = Int(elapsedTime)
        durationLabel.text = String(format: "%02d", hour) + ":" + String(format: "%02d", minute) + ":" + String(format: "%02d", second)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("didFailWithError \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.last!
        print("didUpdateLocations \(newLocation)")
        
        if newLocation.horizontalAccuracy < 10 {
            let location = NSEntityDescription.insertNewObject(forEntityName: "Location", into: managedObjectContext) as! Location
            location.latitude = newLocation.coordinate.latitude
            location.longitude = newLocation.coordinate.longitude
            location.elapsedTime = newLocation.timestamp.timeIntervalSince(date)
            location.route = route
            
            let region = MKCoordinateRegionMakeWithDistance(mapView.userLocation.coordinate, 100, 100)
            mapView.setRegion(region, animated: true)
            
            let overlays = mapView.overlays
            mapView.removeOverlays(overlays)
            points.append(newLocation.coordinate)
            let polyline = MKPolyline(coordinates: &points, count: points.count)
            mapView.add(polyline)
            
            if let lastLocation = lastLocation {
                distance += newLocation.distance(from: lastLocation)
                distanceLabel.text = String(format: "%.1f", distance) + "m"
            }
            lastLocation = newLocation
            speedLabel.text = String(format: "%.1f", newLocation.speed) + "m/s"
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
