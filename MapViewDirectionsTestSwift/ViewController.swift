//
//  ViewController.swift
//  MapRouteTestSwift
//
//  Created by Ken Yurino on 2015/01/31.
//  Copyright (c) 2015 Ken Yurino. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UISearchBarDelegate {
    
    var locationManager: CLLocationManager!
    var userLocation: CLLocationCoordinate2D!
    var destLocation: CLLocationCoordinate2D!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var destSearchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        mapView.delegate = self
        destSearchBar.delegate = self
        
        // 位置情報取得の許可状況を確認
        let status = CLLocationManager.authorizationStatus()
        
        // 許可が場合は確認ダイアログを表示
        if(status == CLAuthorizationStatus.NotDetermined) {
            println("didChangeAuthorizationStatus:\(status)");
            self.locationManager.requestAlwaysAuthorization()
        }
        //位置情報の精度
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //位置情報取得間隔(m)
        locationManager.distanceFilter = 300
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // 検索ボタンを押したときにキーボードを隠して検索実行
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        // キーボードを隠す
        destSearchBar.resignFirstResponder()
        // セット済みのピンを削除
        self.mapView.removeAnnotations(self.mapView.annotations)
        // 描画済みの経路を削除
        self.mapView.removeOverlays(self.mapView.overlays)
        // 目的地の文字列から座標検索
        var geocoder = CLGeocoder()
        geocoder.geocodeAddressString(destSearchBar.text, {(placemarks: [AnyObject]!, error: NSError!) -> Void in
            if let placemark = placemarks?[0] as? CLPlacemark {
                // 目的地の座標を取得
                self.destLocation = CLLocationCoordinate2DMake(placemark.location.coordinate.latitude, placemark.location.coordinate.longitude)
                // 目的地にピンを立てる
                self.mapView.addAnnotation(MKPlacemark(placemark: placemark))
                self.locationManager.startUpdatingLocation()
            }
        })
    }
    
    // 位置情報取得に成功したときに呼び出されるデリゲート.
    func locationManager(manager: CLLocationManager!,didUpdateLocations locations: [AnyObject]!){
        
        userLocation = CLLocationCoordinate2DMake(manager.location.coordinate.latitude, manager.location.coordinate.longitude)
        
        var userLocAnnotation: MKPointAnnotation = MKPointAnnotation()
        userLocAnnotation.coordinate = userLocation
        userLocAnnotation.title = "現在地"
        mapView.addAnnotation(userLocAnnotation)
        // 現在地から目的地家の経路を検索
        getRoute()
    }
    
    // 位置情報取得に失敗した時に呼び出されるデリゲート.
    func locationManager(manager: CLLocationManager!,didFailWithError error: NSError!){
        print("locationManager error")
    }
    
    func getRoute()
    {
        // 現在地と目的地のMKPlacemarkを生成
        var fromPlacemark = MKPlacemark(coordinate:userLocation, addressDictionary:nil)
        var toPlacemark   = MKPlacemark(coordinate:destLocation, addressDictionary:nil)
        
        // MKPlacemark から MKMapItem を生成
        var fromItem = MKMapItem(placemark:fromPlacemark)
        var toItem   = MKMapItem(placemark:toPlacemark)
        
        // MKMapItem をセットして MKDirectionsRequest を生成
        let request = MKDirectionsRequest()
        
        request.setSource(fromItem)
        request.setDestination(toItem)
        request.requestsAlternateRoutes = false // 単独の経路を検索
        request.transportType = MKDirectionsTransportType.Any
        
        let directions = MKDirections(request:request)
        directions.calculateDirectionsWithCompletionHandler({
            (response:MKDirectionsResponse!, error:NSError!) -> Void in
            
            response.routes.count
            if (error != nil || response.routes.isEmpty) {
                return
            }
            var route: MKRoute = response.routes[0] as MKRoute
            // 経路を描画
            self.mapView.addOverlay(route.polyline!)
            // 現在地と目的地を含む表示範囲を設定する
            self.showUserAndDestinationOnMap()
        })
    }
    
    // 地図の表示範囲を計算
    func showUserAndDestinationOnMap()
    {
        // 現在地と目的地を含む矩形を計算
        var maxLat:Double = fmax(userLocation.latitude,  destLocation.latitude)
        var maxLon:Double = fmax(userLocation.longitude, destLocation.longitude)
        var minLat:Double = fmin(userLocation.latitude,  destLocation.latitude)
        var minLon:Double = fmin(userLocation.longitude, destLocation.longitude)
        
        // 地図表示するときの緯度、経度の幅を計算
        var mapMargin:Double = 1.5;  // 経路が入る幅(1.0)＋余白(0.5)
        var leastCoordSpan:Double = 0.005;    // 拡大表示したときの最大値
        var span_x:Double = fmax(leastCoordSpan, fabs(maxLat - minLat) * mapMargin);
        var span_y:Double = fmax(leastCoordSpan, fabs(maxLon - minLon) * mapMargin);
        
        var span:MKCoordinateSpan = MKCoordinateSpanMake(span_x, span_y);
        
        // 現在地を目的地の中心を計算
        var center:CLLocationCoordinate2D = CLLocationCoordinate2DMake((maxLat + minLat) / 2, (maxLon + minLon) / 2);
        var region:MKCoordinateRegion = MKCoordinateRegionMake(center, span);
        
        mapView.setRegion(mapView.regionThatFits(region), animated:true);
    }
    
    // 経路を描画するときの色や線の太さを指定
    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        if overlay is MKPolyline {
            var polylineRenderer = MKPolylineRenderer(overlay: overlay)
            polylineRenderer.strokeColor = UIColor.blueColor()
            polylineRenderer.lineWidth = 5
            return polylineRenderer
        }
        return nil
    }
}

