extension ARKController: ARSCNViewDelegate {

    public func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {

        // Tony (6/6/19): Both of the below options require an update to webxr-ios-js that sends back
        // an 'onUpdate' message that fires at the end of 'finishedRender'.
        
        // SceneKit swimming-reduction attempt 1 (in conjunction with changes in onJSFinishedRendering)
        // tries to wait to until after JS sends back 'onUpdate' to render a frame. This attempt is more
        // successful at reducing the "Thread blocked waiting for next drawable" issue, but is less successful
        // at reducing the swimming issue.
        
//                if let renderView = controller.getRenderView() as? ARSCNView,
//                    let frame = session.currentFrame
//                {
//                    renderView.isPlaying = false
//                    updateARKData(with: frame)
//                    didUpdate()
//                    if shouldUpdateWindowSize {
//                        shouldUpdateWindowSize = false
//                        didUpdateWindowSize()
//                    }
//                }
        
        // SceneKit swimming-reduction attempt 2 (in conjunction with changes in onJSFinishedRendering)
        // doesn't updateARKData until JS sends back that the last frame was processed. On an iPhone X this
        // attempt is more successful at reducing the swimming issue, but it does not completely resolve it.
        
        if initializingRender,
            let frame = session.currentFrame
        {
            updateARKData(with: frame)

            didUpdate()

            if shouldUpdateWindowSize {
                shouldUpdateWindowSize = false
                didUpdateWindowSize()
            }
        }
    }
}
