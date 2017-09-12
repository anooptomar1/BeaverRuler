//
//  EditObjectViewController.swift
//  BeaverRuler
//
//  Created by Sasha on 8/26/17.
//  Copyright © 2017 Sasha. All rights reserved.
//

import UIKit
import Photos

protocol EditObjectVCDelegate {
    func reloadObjects()
}

class EditObjectViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var objectNameTextField: UITextField!
    @IBOutlet weak var objectSizeTextField: UITextField!
    @IBOutlet weak var objectImage: UIImageView!
    @IBOutlet weak var measureUnitLabel: UILabel!
    
    var selectedObjectIndex = 0
    var delegate: EditObjectVCDelegate?
    fileprivate var unit: DistanceUnit = .centimeter
    fileprivate let imagePicker = UIImagePickerController()
    fileprivate var imageName = ""
    fileprivate var selectedObject: UserObjectRm?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        objectNameTextField.delegate = self
        objectSizeTextField.delegate = self
        
        self.imagePicker.allowsEditing = false
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        
        let defaults = UserDefaults.standard
        
        if let measureString = defaults.string(forKey: Setting.measureUnits.rawValue) {
            unit = DistanceUnit(rawValue: measureString)!
            measureUnitLabel.text = unit.unit
        }
        
        let userObjects = GRDatabaseManager.sharedDatabaseManager.grRealm.objects(UserObjectRm.self).sorted(byKeyPath: "createdAt", ascending: false)
        self.selectedObject = userObjects[selectedObjectIndex]
        
        objectNameTextField.text = selectedObject?.name
        
        let objectUnit = DistanceUnit(rawValue: (selectedObject?.sizeUnit!)!)
        let conversionFator = unit.fator / (objectUnit?.fator)!
        objectSizeTextField.text = String(format: "%.2f%", (selectedObject?.size)! * conversionFator)
        
        measureUnitLabel.text = unit.unit
        
        if let imageName = selectedObject?.image {
            let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
            let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
            let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
            if let dirPath = paths.first {
                let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(imageName)
                objectImage.image = UIImage(contentsOfFile: imageURL.path)
                self.imageName = imageName
            }
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func deleteButtonPressed(_ sender: Any) {
        try! GRDatabaseManager.sharedDatabaseManager.grRealm.write {
            GRDatabaseManager.sharedDatabaseManager.grRealm.delete(selectedObject!)
            
            if (self.delegate != nil) {
                self.delegate?.reloadObjects()
            }
            
            dismiss(animated: true, completion: nil)
        }
    }

    @IBAction func backPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func savePressed(_ sender: Any) {
        
        let userObjects = GRDatabaseManager.sharedDatabaseManager.grRealm.objects(UserObjectRm.self).sorted(byKeyPath: "createdAt", ascending: false)
        let selectedObject = userObjects[selectedObjectIndex]
        
        if objectSizeTextField.text?.characters.count == 0 || (objectNameTextField.text?.characters.count)! == 0 {
            return
        }
        
        if Float(objectSizeTextField.text!) != nil {
            
        } else {
            
            let alertController = UIAlertController(title: "INPUT ERROR", message:
                "Input right size", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
            
            return
        }
        
        DispatchQueue.main.async {
            try! GRDatabaseManager.sharedDatabaseManager.grRealm.write({
                selectedObject.name = self.objectNameTextField.text
                selectedObject.size = Float(self.objectSizeTextField.text!)!
                selectedObject.sizeUnit = self.unit.rawValue
                selectedObject.image = self.imageName
                
                if let data = UIImagePNGRepresentation(self.objectImage.image!) {
                    let filename = self.getDocumentsDirectory().appendingPathComponent(self.imageName)
                    try? data.write(to: filename)
                }
                
                if (self.delegate != nil) {
                    self.delegate?.reloadObjects()
                }
            })
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    @IBAction func editImagePressed(_ sender: Any) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func sharePressed(_ sender: Any) {
        let size = objectSizeTextField.text! + " " + unit.unit
        let firstActivityItem = objectNameTextField.text! + " " + size + " #GRuler"
        let secondActivityItem : NSURL = NSURL(string: "https://itunes.apple.com/us/app/gruler/id1274233742?ls=1&mt=8")!
        let image : UIImage = objectImage.image!
        
        let activityViewController : UIActivityViewController = UIActivityViewController(
            activityItems: [firstActivityItem, secondActivityItem, image], applicationActivities: nil)
        
        activityViewController.popoverPresentationController?.sourceView = (sender as! UIButton)
        activityViewController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.unknown
        activityViewController.popoverPresentationController?.sourceRect = CGRect(x: 150, y: 150, width: 0, height: 0)
        
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
//    func textFieldDidBeginEditing(_ textField: UITextField) {
//    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        view.endEditing(true)
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            objectImage.image = pickedImage
        }
        
        if let imageURL = info[UIImagePickerControllerPHAsset] as? NSURL {
            let result = PHAsset.fetchAssets(withALAssetURLs: [imageURL as URL], options: nil)
            let fileName = result.firstObject?.value(forKey: "filename") as? String ?? "Unknown"
            self.imageName = fileName
        }
        
        dismiss(animated: true, completion: nil)
    }
    
}
