//
//  ViewController.swift
//  CatDogIdentifierDemo
//
//  Created by André Felipe Chinen on 21/02/24.
//

import UIKit
import CoreML
import Vision

class ViewController: UIViewController {
    
    private var model: VNCoreMLModel? = nil
    private var Model: VNCoreMLModel {
        get {
            guard let unwrappedModel = model else {
                fatalError("model is nil!")
            }
            return unwrappedModel
        }
    }
    
    private let imagePicker = UIImagePickerController()
    
    private let cameraBarButton = UIBarButtonItem(barButtonSystemItem: .camera, target: nil, action: nil)
    
    private let imagePreview: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = .systemBackground
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let labelPreview: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = .label
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
        label.text = "Press the camera button to take a picture!"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let labelResult: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 18)
        label.textAlignment = .center
        label.text = ""
        label.lineBreakMode = .byCharWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let padding = CGFloat(10)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load machine learning model
        
        let configuration = MLModelConfiguration()
        guard let importedModel = try? VNCoreMLModel(for: CatDogModel(configuration: configuration).model) else {
            fatalError("Cannot import model!")
        }
        
        model = importedModel
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .camera
        
        view.backgroundColor = .systemBackground
        
        configureNavigationItem()
        configureBarButtons()
        
        view.addSubview(imagePreview)
        view.addSubview(labelPreview)
        view.addSubview(labelResult)
    }
    
    override func viewDidLayoutSubviews() {
        
        let insets = self.view.safeAreaInsets
        
        imagePreview.leftAnchor.constraint(equalTo: view.leftAnchor, constant: insets.left).isActive = true
        imagePreview.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -insets.right).isActive = true
        imagePreview.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        imagePreview.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        labelPreview.topAnchor.constraint(equalTo: imagePreview.topAnchor).isActive = true
        labelPreview.bottomAnchor.constraint(equalTo: imagePreview.bottomAnchor).isActive = true
        labelPreview.leftAnchor.constraint(equalTo: imagePreview.leftAnchor).isActive = true
        labelPreview.rightAnchor.constraint(equalTo: imagePreview.rightAnchor).isActive = true
        
        labelResult.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        labelResult.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: view.frame.height * 0.3).isActive = true
        
    }
    
    private func configureNavigationItem() {
        navigationItem.title = "Cat or Dog"
        navigationItem.setRightBarButtonItems([cameraBarButton], animated: true)
    }
    
    private func configureBarButtons() {
        cameraBarButton.target = self
        cameraBarButton.action = #selector(cameraButtonPressed)
    }
    
    // On camera button pressed
    @objc private func cameraButtonPressed() {
        present(imagePicker, animated: true)
    }
    
    private func setResultLabel(animal: String, accuracy: Float, resultString: String) {
        print("Result string:\n\(resultString)")
        
        var percent = accuracy * 100
        
        if animal == "Dog" {
            labelResult.text = "Cachorro\n\(round(10 * percent) / 10)%"
        }else {
            labelResult.text = "Gato\n\(round(10 * percent) / 10)%"
        }
        
    }
    
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // Load captured photo
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        let pickedImage = info[.editedImage]
        
        guard let pickedImage = pickedImage as? UIImage else {
            fatalError("Failed to set picked image to preview!")
        }
        
        imagePreview.image = pickedImage
        labelPreview.isHidden = true
        
        // Convert into CIImage before passing the captured photo into machine learning model
        guard let convertedCIImage = CIImage(image: pickedImage) else {
            fatalError("Failed to convert UIImage into CIImage")
        }
        
        // Pass captured photo into machine learning model
        detectImage(image: convertedCIImage)
        
        imagePicker.dismiss(animated: true)
    }
    
    // Detect Cat or Dog with machine learning model
    private func detectImage(image: CIImage) {
        
        let request = VNCoreMLRequest(model: Model) { [weak self] (request, error) in
            
            guard let classificationResults = request.results as? [VNClassificationObservation] else { return }
            
            // Sort prediction results by its confidence
            let sortedResults = classificationResults.sorted { $0.confidence > $1.confidence}
            
            var resultString = ""
            
            var animal: String = ""
            var accuracy: Float = 0
            
            // Sort the prediction results with highest confidence
            for i in 0...sortedResults.count-1 {
                resultString += "\(sortedResults[i].identifier.capitalized), confidence: \(sortedResults[i].confidence)\n"
                
                if i == 0 {
                    animal = sortedResults[i].identifier.capitalized
                    accuracy = sortedResults[i].confidence
                } else {
                    if sortedResults[i].confidence > accuracy {
                        animal = sortedResults[i].identifier.capitalized
                        accuracy = sortedResults[i].confidence
                    }
                }
            }
            
            self?.setResultLabel(animal: animal, accuracy: accuracy, resultString: resultString)
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        // Perform prediction
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
}
