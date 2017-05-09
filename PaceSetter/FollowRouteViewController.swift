//
//  FollowRouteViewController.swift
//  PaceSetter
//
//  Created by JessicaChen on 4/18/16.
//  Copyright © 2016 JessicaChen. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class FollowRouteViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var previousDistanceLabel: UILabel!
    @IBOutlet weak var currentDistanceLabel: UILabel!
    
    var routeToDisplay: Route? {
        didSet {
            if let route = routeToDisplay {
                locations = route.locations
            }
        }
    }
    var locations: NSOrderedSet?
    var walkingPoints = [CLLocationCoordinate2D]()
    var finishedWalkingPoints = [CLLocationCoordinate2D]()
    var unfinishedWalk: MKPolyline!
    var finishedWalk: MKPolyline!
    let startPointAnnotation = MKPointAnnotation()
    let endPointAnnotation = MKPointAnnotation()
    var timer = Timer()
    var startTime = Date()
    
    let locationManager = CLLocationManager()
    var points = [CLLocationCoordinate2D]()
    var currentWalk: MKPolyline!
    var previousDistance: Double = 0
    var currentDistance: Double = 0
    var lastPreviousWalkLocation: CLLocation?
    var lastCurrentWalkLocation: CLLocation?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        unfinishedWalk = MKPolyline(coordinates: &walkingPoints, count: walkingPoints.count)
        mapView.add(unfinishedWalk)
        
        finishedWalk = MKPolyline(coordinates: &finishedWalkingPoints, count: finishedWalkingPoints.count)
        mapView.add(finishedWalk)
        
        currentWalk = MKPolyline(coordinates: &points, count: points.count)
        
        if walkingPoints.count > 0 {
            let startPoint = walkingPoints[0]
            let endPoint = walkingPoints.last!
            
            startPointAnnotation.coordinate = startPoint
            startPointAnnotation.title = "Start Location"
            mapView.addAnnotation(startPointAnnotation)
            endPointAnnotation.coordinate = endPoint
            endPointAnnotation.title = "Destination"
            mapView.addAnnotation(endPointAnnotation)
            
            let region = MKCoordinateRegionMakeWithDistance(startPoint, 100, 100)
            mapView.setRegion(region, animated: true)
        }
    }
    
    @IBAction func startFollowing(_ sender: AnyObject) {
        let userCoordinate = mapView.userLocation.coordinate
        let userLocation = CLLocation(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)
        let startCoordinate = walkingPoints[0]
        let startLocation = CLLocation(latitude: startCoordinate.latitude, longitude: startCoordinate.longitude)
        
        if userLocation.distance(from: startLocation) > 10 {
            let alertController = UIAlertController(title: "Go to start location", message: "You are too far away from the start location. Please go to the start location indicated by a green pin.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: .default,handler: nil))
            self.present(alertController, animated: true, completion: nil)
        } else {
            startButton.isEnabled = false
            stopButton.isEnabled = true
            
            finishedWalkingPoints.removeAll()
            mapView.remove(finishedWalk)
        
            points.removeAll()
            mapView.remove(currentWalk)
            
            previousDistance = 0
            previousDistanceLabel.text = "0.0"
            lastPreviousWalkLocation = nil
            currentDistance = 0
            currentDistanceLabel.text = "0.0"
            lastCurrentWalkLocation = nil
            
            startTime = Date()
            durationLabel.text = "00:00:00"
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(FollowRouteViewController.updateTime), userInfo: nil, repeats: true)
            
            let region = MKCoordinateRegionMakeWithDistance(mapView.userLocation.coordinate, 100, 100)
            mapView.setRegion(region, animated: true)
            
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            locationManager.startUpdatingLocation()
        }
    }
    
    @IBAction func stopFollowing(_ sender: AnyObject) {
        locationManager.stopUpdatingLocation()
        startButton.isEnabled = true
        stopButton.isEnabled = false
        timer.invalidate()
    }
    
    func updateTime() {
        let currentTime = Date()
        var elapsedTime = currentTime.timeIntervalSince(startTime)
        
        if Int(elapsedTime) == Int(routeToDisplay!.duration) {
            stopFollowing(stopButton)
        }
        
        if let locations = locations {
            for (index, value) in locations.enumerated() {
                let location = value as! Location
                if round(location.elapsedTime) == round(elapsedTime) {
                    
                    let numOfFinishedPoints = finishedWalkingPoints.count
                    for i in numOfFinishedPoints...index {
                        let point = walkingPoints[i]
                        finishedWalkingPoints.append(point)
                        
                        let newLocation = CLLocation(latitude: point.latitude, longitude: point.longitude)
                        if let lastLocation = lastPreviousWalkLocation {
                            previousDistance += newLocation.distance(from: lastLocation)
                            previousDistanceLabel.text = String(format: "%.1f", previousDistance)
                        }
                        lastPreviousWalkLocation = newLocation
                    }
                    
                    mapView.remove(finishedWalk)
                    finishedWalk = MKPolyline(coordinates: &finishedWalkingPoints, count: finishedWalkingPoints.count)
                    mapView.add(finishedWalk)
                    
//                    let region = MKCoordinateRegionMakeWithDistance(finishedWalkingPoints.last!, 100, 100)
//                    mapView.setRegion(region, animated: true)
                    
                    break
                }
            }
        }
        
        let hour = Int(elapsedTime / 3600)
        elapsedTime = elapsedTime - Double(hour) * 3600
        let minute = Int(elapsedTime / 60)
        elapsedTime = elapsedTime - Double(minute) * 60
        let second = Int(elapsedTime)
        durationLabel.text = String(format: "%02d", hour) + ":" + String(format: "%02d", minute) + ":" + String(format: "%02d", second)
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("didFailWithError \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.last!
        //print("didUpdateLocations \(newLocation)")
        
        if newLocation.horizontalAccuracy < 10 {
            let region = MKCoordinateRegionMakeWithDistance(mapView.userLocation.coordinate, 100, 100)
            mapView.setRegion(region, animated: true)
            
            mapView.remove(currentWalk)
            points.append(newLocation.coordinate)
            currentWalk = MKPolyline(coordinates: &points, count: points.count)
            mapView.add(currentWalk)
            
            if let lastLocation = lastCurrentWalkLocation {
                currentDistance += newLocation.distance(from: lastLocation)
                currentDistanceLabel.text = String(format: "%.1f", currentDistance)
            }
            lastCurrentWalkLocation = newLocation
        }
    }
    
    // MARK: - MKMapViewDelegate

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer! {
        if overlay is MKPolyline {
            let polyline = overlay as! MKPolyline
            let polylineRenderer = MKPolylineRenderer(polyline: polyline)
            if polyline == unfinishedWalk {
                polylineRenderer.strokeColor = UIColor.gray
                polylineRenderer.lineWidth = 3
                polylineRenderer.lineDashPattern = [2, 7]
                return polylineRenderer
            }
            if polyline == finishedWalk {
                polylineRenderer.strokeColor = UIColor.black
                polylineRenderer.lineWidth = 5
                return polylineRenderer
            }
            if polyline == currentWalk {
                polylineRenderer.strokeColor = UIColor.red
                polylineRenderer.lineWidth = 4
                return polylineRenderer
            }
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? MKPointAnnotation {
            let annotationView: MKPinAnnotationView
            if annotation == startPointAnnotation {
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "start")
                annotationView.canShowCallout = true
                annotationView.pinTintColor = UIColor.green
                return annotationView
            }
            if annotation == endPointAnnotation {
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "end")
                annotationView.canShowCallout = true
                annotationView.pinTintColor = UIColor.red
                return annotationView
            }
        }
        return nil
    }

}
