//
//  ViewController.swift
//  Whatflower
//
//  Created by Roy Li on 10/9/18.
//  Copyright © 2018 Roy Li. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate,UINavigationControllerDelegate {

    let imagePicker = UIImagePickerController()
    
    @IBOutlet weak var textLabel: UILabel!
    
    let wikipediaURL = "https://en.wikipedia.org/w/api.php"
    
    
    
    @IBOutlet weak var imageView: UIImageView!
    var pickedImage : UIImage?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .camera
        
    }

    @IBAction func tappedCamera(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        // Local variable inserted by Swift 4.2 migrator.
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        if let userPickedImage = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.editedImage)] as? UIImage {
            guard let ciImage = CIImage(image: userPickedImage) else{
                fatalError("Could not convert image to CIImage!")
            }
            
//            imageView.image = userPickedImage
            
            
            detect(flower: ciImage)

        }
        
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    //MARK: - Networking
    /***************************************************************/
    
    //Write the get WikiData method here:
    func getWikiData(flowerName:String) {
        
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
            ]
        
        Alamofire.request(wikipediaURL, method: .get, parameters: parameters).responseJSON {
            response in
            if response.result.isSuccess{
                print("Success! Got the Wiki Data")
                
                let wikiJSON : JSON = JSON(response.result.value!)
                print(wikiJSON)
                self.updateWikiData(json: wikiJSON)
            }
            else{
                print("Error \(response.result.error)")
                self.textLabel.text = "Connection issues"
            }
        }
    }
    
    //MARK: - JSON Parsing and UI updates
    /***************************************************************/
    
    
    //Write the updateWeatherData method here:
    
    func updateWikiData(json:JSON) {
        let pageid = json["query"]["pageids"][0].stringValue
        let tempResult = json["query"]["pages"][pageid]["extract"].stringValue
        
        let flowerImageURL = json["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
        
        imageView.sd_setImage(with: URL(string: flowerImageURL))
        textLabel.text = tempResult
    }
    
    
    //MARK: - Using CoreML to detect the image and change the title of the navBar
    func detect(flower: CIImage){
        
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Loading CoreML Model Failed")
        }
        
        let request = VNCoreMLRequest(model: model) { (request, Error) in
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("Cannot get results from the request")
            }
            print(results.first)
            if let firstResult = results.first{
                self.navigationItem.title = firstResult.identifier.capitalized
                // Get the Wiki data from Wiki API
                self.getWikiData(flowerName: firstResult.identifier)
            }
        }
        
        let handler = VNImageRequestHandler(ciImage: flower)
        do{
            try handler.perform([request])
        }catch{
            print("Error \(error)")
        }
        
    }
}


    // Helper function inserted by Swift 4.2 migrator.
    fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
        return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
    }

    // Helper function inserted by Swift 4.2 migrator.
    fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
        return input.rawValue
    }
