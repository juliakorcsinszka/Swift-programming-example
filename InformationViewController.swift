//
//  InformationViewController.swift
//
//  Created by Julia Korcsinszka
//  Copyright © 2017 Julia Korcsinszka. All rights reserved.
//

import UIKit
import CoreData

class InformationViewController: UIViewController {
    
    var locationOfElement = Int()
    let imageDirectory = "https://cgi.csc.liv.ac.uk/~phil/Teaching/COMP327/artwork_images/"
    var linkPart = String()
    var concatenatedURL = String()
    var completeUrl = String()
    var numberOfArtworks = Int()
    var firstArtwork = String()
    var currentArtwork = Int()
    var currentArtworkTitle = String()
    var indexOfLocation = Int()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //get the array index of the location
        for index in 0...locationsOrderedByDistance.count-1 {
            if segueLocation == locationsOrderedByDistance[index]{
                indexOfLocation = index
            }
        }
        numberOfArtworks = artworksByLocation[indexOfLocation].count
        //if only one artwork, do not allow user to move between artwork pages
        if numberOfArtworks <= 1{
            backOutlet.isHidden = true
            forwardOutlet.isHidden = true
            //get the artwork
            firstArtwork = artworksByLocation[indexOfLocation][0]
        }
        //if more than one, allow for forward button to be seen and get the location of it
        else{
            backOutlet.isHidden = true
            forwardOutlet.isHidden = false
            //get the first artwork
            firstArtwork = artworksByLocation[indexOfLocation][0]
            currentArtwork = 0
            
        }
        //look for the location of the element in the dictionary
        for index in 0...numberOfElementsInFile-1{
            if (((artworkData!["artworks"] as? NSArray)?[index] as? NSDictionary)?["title"] as? String)! == firstArtwork{
                locationOfElement = index
            }
        }
        
        //load and display infromation about the first artwork
        titleOutlet.text = (((artworkData!["artworks"] as? NSArray)?[locationOfElement] as? NSDictionary)?["title"] as? String)!
        authorOutlet.text = (((artworkData!["artworks"] as? NSArray)?[locationOfElement] as? NSDictionary)?["artist"] as? String)!
        yearOutlet.text = (((artworkData!["artworks"] as? NSArray)?[locationOfElement] as? NSDictionary)?["yearOfWork"] as? String)!
        informationOutlet.text = (((artworkData!["artworks"] as? NSArray)?[locationOfElement] as? NSDictionary)?["Information"] as? String)!
        linkPart = (((artworkData!["artworks"] as? NSArray)?[locationOfElement] as? NSDictionary)?["fileName"] as? String)!
        concatenatedURL = imageDirectory+linkPart
        completeUrl = concatenatedURL.replacingOccurrences(of: " ", with: "%20", options: .literal, range: nil)
        loadImage(urlString: completeUrl)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
 
    //the outlets for the elements
    @IBOutlet weak var imageOutlet: UIImageView!
    
    @IBOutlet weak var titleOutlet: UILabel!
    
    @IBOutlet weak var authorOutlet: UILabel!
    
    @IBOutlet weak var informationOutlet: UITextView!
    
    @IBOutlet weak var yearOutlet: UILabel!
    
    @IBOutlet weak var backOutlet: UIButton!
    
    @IBOutlet weak var forwardOutlet: UIButton!
    
    //when the forward button is pressed
    @IBAction func forwardAction(_ sender: Any) {
        backOutlet.isHidden = false
        currentArtwork = currentArtwork+1
        if currentArtwork >= numberOfArtworks-1{
            forwardOutlet.isHidden = true
        }
        currentArtworkTitle = artworksByLocation[indexOfLocation][currentArtwork]
        loadInformation()
    }
    
    //when the back button is pressed
    @IBAction func backAction(_ sender: Any) {
        forwardOutlet.isHidden = false
        currentArtwork = currentArtwork-1
        if currentArtwork <= 0{
            backOutlet.isHidden = true
        }
        currentArtworkTitle = artworksByLocation[indexOfLocation][currentArtwork]
        loadInformation()
    }
    
    
    func loadImage(urlString:String){
        //get the url and convert it to URL
        let imageUrlString = urlString
        let imageURL:URL = URL(string: imageUrlString)!
        
        //Load image in background
        DispatchQueue.global(qos: .userInitiated).async {
            
            let imageData:NSData = NSData(contentsOf: imageURL)!
            let imageView = UIImageView()
            imageView.center = self.view.center
            
            // update the UI
            DispatchQueue.main.async {
                let image = UIImage(data: imageData as Data)
                //set the Image
                self.imageOutlet.image = image
                imageView.contentMode = UIViewContentMode.scaleAspectFit
            }
        }
        
    }
    
    func loadInformation (){
        
        //get the location in the dictionary
        for index in 0...numberOfElementsInFile-1{
            if (((artworkData!["artworks"] as? NSArray)?[index] as? NSDictionary)?["title"] as? String)! == currentArtworkTitle{
                locationOfElement = index
            }
        }
        
        //load and display infromation about the artwork
        titleOutlet.text = (((artworkData!["artworks"] as? NSArray)?[locationOfElement] as? NSDictionary)?["title"] as? String)!
        authorOutlet.text = (((artworkData!["artworks"] as? NSArray)?[locationOfElement] as? NSDictionary)?["artist"] as? String)!
        yearOutlet.text = (((artworkData!["artworks"] as? NSArray)?[locationOfElement] as? NSDictionary)?["yearOfWork"] as? String)!
        informationOutlet.text = (((artworkData!["artworks"] as? NSArray)?[locationOfElement] as? NSDictionary)?["Information"] as? String)!
        linkPart = (((artworkData!["artworks"] as? NSArray)?[locationOfElement] as? NSDictionary)?["fileName"] as? String)!
        //create the URL for the image
        concatenatedURL = imageDirectory+linkPart
        completeUrl = concatenatedURL.replacingOccurrences(of: " ", with: "%20", options: .literal, range: nil)
        loadImage(urlString: completeUrl)
    }
    
}
