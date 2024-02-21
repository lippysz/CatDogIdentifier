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
    
    //Declara o modelo com a configuração do modelo importado(CatDogModel)
    private let Model: VNCoreMLModel = {
        let configuration = MLModelConfiguration()
        guard let importedModel = try? VNCoreMLModel(for: CatDogModel(configuration: configuration).model) else {
            fatalError("Cannot import model!")
        }
        return importedModel
    }()
    
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
    
    //Função de quando apertar no ícone da câmera
    @objc private func cameraButtonPressed() {
        present(imagePicker, animated: true)
    }
    
    //Função que recebe os resultados e muda para mostrar melhor ao usuário
    //Mudei um pouco essa função só pq eu queria que mostrasse só o resultado do animal detectado
    private func setResultLabel(animal: String, accuracy: Float, resultString: String) {
        print("Result string:\n\(resultString)") //Printa o resultado dos animais no console
        
        var percent = accuracy * 100 //Transforma o accuracy em porcentagem
        
        if animal == "Dog" {
            labelResult.text = "Cachorro\n\(round(10 * percent) / 10)%" //Usei o round para arrendondar uma casa decimal dps da virgula
        }else {
            labelResult.text = "Gato\n\(round(10 * percent) / 10)%" //Usei o round para arrendondar uma casa decimal dps da virgula
        }
        
    }
    
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //Método que é chamado após o usuário selecionar uma imagem (nosso caso, quando apertar em 'Use Photo')
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        let pickedImage = info[.editedImage]
        
        guard let pickedImage = pickedImage as? UIImage else {
            fatalError("Failed to set picked image to preview!")
        }
        
        imagePreview.image = pickedImage //Coloca uma imagem no UIImageView do Menu
        labelPreview.isHidden = true //Esconde a label do Menu
        
        //Converte a imagem em CIImage, que é o tipo necessário para usar com a API de visão computacional (Vision).
        guard let convertedCIImage = CIImage(image: pickedImage) else {
            fatalError("Failed to convert UIImage into CIImage")
        }
        
        //Manda a imagem para o modelo da Machine Learning
        detectImage(image: convertedCIImage)
        
        imagePicker.dismiss(animated: true) //Fecha modal
    }
    
    //Função que detecta cachorro ou gato no modelo da Machine Learning
    private func detectImage(image: CIImage) {
        
        //É necessário fazer esse Request utilizando o modelo declarado lá no começo do código
        let request = VNCoreMLRequest(model: Model) { [weak self] (request, error) in
            
            //Resultados da solicitação são extraídos e convertidos em uma matriz de VNClassificationObservation
            guard let classificationResults = request.results as? [VNClassificationObservation] else { return }
            
            //Ordena os resultados do maior para menor
            let sortedResults = classificationResults.sorted { $0.confidence > $1.confidence}
            
            var resultString = "" //String só para aparecer no console os dois resultados (do cachorro e do gato, e suas accuracy)
            
            var animal: String = sortedResults[0].identifier.capitalized //Nome do animal com a maior accuracy
            var accuracy: Float = sortedResults[0].confidence //Valor do accuracy em uma escala de 0 a 1
            
            //Apenas salvando os dois resultados na variável 'resultString'
            for i in 0...sortedResults.count-1 {
                resultString += "\(sortedResults[i].identifier.capitalized), confidence: \(sortedResults[i].confidence)\n"
            }
            
            //Chama a função lá da View Controller para organizar o resultado ao usuário
            self?.setResultLabel(animal: animal, accuracy: accuracy, resultString: resultString)
        }
        
        //O VNImageRequestHandler é uma classe que fornece funcionalidades para executar solicitações de visão computacional em imagens
        //Estamos passando a imgem selecionada pelo usuário que recebemos como parâmetro
        let handler = VNImageRequestHandler(ciImage: image)
        
        //Processamos a imagem com o Request que criamos acima
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
}
