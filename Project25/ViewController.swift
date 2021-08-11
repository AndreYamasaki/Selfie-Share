//
//  ViewController.swift
//  Project25
//
//  Created by user on 11/08/21.
//

import UIKit
import MultipeerConnectivity

class ViewController: UICollectionViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, MCSessionDelegate, MCBrowserViewControllerDelegate {
    
    //MARK: - Attributes

    var images = [UIImage]()
    
    //identifies each user uniquely in a session.
    var peerID = MCPeerID(displayName: UIDevice.current.name)
    //is the manager class that handles all multipeer connectivity for us
    var mcSession: MCSession?
    //is used when creating a session, telling others that we exist and handling invitations
    var mcAdvertisingAssistant: MCAdvertiserAssistant?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Selfie Share"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(importPicture))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showConnectionPrompt))

        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession?.delegate = self
    }
    
    //MARK: - Methods
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        //the imageview inside the cell is the identifier
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageView", for: indexPath)

        //searches for any views inside itself (or indeed itself) with that tag number. typecast UIView into UIImageview
        if let imageView = cell.viewWithTag(1000) as? UIImageView {
            imageView.image = images[indexPath.item]
        }

        return cell
    }
    
    @objc func importPicture() {
        
        let picker = UIImagePickerController()
            picker.allowsEditing = true
            picker.delegate = self
            present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        //if key in info has an UIImage, typecast it
        guard let image = info[.editedImage] as? UIImage else { return }

            dismiss(animated: true)

            images.insert(image, at: 0)
            collectionView.reloadData()
    }
    
    @objc func showConnectionPrompt() {
        
        let ac = UIAlertController(title: "Connect to others", message: nil, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Host a session", style: .default, handler: startHosting))
            ac.addAction(UIAlertAction(title: "Join a session", style: .default, handler: joinSession))
            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(ac, animated: true)
    }
    
    func startHosting(action: UIAlertAction) {
        
        guard let mcSession = mcSession else { return }
        mcAdvertisingAssistant = MCAdvertiserAssistant(serviceType: "hws-project25", discoveryInfo: nil, session: mcSession)
    }
    
    func joinSession(action: UIAlertAction) {
        
        guard let mcSession = mcSession else { return }
        //used when looking for sessions, showing users who is nearby and letting them join
        let mcBrowser = MCBrowserViewController(serviceType: "hws-project25", session: mcSession)
        mcBrowser.delegate = self
        present(mcBrowser, animated: true)
    }
}

