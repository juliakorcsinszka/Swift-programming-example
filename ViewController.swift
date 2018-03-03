

import UIKit
import MapKit
import CoreData


var artworkData: NSDictionary? = nil
var segueLocation = String()
var artworksByLocation = [[String]]()
var numberOfElementsInFile = Int()
var locationsOrderedByDistance = [String]()

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MKMapViewDelegate {
    
    
    var locationsOfArtworks = Dictionary<String, Array<Double>>()
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var context: NSManagedObjectContext?
    var originalLocation = CLLocationCoordinate2D()
    var currentElement = 0
    var numberOfLocations = 0
    var locationsArray = [String]()
    
    //number of sections
    public func numberOfSections(in tableView: UITableView) -> Int {
        return locationsOrderedByDistance.count
    }
    
    //number of rows per section
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return artworksByLocation[section].count
    }

    //text in the cell
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "myCell", for: indexPath) as UITableViewCell;
        cell.textLabel?.text = artworksByLocation[indexPath.section][indexPath.row]
        return cell
    }
    
    //title of the group according to the section number
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return locationsOrderedByDistance[section]
    }
    

    //is called if a pin is tapped
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView){
        if let annotation = view.annotation as? MKPointAnnotation
        {
            segueLocation = (annotation.title)!
        }
        self.performSegue(withIdentifier: "toMap", sender: self)
    }

    //is called when segue is performed
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "toMap"){
            let destination = segue.destination as! InformationViewController
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        //context for the tableview
        context = appDelegate.persistentContainer.viewContext
        // Do any additional setup after loading the view, typically from a nib.
            //get the URL of the data
            let url = URL(string: "https://cgi.csc.liv.ac.uk/~phil/Teaching/COMP327/artworksOnCampus/data.php?class=artworks&lastUpdate=2017-11-01")!
            //get the data from the URL
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                if error != nil {
                    print(error as Any)
                
                } else {
                    if let urlContent = data {
                    
                    do {
                        //deserialize the contents
                        let jsonResult = (try JSONSerialization.jsonObject(with: urlContent, options: JSONSerialization.ReadingOptions.mutableContainers)) as AnyObject
                        artworkData = (jsonResult as? NSDictionary)
                    } catch {
                        print("======\nJSON processing Failed\n=======")
                    }
                    
                }
            }
                
        }
        task.resume()
        
        //display zoomed in
        let span = MKCoordinateSpan(latitudeDelta: 0.013, longitudeDelta: 0.013)
        //the coordinate of the original location
        var coordinate = CLLocationCoordinate2D(latitude: 53.406566, longitude: -2.966531)
        originalLocation = coordinate
        //centre on the coordinates
        let region = MKCoordinateRegion(center: coordinate, span: span)
        self.map.setRegion(region, animated: true)
        
        while (artworkData == nil){
            //busy-waiting for the JSON file data to load
        }

        numberOfElementsInFile = ((artworkData!["artworks"] as? NSArray)?.count)!
        //reset current element value:
        currentElement = 0
        //get the location of all elements to compare them later
        while(currentElement<numberOfElementsInFile){
            let artworkLocationLat = (((artworkData!["artworks"] as? NSArray)?[currentElement] as? NSDictionary)?["lat"] as? String)!
            let artworkLocationLong = (((artworkData!["artworks"] as? NSArray)?[currentElement] as? NSDictionary)?["long"] as? String)!
            let artworkLocation = (((artworkData!["artworks"] as? NSArray)?[currentElement] as? NSDictionary)?["locationNotes"] as? String)!
            locationsOfArtworks[artworkLocation] = [Double(artworkLocationLat)!, Double(artworkLocationLong)!]
            currentElement = currentElement+1
        }
        currentElement = 0
        for currentElement in 0...numberOfElementsInFile-1 {
            let artworkLocation = (((artworkData!["artworks"] as? NSArray)?[currentElement] as? NSDictionary)?["locationNotes"] as? String)!
            let latitude = locationsOfArtworks[artworkLocation]![0]
            let longitude = locationsOfArtworks[artworkLocation]![1]
            //let currentPlace = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            self.map.setRegion(region, animated: true)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = (((artworkData!["artworks"] as? NSArray)?[currentElement] as? NSDictionary)?["locationNotes"] as? String)!
            self.map.addAnnotation(annotation)
       }
        //count the number of locations in the array
        countNumberOfLocations()
        rearrangeByDistance()
        artworkArrayForTable()
        table.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBOutlet weak var map: MKMapView!
    
    @IBOutlet weak var table: UITableView!
    
    func countNumberOfLocations(){
        currentElement = 0
        var similarity = false
        //for all the elements in the file
        for currentElement in 0...numberOfElementsInFile-1 {
            //get the location of the element
            let location = (((artworkData!["artworks"] as? NSArray)?[currentElement] as? NSDictionary)?["locationNotes"] as? String)!
            //if the array is not empty, check if the element is present
            if !locationsArray.isEmpty {
                //traverse the existing array to check for the same elements
                for index in 0...locationsArray.count-1{
                    if location == locationsArray[index]{
                        similarity = true
                    }
                }
                //if no similarities - insert new element into the array, otherwise do not do anything
                if similarity == false{
                    locationsArray.append(location)
                }
                //reset the similarity
                similarity = false
            }
            //if the array is empty, insert the first element
            else{
                locationsArray.append(location)
            }
        }
        numberOfLocations = locationsArray.count
        
    }

    func rearrangeByDistance(){
        var indexOfClosest = 0
        var closest = String()
        var currentLength = 0.0
            //traverse the array of all locations
        for orderedIndex in 0...locationsArray.count-2{
            //for each location compare all the distances
            for unorderedIndex in 0...locationsArray.count-1{
                if !locationsArray.isEmpty{
                    //find the closest and get its name
                    let currentElementKey = locationsArray[unorderedIndex]
                    //get the location of the currentArray element
                    let latitude = locationsOfArtworks[currentElementKey]![0]
                    let longitude = locationsOfArtworks[currentElementKey]![1]
                    let currentPoint = CLLocation(latitude:latitude, longitude:longitude)
                    let userLocation = CLLocation(latitude: 53.406566, longitude: -2.966531)
                    //get the distance between the 2 points
                    var length = userLocation.distance(from: currentPoint) as? Double
                    //if starting to traverse the array, assume the first distance is smallest
                    if unorderedIndex == 0 {
                        currentLength = length!
                    }
                    //if a smaller distance found, remember it
                    if length! < currentLength{
                        currentLength = length!
                        closest = locationsArray[unorderedIndex]
                        indexOfClosest = unorderedIndex
                    }
                }
            }
            //append the location with smallest distance
            locationsOrderedByDistance.append(closest)
            //remove it from the original array
            locationsArray.remove(at: indexOfClosest)
            //if it is the last element - append it
            if locationsArray.count == 1{
                closest = locationsArray[0]
                locationsOrderedByDistance.append(closest)
            }
        }
    }
    
    func artworkArrayForTable(){
    var index = 0
    var innerIndex = 0
        //for all of the elements in the array
        for index in 0...locationsOrderedByDistance.count-1{
            var currentLocation = locationsOrderedByDistance[index]
            var subArray = [String]()
            //look how many times the location is mentioned
            for innerIndex in 0...numberOfElementsInFile-1{
                //if the same location is found record all its artworks
                if (((artworkData!["artworks"] as? NSArray)?[innerIndex] as? NSDictionary)?["locationNotes"] as? String)! == currentLocation{
                    subArray.append((((artworkData!["artworks"] as? NSArray)?[innerIndex] as? NSDictionary)?["title"] as? String)!)
                }
            }
            artworksByLocation.append(subArray)
        }
    }
}

