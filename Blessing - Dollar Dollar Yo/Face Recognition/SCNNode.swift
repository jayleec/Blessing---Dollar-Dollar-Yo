//
//  SCNNode.swift
//  Blessing - Dollar Dollar Yo
//
//  Created by Jay on 24/12/2017.
//  Copyright © 2017 Jay. All rights reserved.
//


import Foundation
import ARKit
import Async


public extension SCNNode {
    
    convenience init(position: SCNVector3) {
        self.init()
        self.position = position
    }
    
    convenience init(withIndex index : Int, position: SCNVector3, effect: String) {
        // CENTRE POINT NODE
        let sphere = SCNSphere(radius: 0.005)
        sphere.firstMaterial?.diffuse.contents = UIColor.blue
        let sphereNode = SCNNode(geometry: sphere)
//        sphereNode.opacity = 0.6
        
        self.init()
        
        let trailEmitter = createParticles(name: effect, geometry: sphere)
        sphereNode.addParticleSystem(trailEmitter)
        addChildNode(sphereNode)
        self.position = position
        
    }
    
    func createParticles(name: String, geometry: SCNGeometry) -> SCNParticleSystem {
        let particle = SCNParticleSystem(named:  name + ".scnp", inDirectory: nil)!
        particle.emitterShape = geometry
        return particle
    }
    
    func move(_ position: SCNVector3)  {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.4
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction.init(name: kCAMediaTimingFunctionLinear)
        self.position = position
//        opacity = 1
        SCNTransaction.commit()
    }
    
    func hide()  {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 2.0
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction.init(name: kCAMediaTimingFunctionLinear)
        opacity = 0
        SCNTransaction.commit()
    }
    
    func show()  {
        opacity = 0
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.4
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction.init(name: kCAMediaTimingFunctionLinear)
        opacity = 1
        SCNTransaction.commit()
    }
}
