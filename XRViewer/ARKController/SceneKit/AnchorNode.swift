import ARKit
import SceneKit
import XCGLogger

enum AnchorFigure : Int {
    case anchorBox
    case anchorSphere
    case anchorPyramid
    case anchorCylinder
    case anchorCone
    case anchorTube
    case anchorCapsule
    case anchorTorus
    case anchorFugureCount
}

class AnchorNode: SCNNode {
    
    private var figure: AnchorFigure?
    let boxSize = Constant.boxSize()
    
    init(anchor: ARAnchor) {
        super.init()

        appDelegate().logger.debug("+ anchor")
        
        figure = .anchorBox //arc4random() % AnchorPyramid;

        switch figure {
            case .anchorBox?:
                setupBox()
            case .anchorPyramid?:
                setupPyramid()
            case .anchorSphere?:
                setupSphere()
            case .anchorCylinder?:
                setupCylinder()
            case .anchorCone?:
                setupCone()
            case .anchorTube?:
                setupTube()
            case .anchorCapsule?:
                setupCapsule()
            case .anchorTorus?:
                setupTorus()
            default:
                break
        }

        opacity = 0
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        appDelegate().logger.debug("- anchor")
    }

    func size() -> CGFloat {
        switch figure {
            case .anchorBox?:
                return (geometry as? SCNBox)?.width ?? 0.0
            case .anchorPyramid?:
                return (geometry as? SCNPyramid)?.width ?? 0.0
            case .anchorSphere?:
                return (geometry as? SCNSphere)?.radius ?? 0.0
            case .anchorCylinder?:
                return (geometry as? SCNCylinder)?.height ?? 0.0
            case .anchorCone?:
                return (geometry as? SCNCone)?.height ?? 0.0
            case .anchorTube?:
                return (geometry as? SCNTube)?.height ?? 0.0
            case .anchorCapsule?:
                return (geometry as? SCNCapsule)?.height ?? 0.0
            case .anchorTorus?:
                return (geometry as? SCNTorus)?.pipeRadius ?? 0.0
            default:
                break
        }
        return 0
    }

    func setupTorus() {
        let geometry: SCNGeometry? = SCNTorus(ringRadius: boxSize, pipeRadius: boxSize / 3)

        var materialColor: UIColor?
        let col = Int(arc4random()) % 7
        switch col {
            case 0:
                materialColor = UIColor.green
            case 1:
                materialColor = UIColor.red
            case 2:
                materialColor = UIColor.blue
            case 3:
                materialColor = UIColor.green
            case 4:
                materialColor = UIColor.yellow
            case 5:
                materialColor = UIColor.purple
            case 6:
                materialColor = UIColor.magenta
            default:
                break
        }

        guard let anchorMaterial = anchorMaterial(with: materialColor) else { return }
        geometry?.materials = [anchorMaterial]

        self.geometry = geometry
    }

    func setupCapsule() {
        let geometry: SCNGeometry? = SCNCapsule(capRadius: boxSize, height: boxSize)

        var materialColor: UIColor?

        let col = Int(arc4random()) % 7
        switch col {
            case 0:
                materialColor = UIColor.green
            case 1:
                materialColor = UIColor.red
            case 2:
                materialColor = UIColor.blue
            case 3:
                materialColor = UIColor.green
            case 4:
                materialColor = UIColor.yellow
            case 5:
                materialColor = UIColor.purple
            case 6:
                materialColor = UIColor.magenta
            default:
                break
        }

        guard let anchorMaterial = anchorMaterial(with: materialColor) else { return }
        geometry?.materials = [anchorMaterial]

        self.geometry = geometry
    }

    func setupTube() {
        let geometry: SCNGeometry? = SCNTube(innerRadius: boxSize - boxSize / 5, outerRadius: boxSize, height: boxSize)

        guard let anchorMaterialYellow = anchorMaterial(with: .yellow) else { return }
        guard let anchorMaterialPurple = anchorMaterial(with: .purple) else { return }
        guard let anchorMaterialMagenta = anchorMaterial(with: .magenta) else { return }
        geometry?.materials = [anchorMaterialYellow, anchorMaterialPurple, anchorMaterialMagenta]

        self.geometry = geometry
    }

    func setupCone() {
        let geometry: SCNGeometry? = SCNCone(topRadius: boxSize / 2, bottomRadius: boxSize, height: boxSize)
        
        guard let anchorMaterialRed = anchorMaterial(with: .red) else { return }
        guard let anchorMaterialGreen = anchorMaterial(with: .green) else { return }
        guard let anchorMaterialBlue = anchorMaterial(with: .blue) else { return }
        geometry?.materials = [anchorMaterialRed, anchorMaterialGreen, anchorMaterialBlue]

        self.geometry = geometry
    }

    func setupCylinder() {
        let geometry: SCNGeometry? = SCNCylinder(radius: boxSize, height: boxSize)

        guard let anchorMaterialOrange = anchorMaterial(with: .orange) else { return }
        guard let anchorMaterialGray = anchorMaterial(with: .gray) else { return }
        guard let anchorMaterialBlue = anchorMaterial(with: .blue) else { return }
        geometry?.materials = [anchorMaterialOrange, anchorMaterialGray, anchorMaterialBlue]

        self.geometry = geometry
    }

    func setupSphere() {
        let geometry: SCNGeometry? = SCNSphere(radius: boxSize)

        var materialColor: UIColor?

        let col = Int(arc4random()) % 7
        switch col {
            case 0:
                materialColor = UIColor.green
            case 1:
                materialColor = UIColor.red
            case 2:
                materialColor = UIColor.blue
            case 3:
                materialColor = UIColor.green
            case 4:
                materialColor = UIColor.yellow
            case 5:
                materialColor = UIColor.purple
            case 6:
                materialColor = UIColor.magenta
            default:
                break
        }

        guard let anchorMaterial = anchorMaterial(with: materialColor) else { return }
        geometry?.materials = [anchorMaterial]

        self.geometry = geometry
    }

    func setupPyramid() {
        let geometry: SCNGeometry? = SCNPyramid(width: boxSize, height: boxSize, length: boxSize)

        guard let anchorMaterialRed = anchorMaterial(with: .red) else { return }
        guard let anchorMaterialGreen = anchorMaterial(with: .green) else { return }
        guard let anchorMaterialBlue = anchorMaterial(with: .blue) else { return }
        guard let anchorMaterialYellow = anchorMaterial(with: .yellow) else { return }
        guard let anchorMaterialPurple = anchorMaterial(with: .purple) else { return }
        geometry?.materials = [anchorMaterialRed, anchorMaterialGreen, anchorMaterialBlue, anchorMaterialYellow, anchorMaterialPurple]

        self.geometry = geometry
    }

    func setupBox() {
        let geometry: SCNGeometry? = SCNBox(width: boxSize, height: boxSize, length: boxSize, chamferRadius: boxSize / 20)

        guard let anchorMaterialRed = anchorMaterial(with: .red) else { return }
        guard let anchorMaterialGreen = anchorMaterial(with: .green) else { return }
        guard let anchorMaterialBlue = anchorMaterial(with: .blue) else { return }
        guard let anchorMaterialYellow = anchorMaterial(with: .yellow) else { return }
        guard let anchorMaterialPurple = anchorMaterial(with: .purple) else { return }
        guard let anchorMaterialMagenta = anchorMaterial(with: .magenta) else { return }
        geometry?.materials = [anchorMaterialRed, anchorMaterialGreen, anchorMaterialBlue, anchorMaterialYellow, anchorMaterialPurple, anchorMaterialMagenta]

        self.geometry = geometry
    }

    func anchorMaterial(with color: UIColor?) -> SCNMaterial? {
        let material = SCNMaterial()
        material.fillMode = .fill
        material.diffuse.contents = color
        material.specular.contents = UIColor.white
        material.locksAmbientWithDiffuse = true

        return material
    }
}
