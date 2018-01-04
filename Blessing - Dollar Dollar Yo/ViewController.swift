//
//  ViewController.swift
//  Blessing - Dollar Dollar Yo
//
//  Created by Jay on 24/12/2017.
//  Copyright © 2017 Jay. All rights reserved.
//

import UIKit
import ARKit
import SceneKit
import SceneKitVideoRecorder
import RxSwift
import RxCocoa
import Async
import Vision

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet weak var sceneView: ARSCNView!
    
    var scnScene: SCNScene!
    
    var recorder: SceneKitVideoRecorder?
    
    private var selfy: Bool = false
    
    // MARK: Render TEST
//    var spawnTime: TimeInterval = 0
    
    // MARK: Face Detection;
    var faceList: [Face] = []
    var faceIndex: Int = 0
    var 👜 = DisposeBag()
    var bounds: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0)
    
    var faces: Int = 0
    var num: Int = 0
    var cnt: Int = 0
    var current: Int = 0
    
    // MARK: Particle
    var currentEffect: String = "art.scnassets/fire_coin_test"
    
    // MARK: sound
    var soundName = "art.scnassets/audio/coin.mp3"
    var coinSound: SCNAudioSource!
    var audioNode = SCNNode()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        //TODO: turn off statistics
        sceneView.showsStatistics = true
        
        setupScene()
        
        recorder = try! SceneKitVideoRecorder(withARSCNView: sceneView)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        sceneView.session.run(configuration)
        
        Observable<Int>.interval(0.6, scheduler: SerialDispatchQueueScheduler(qos: .default))
            .subscribeOn(SerialDispatchQueueScheduler(qos: .background))
            .concatMap{ _ in  self.faceObservation() }
            .flatMap{ Observable.from($0) }
            .subscribe { [unowned self] event in
                guard let element = event.element else {
                    print("No element available")
                    return
                }
                self.updateNode(face: element.observation, image: element.image, frame: element.frame)
            }.disposed(by: 👜)
        
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        👜 = DisposeBag()
        
        sceneView.session.pause()
    }
    
    // MARK: setup
    func setupScene() {
        scnScene = SCNScene()
        sceneView.scene = scnScene
        
        // MARK: Set up Face Detection
        bounds = sceneView.bounds
        
        // prepare sound
        coinSound = SCNAudioSource(named: soundName)!
        coinSound.volume = 0.2
        coinSound.isPositional = false
        coinSound.load()
        
        scnScene.rootNode.addAudioPlayer(SCNAudioPlayer(source: self.coinSound))
    }
    
    // MARK: Change Camera
    @IBAction func changeCamera(_ sender: Any) {
        
        sceneView.session.pause()
        
        let worldConfig = ARWorldTrackingConfiguration()
        let faceConfig = ARFaceTrackingConfiguration()
        
        if selfy {
            sceneView.session.run(worldConfig)
            selfy = false
        } else {
            sceneView.session.run(faceConfig)
            selfy = true
        }
        
    }
    
    // MARK: Start Recording;
    @IBAction func startRecording(_ sender: UIButton) {
        sender.backgroundColor = .red
        
        self.recorder?.startWriting().onSuccess {}
    }
    
    // MARK: Stop Recording;
    @IBAction func stopRecording(_ sender: UIButton) {
        sender.backgroundColor = .white
        
        self.recorder?.finishWriting().onSuccess { [weak self] url in
            
            Utils.checkAuthorizationAndPresentActivityController(toShare: url, using: self!)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: main
    func main() {
        
        let array = faceObservation()
        array.subscribeOn(SerialDispatchQueueScheduler(qos: .background))
            .flatMap{ Observable.from($0) }
            .subscribe { [unowned self] event in
                guard let element = event.element else {
                    print("No element available")
                    return
                }
                self.updateNode(face: element.observation, image: element.image, frame: element.frame)
            }.disposed(by: 👜)
        
    }
    
    // MARK: - ARSCNViewDelegate
    // MARK: RENDERER
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
       /*
        if time > spawnTime {
            main()
            
            spawnTime = time + TimeInterval(0.3)
        }
        */
    }
    
    //ARFaceTrackihngConfig Only;
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        print("faceAnchor \(faceAnchor)")
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
        
        return node
    }
 
    // MARK: SESSION
    func session(_ session: ARSession, didFailWithError error: Error) {
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        
    }
    
    // MARK: - Face detections
    private func faceObservation() -> Observable<[(observation: VNFaceObservation, image: CIImage, frame: ARFrame)]> {
        current = cnt
   
        if current == 0 {
            self.cleanup()
        }
 
        cnt = 0
        num = 0

        return Observable<[(observation: VNFaceObservation, image: CIImage, frame: ARFrame)]>.create{ observer in
            guard let frame = self.sceneView.session.currentFrame else {
                print("No frame available")
                observer.onCompleted()
                return Disposables.create()
            }
            
            // Create and rotate image
            let image = CIImage.init(cvPixelBuffer: frame.capturedImage).rotate
            
            let facesRequest = VNDetectFaceRectanglesRequest { request, error in
                guard error == nil else {
                    print("Face request error: \(error!.localizedDescription)")
                    observer.onCompleted()
                    return
                }
                
                guard let observations = request.results as? [VNFaceObservation] else {
                    print("No face observations")
                    observer.onCompleted()
                    return
                }
                
                // Map response
                let response = observations.map({ (face) -> (observation: VNFaceObservation, image: CIImage, frame: ARFrame) in
                    return (observation: face, image: image, frame: frame)
                })
                observer.onNext(response)
                observer.onCompleted()
                
            }
            try? VNImageRequestHandler(ciImage: image).perform([facesRequest])
            
            return Disposables.create()
        }
    }
    
    //TODO: cleanup outside of view
    
    // MARK: Update Node - sound / point / money sprey
    private func updateNode(face: VNFaceObservation, image: CIImage, frame: ARFrame) {
        
        cnt += 1
        
        // Determine position of the face
        let boundingBox = self.transformBoundingBox(face.boundingBox)

        guard let worldCoord = self.normalizeWorldCoord(boundingBox) else {
            print("No feature point found")
            return
        }
        
        let geometryNode = drawPoint(position: worldCoord)
        
        let sceneRoot = self.scnScene.rootNode
        
        if current == faces {
            
            if num < faceList.count && sceneRoot.childNodes.count > 0 {
                faceList[num].node.move(worldCoord)
                num += 1
            }

        }
        else if current > faces {
            
            scnScene.rootNode.addAudioPlayer(SCNAudioPlayer(source: self.coinSound))
            
            Async.main{
                sceneRoot.addChildNode(geometryNode)
                let index = sceneRoot.childNodes.count - 1
                let face = Face.init(index: index , node: geometryNode)
                self.faceList.append(face)
            }
            
            faces += 1
        }
        else {

            if faceList.count > 0 && faces > 0 {
                let index = faceList[0].index
                faceList.remove(at: 0)
                sceneRoot.childNodes[index].removeFromParentNode()
                faces -= 1
            }
        }
        
    }

    // MARK: drawPoint
    func drawPoint(position: SCNVector3) -> SCNNode {
        
        let node = SCNNode(withIndex: faceIndex, position: position, effect: currentEffect)
        faceIndex += 1
        
        return node
    }
    
    func cleanup() {
        
        for node in scnScene.rootNode.childNodes {
            for subNode in node.childNodes {
                subNode.removeFromParentNode()
            }
        }
        faceList = []
        faces = 0
        
        scnScene.rootNode.removeAllAudioPlayers()
        
    }
    
    /// In order to get stable vectors, we determine multiple coordinates within an interval.
    ///
    /// - Parameters:
    ///   - boundingBox: Rect of the face on the screen
    /// - Returns: the normalized vector
    private func normalizeWorldCoord(_ boundingBox: CGRect) -> SCNVector3? {
        
        var array: [SCNVector3] = []
        Array(0...2).forEach{_ in
            if let position = determineWorldCoord(boundingBox) {
                array.append(position)
            }
            usleep(12000) // .012 seconds
        }
        
        if array.isEmpty {
            return nil
        }
        
        return SCNVector3.center(array)
    }
    
    /// Determine the vector from the position on the screen.
    ///
    /// - Parameter boundingBox: Rect of the face on the screen
    /// - Returns: the vector in the sceneView
    private func determineWorldCoord(_ boundingBox: CGRect) -> SCNVector3? {
        // get top of the bounding box
        let arHitTestResults = sceneView.hitTest(CGPoint(x: boundingBox.midX, y: boundingBox.minY - boundingBox.height * 0.22), types: [.featurePoint])
        
        // Filter results that are to close
        if let closestResult = arHitTestResults.filter({ $0.distance > 0.10 }).first {
            //            print("vector distance: \(closestResult.distance)")
            return SCNVector3.positionFromTransform(closestResult.worldTransform)
        }
        return nil
    }
    
    /// Transform bounding box according to device orientation
    ///
    /// - Parameter boundingBox: of the face
    /// - Returns: transformed bounding box
    private func transformBoundingBox(_ boundingBox: CGRect) -> CGRect {
        var size: CGSize
        var origin: CGPoint
        switch UIDevice.current.orientation {
        case .landscapeLeft, .landscapeRight:
            size = CGSize(width: boundingBox.width * bounds.height,
                          height: boundingBox.height * bounds.width)
        default:
            size = CGSize(width: boundingBox.width * bounds.width,
                          height: boundingBox.height * bounds.height)
        }
        
        switch UIDevice.current.orientation {
        case .landscapeLeft:
            origin = CGPoint(x: boundingBox.minY * bounds.width,
                             y: boundingBox.minX * bounds.height)
        case .landscapeRight:
            origin = CGPoint(x: (1 - boundingBox.maxY) * bounds.width,
                             y: (1 - boundingBox.maxX) * bounds.height)
        case .portraitUpsideDown:
            origin = CGPoint(x: (1 - boundingBox.maxX) * bounds.width,
                             y: boundingBox.minY * bounds.height)
        default:
            origin = CGPoint(x: boundingBox.minX * bounds.width,
                             y: (1 - boundingBox.maxY) * bounds.height)
        }
        
        return CGRect(origin: origin, size: size)
    }
}







