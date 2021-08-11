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
    
    //MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Selfie Share"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(importPicture))
        let connectionPrompt = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showConnectionPrompt))
        let showDevices = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(showConnectedPeers))
        navigationItem.leftBarButtonItems = [connectionPrompt, showDevices]

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
    
    @objc func showConnectedPeers() {
        
        guard let mcSession = mcSession else { return }
                
                var peersList = [String]()
                
                for peer in mcSession.connectedPeers {
                    peersList.append(peer.displayName)
                }
                
                var message = peersList.joined(separator: "\n")
                
                if peersList.count == 0 {
                    message = "No devices are connected."
                }
                
                let ac = UIAlertController(title: "Peers connected", message: message, preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                present(ac, animated: true, completion: nil)
    }
    
    //Tell the delegate the user picked an image
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        //if key in info has an UIImage, typecast it
        guard let image = info[.editedImage] as? UIImage else { return }
        dismiss(animated: true)

        images.insert(image, at: 0)
        collectionView.reloadData()
        
        // Check if we have an active session we can use.
        guard let mcSession = mcSession else { return }

        // Check if there are any peers[] to send to.
        if mcSession.connectedPeers.count > 0 {
            // Convert the new image to a Data object.
            if let imageData = image.pngData() {
                // Send it to all peers, ensuring it gets delivered.
                do {
                    try mcSession.send(imageData, toPeers: mcSession.connectedPeers, with: .reliable)
                } catch {
                    // Show an error message if there's a problem.
                    let ac = UIAlertController(title: "Send error", message: error.localizedDescription, preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    present(ac, animated: true)
                }
            }
        }
    }
    
    @objc func showConnectionPrompt() {
        
        let ac = UIAlertController(title: "Connect to others", message: nil, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Host a session", style: .default, handler: startHosting))
            ac.addAction(UIAlertAction(title: "Join a session", style: .default, handler: joinSession))
            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(ac, animated: true)
    }
    
    func startHosting(action: UIAlertAction) {
        
        //creates a session that people can join in
        guard let mcSession = mcSession else { return }
        mcAdvertisingAssistant = MCAdvertiserAssistant(serviceType: "hws-project25", discoveryInfo: nil, session: mcSession)
        //starts advertising the service
        mcAdvertisingAssistant?.start()
    }
    
    func joinSession(action: UIAlertAction) {
        
        guard let mcSession = mcSession else { return }
        //used when looking for sessions, showing users who is nearby and letting them join
        let mcBrowser = MCBrowserViewController(serviceType: "hws-project25", session: mcSession)
        mcBrowser.delegate = self
        present(mcBrowser, animated: true)
    }
    
    //MARK: - Delegates
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        
        //dealing with MCSessionState enum
        switch state {
        //the user is connected
        case .connected:
            print("Connected: \(peerID.displayName)")
        //the user is connecting
        case .connecting:
            print("Connecting: \(peerID.displayName)")
        //the user is no connected
        case .notConnected:
            print("Not Connected: \(peerID.displayName)")
//Challenge 1
            let ac = UIAlertController(title: "\(peerID.displayName) has disconnected", message: nil, preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                        present(ac, animated: true, completion: nil)

        @unknown default:
            print("Unknown state received: \(peerID.displayName)")
        }
    }
    
    //Indicates that an NSData object has been received from a nearby peer.
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
        DispatchQueue.main.async { [weak self] in
            //put the image recieved at images array
            if let image = UIImage(data: data) {
                self?.images.insert(image, at: 0)
                self?.collectionView.reloadData()
            }
        }
    }
}

